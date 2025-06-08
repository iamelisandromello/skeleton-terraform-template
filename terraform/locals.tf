#########################################
# locals.tf (root module)
#########################################

locals {
  # Identificadores padronizados
  environment_suffix   = var.environment == "prod" ? "" : "-${var.environment}"

  lambda_name          = "${var.project_name}${local.environment_suffix}"
  lambda_role_name     = "${var.project_name}${local.environment_suffix}_execution_role"
  logging_policy_name  = "${var.project_name}${local.environment_suffix}_logging_policy"
  publish_policy_name  = "${var.project_name}${local.environment_suffix}-lambda-sqs-publish"

  # Infraestrutura associada
  log_group_name       = "/aws/lambda/${local.lambda_name}"
  queue_name           = "${local.lambda_name}-queue"

  s3_bucket_name       = var.s3_bucket_name
  s3_object_key        = "${var.project_name}.zip"

  merged_env_vars = merge(
    var.global_env_vars,
    var.environments[var.environment]
  )

  lambda_handler  = "main/app.handler"
  lambda_runtime  = "nodejs20.x"
}
