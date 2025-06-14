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

# NOVO: Data source para obter o ARN da fila SQS existente a partir do NOME
# Este bloco será avaliado SOMENTE se 'use_existing_sqs_trigger' for true e 'existing_sqs_queue_name' for fornecido.
# O ARN resolvido será então passado para outros recursos.
data "aws_sqs_queue" "existing_trigger_queue" {
  count = var.use_existing_sqs_trigger && var.existing_sqs_queue_name != "" ? 1 : 0
  name  = var.existing_sqs_queue_name
}

# Módulo SQS é criado SOMENTE se 'create_sqs_queue' for true E 'use_existing_sqs_trigger' for false
module "sqs" {
  source     = "./modules/sqs"
  count      = var.create_sqs_queue && !var.use_existing_sqs_trigger ? 1 : 0
  queue_name = local.queue_name
}

module "lambda" {
  source              = "./modules/lambda"
  lambda_name         = local.lambda_name
  role_arn            = module.iam.role_arn
  handler             = local.lambda_handler
  runtime             = local.lambda_runtime
  s3_bucket           = data.aws_s3_bucket.lambda_code_bucket.bucket
  s3_key              = local.s3_object_key
  environment_variables = local.merged_env_vars
  
  # Passando as variáveis de controle SQS e o ARN da fila EXISTENTE (agora resolvido por data source)
  create_sqs_queue         = var.create_sqs_queue
  use_existing_sqs_trigger = var.use_existing_sqs_trigger
  # O ARN passado para o módulo lambda agora vem do data source
  existing_sqs_queue_arn   = var.use_existing_sqs_trigger && var.existing_sqs_queue_name != "" ? data.aws_sqs_queue.existing_trigger_queue[0].arn : ""
  # O NOME da fila também pode ser passado para consistência, se o módulo lambda precisar
  existing_sqs_queue_name  = var.existing_sqs_queue_name # NOVO: Passa o nome da fila existente
}

module "iam" {
  source = "./modules/iam"

  lambda_role_name    = local.lambda_role_name
  logging_policy_name = local.logging_policy_name
  publish_policy_name = local.publish_policy_name
  
  # Passa o ARN da SQS para publicação. Se SQS não for criada OU se estivermos usando uma existente,
  # passa a string placeholder.
  sqs_queue_arn       = var.create_sqs_queue && !var.use_existing_sqs_trigger ? module.sqs[0].queue_arn : "SQS_PUBLISH_NOT_APPLICABLE"
  create_sqs_queue    = var.create_sqs_queue && !var.use_existing_sqs_trigger
  
  # Passa as variáveis para o módulo IAM para gerenciar permissões de consumo
  use_existing_sqs_trigger = var.use_existing_sqs_trigger
  # O ARN passado para o módulo IAM agora vem do data source
  existing_sqs_queue_arn   = var.use_existing_sqs_trigger && var.existing_sqs_queue_name != "" ? data.aws_sqs_queue.existing_trigger_queue[0].arn : ""
  consume_policy_name      = local.consume_policy_name 
}

module "cloudwatch" {
  source         = "./modules/cloudwatch"
  log_group_name = local.log_group_name
}

# Recurso para configurar a trigger da Lambda para uma fila SQS existente
# Este recurso será criado SOMENTE se 'use_existing_sqs_trigger' for true.
resource "aws_lambda_event_source_mapping" "sqs_event_source_mapping" {
  count = var.use_existing_sqs_trigger ? 1 : 0

  # O ARN usado aqui agora vem do data source
  event_source_arn = var.use_existing_sqs_trigger && var.existing_sqs_queue_name != "" ? data.aws_sqs_queue.existing_trigger_queue[0].arn : ""
  function_name    = module.lambda.lambda_function_name
  batch_size       = 10
  enabled          = true

  # A validação `existing_sqs_queue_name` e a mutualidade exclusiva
  # serão feitas no resource `aws_lambda_function` dentro do módulo Lambda.
  # (já implementado em `lambda/main.tf`)
}
