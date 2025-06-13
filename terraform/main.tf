#########################################
# main.tf (root module)
#########################################

terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_s3_bucket" "lambda_code_bucket" {
  bucket = var.s3_bucket_name
}

# MODIFICADO: Módulo SQS é criado SOMENTE se 'create_sqs_queue' for true E 'use_existing_sqs_trigger' for false
module "sqs" {
  source     = "./modules/sqs"
  count      = var.create_sqs_queue && !var.use_existing_sqs_trigger ? 1 : 0 # O módulo será criado se var.create_sqs_queue for true e não estivermos usando uma fila existente
  queue_name = local.queue_name
}

module "lambda" {
  source              = "./modules/lambda"
  lambda_name         = local.lambda_name
  s3_bucket           = data.aws_s3_bucket.lambda_code_bucket.bucket
  s3_key              = local.s3_object_key
  handler             = local.lambda_handler
  runtime             = local.lambda_runtime
  role_arn            = module.iam.role_arn
  environment_variables = local.merged_env_vars
  # NOVO: Passa o ARN da SQS existente e a flag para o módulo Lambda (para a trigger)
  use_existing_sqs_trigger = var.use_existing_sqs_trigger
  existing_sqs_queue_arn   = var.existing_sqs_queue_arn
}

module "iam" {
  source = "./modules/iam"

  lambda_role_name    = local.lambda_role_name
  logging_policy_name = local.logging_policy_name
  publish_policy_name = local.publish_policy_name
  # Passa o ARN da SQS. Se SQS não for criada, passa a string placeholder.
  sqs_queue_arn       = var.create_sqs_queue && !var.use_existing_sqs_trigger ? module.sqs[0].queue_arn : "SQS_NOT_CREATED_PLACEHOLDER"
  create_sqs_queue    = var.create_sqs_queue && !var.use_existing_sqs_trigger # Passa a flag ajustada para o IAM
  
  # NOVO: Passa as variáveis para o módulo IAM para gerenciar permissões de consumo
  use_existing_sqs_trigger = var.use_existing_sqs_trigger
  existing_sqs_queue_arn   = var.existing_sqs_queue_arn
  consume_policy_name      = local.consume_policy_name # Novo nome de política
}

module "cloudwatch" {
  source         = "./modules/cloudwatch"
  log_group_name = local.log_group_name
}

# NOVO: Recurso para configurar a trigger da Lambda para uma fila SQS existente
# Este recurso será criado SOMENTE se 'use_existing_sqs_trigger' for true.
resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping" {
  count = var.use_existing_sqs_trigger ? 1 : 0 # Criar trigger se a flag for true

  event_source_arn = var.existing_sqs_queue_arn
  function_name    = module.lambda.lambda_function_name
  batch_size       = 10 # Tamanho do batch, ajuste conforme necessidade
  enabled          = true # Habilitar a trigger
}
