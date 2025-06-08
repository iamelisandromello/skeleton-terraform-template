#########################################
# outputs.tf (cloudwatch module)
#########################################

output "log_group_name" {
  value = aws_cloudwatch_log_group.lambda_log_group.name
}
