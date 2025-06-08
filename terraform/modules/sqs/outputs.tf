#########################################
# outputs.tf (sqs module)
#########################################

output "queue_url" {
  value = aws_sqs_queue.queue.id
}

output "queue_arn" {
  value = aws_sqs_queue.queue.arn
}
