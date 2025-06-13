#########################################
# variables.tf (lambda module)
#########################################

variable "lambda_name"      { type = string }
variable "role_arn"         { type = string }
variable "s3_bucket"        { type = string }
variable "s3_key"           { type = string }

variable "environment_variables" {
  type = map(string)
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}

# NOVO: Variáveis passadas do módulo raiz para a Lambda para preconditions
variable "create_sqs_queue" {
  description = "Define se uma nova fila SQS será criada (para uso em preconditions)."
  type        = bool
  default     = false
}

variable "use_existing_sqs_trigger" {
  description = "Define se uma fila SQS existente será usada como trigger (para uso em preconditions)."
  type        = bool
  default     = false
}

variable "existing_sqs_queue_arn" {
  description = "ARN da fila SQS existente se usada como trigger (para uso em preconditions)."
  type        = string
  default     = ""
}
