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

# MODIFICADO: Uso do 'count' para tornar o módulo SQS opcional
module "sqs" {
  source     = "./modules/sqs"
  count      = var.create_sqs_queue ? 1 : 0 # O módulo será criado se 'create_sqs_queue' for true
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
}

module "iam" {
  source = "./modules/iam"

  lambda_role_name    = local.lambda_role_name
  logging_policy_name = local.logging_policy_name
  publish_policy_name = local.publish_policy_name
  # MODIFICADO: Passa o ARN da SQS apenas se ela for criada, senão passa uma string vazia
  # Isso permite que o módulo IAM decida se anexa políticas SQS ou não
  sqs_queue_arn       = var.create_sqs_queue ? module.sqs[0].queue_arn : "" # Adicionado '[0]' devido ao 'count'
}

module "cloudwatch" {
  source         = "./modules/cloudwatch"
  log_group_name = local.log_group_name
}
