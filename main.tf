resource "aws_iam_role" "lambda_exec_role" {
  name = "${var.project_name}-lambda-exec-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_policy" {
  role       = aws_iam_role.lambda_exec_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Add S3 permissions if your Lambda cleans S3
resource "aws_iam_policy" "s3_cleanup_policy" {
   count       = var.enable_s3_cleanup ? 1 : 0
   name        = "${var.project_name}-s3-cleanup-policy"
   description = "IAM policy for Lambda to clean up S3"

   policy = jsonencode({
     Version = "2012-10-17",
     Statement = [
       {
         Effect   = "Allow",
         Action   = [
           "s3:ListBucket",
           "s3:DeleteObject"
         ],
         Resource = [
           "arn:aws:s3:::${var.s3_bucket_name}",
           "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_prefix}*"
         ]
       }
     ]
   })
}

resource "aws_iam_role_policy_attachment" "s3_cleanup_policy_attachment" {
   count      = var.enable_s3_cleanup ? 1 : 0
   role       = aws_iam_role.lambda_exec_role.name
   policy_arn = aws_iam_policy.s3_cleanup_policy[0].arn
}


# --- Lambda Function ---
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_dir  = "${path.module}/lambda"
  output_path = "${path.module}/lambda/lambda_function.zip"
}

resource "aws_lambda_function" "scheduled_lambda" {
  function_name    = "${var.project_name}-scheduled-function"
  filename         = data.archive_file.lambda_zip.output_path
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  role             = aws_iam_role.lambda_exec_role.arn
  handler          = "lambda_function.lambda_handler"
  runtime          = "python3.9" # Or your preferred Python version
  timeout          = 30          # seconds
  memory_size      = 128         # MB

  tags = {
    Project = var.project_name
    Purpose = "Scheduled Cleanup/Logging"
  }
}

# --- CloudWatch Event Rule (EventBridge) ---
resource "aws_cloudwatch_event_rule" "every_6_hours" {
  name                = "${var.project_name}-every-6-hours-rule"
  description         = "Triggers the Lambda function every 6 hours"
  schedule_expression = "rate(6 hours)" # Or "cron(0 */6 * * ? *)" for specific hour (UTC)

  tags = {
    Project = var.project_name
    Purpose = "Scheduled Trigger"
  }
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.every_6_hours.name
  target_id = "invoke-scheduled-lambda"
  arn       = aws_lambda_function.scheduled_lambda.arn
}

# --- Permission for CloudWatch Events to invoke Lambda ---
resource "aws_lambda_permission" "allow_cloudwatch_to_invoke_lambda" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.scheduled_lambda.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.every_6_hours.arn
}

# CloudWatch Log Group for the Lambda function
resource "aws_cloudwatch_log_group" "lambda_log_group" {
  name              = "/aws/lambda/${aws_lambda_function.scheduled_lambda.function_name}"
  retention_in_days = 7 

  tags = {
    Project = var.project_name
    Purpose = "Lambda Logs"
  }
}
