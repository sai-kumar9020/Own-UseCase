output "lambda_function_name" {
  description = "The name of the deployed Lambda function."
  value       = aws_lambda_function.scheduled_lambda.function_name
}

output "cloudwatch_event_rule_name" {
  description = "The name of the CloudWatch Event Rule."
  value       = aws_cloudwatch_event_rule.every_6_hours.name
}

output "lambda_log_group_name" {
  description = "The name of the CloudWatch Log Group for the Lambda function."
  value       = aws_cloudwatch_log_group.lambda_log_group.name
}