#########################################
# variables.tf (cloudwatch module)
#########################################

variable "log_group_name" {
  type        = string
  description = "Nome do grupo de logs do Lambda"
}