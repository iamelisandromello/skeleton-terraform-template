#########################################
# variables.tf (iam module)
#########################################

variable "lambda_role_name" {
  description = "Nome da role IAM para a função Lambda"
  type        = string
}

variable "logging_policy_name" {
  description = "Nome da política IAM para logs da Lambda"
  type        = string
}

variable "publish_policy_name" {
  description = "Nome da política IAM para publicação em SQS"
  type        = string
}

variable "sqs_queue_arn" {
  description = "ARN da fila SQS para permissões de publicação. Pode ser 'SQS not created' se a fila não for criada."
  type        = string
}

# Variável para controlar a criação condicional da política de PUBLICAÇÃO em SQS
variable "create_sqs_queue" {
  description = "Define se a fila SQS (e, portanto, sua política de publicação) deve ser criada."
  type        = bool
  default     = false # Padrão é false, para ser consistente com a nova lógica
}

# NOVO: Variável para controlar a criação condicional da política de CONSUMO em SQS
variable "use_existing_sqs_trigger" {
  description = "Define se a política para consumir de uma fila SQS existente deve ser criada."
  type        = bool
  default     = false
}

# NOVO: ARN da fila SQS existente para permissões de consumo
variable "existing_sqs_queue_arn" {
  description = "ARN da fila SQS existente para permissões de consumo."
  type        = string
  default     = "" # Padrão vazio
}

# NOVO: Nome da política IAM para consumo de SQS
variable "consume_policy_name" {
  description = "Nome da política IAM para consumo de SQS."
  type        = string
}
