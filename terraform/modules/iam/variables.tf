#########################################
# variables.tf (iam module)
#########################################

variable "lambda_role_name" {
  description = "Nome da IAM Role de execução da Lambda"
  type        = string
}

variable "logging_policy_name" {
  description = "Nome da policy de logs da Lambda"
  type        = string
}

variable "publish_policy_name" {
  description = "Nome da policy que publica na SQS"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN da fila SQS"
  type        = string
}

# NOVO: Variável para controlar a criação condicional da política SQS
variable "create_sqs_queue" {
  description = "Define se a fila SQS (e, portanto, sua política de publicação) deve ser criada."
  type        = bool
  default     = true # O padrão é true para manter o comportamento existente
}
