#########################################
# variables.tf (lambda module)
#########################################

variable "lambda_name"  { type = string }
variable "role_arn"     { type = string }
variable "s3_bucket"    { type = string }
variable "s3_key"       { type = string }

variable "environment_variables" {
  type = map(string)
}

variable "handler" {
  type = string
}

variable "runtime" {
  type = string
}