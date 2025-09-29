provider "aws" {
  region = "ap-south-1"
}

# Generate unique suffix to avoid duplicate errors
resource "random_id" "suffix" {
  byte_length = 4
}

# Lambda Function
resource "aws_lambda_function" "snapshot_cleaner" {
  filename      = "../docker/lambda/lambda.zip"
  function_name = "snapshot_cleaner"
  role          = aws_iam_role.lambda_exec.arn
  handler       = "snapshot_cleaner.lambda_handler"
  runtime       = "python3.12"

  environment {
    variables = {
      RETENTION_DAYS = 0
      SNS_TOPIC_ARN  = aws_sns_topic.alerts.arn
    }
  }
}

# IAM Role for Lambda
resource "aws_iam_role" "lambda_exec" {
  name = "lambda_snapshot_role_${random_id.suffix.hex}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# IAM Policy for Lambda
resource "aws_iam_role_policy" "lambda_policy" {
  name   = "lambda_snapshot_policy"
  role   = aws_iam_role.lambda_exec.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["ec2:DescribeSnapshots", "ec2:DeleteSnapshot", "ec2:DescribeInstances", "ec2:DescribeImages"]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"]
        Resource = "arn:aws:logs:*:*:log-group:/aws/lambda/snapshot_cleaner:*"
      },
      {
        Effect = "Allow"
        Action = "sns:Publish"
        Resource = aws_sns_topic.alerts.arn
      }
    ]
  })
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "snapshot_alerts"
}

# SNS Email Subscription
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.alerts.arn
  protocol  = "email"
  endpoint  = "venkyvenky7353@gmail.com" # Replace with your email
}

# CloudWatch Event Rule for Daily Trigger
resource "aws_cloudwatch_event_rule" "daily" {
  name                = "daily_snapshot_cleanup"
  schedule_expression = "cron(0 0 * * ? *)" # Daily at 00:00 UTC (5:30 AM IST)
}

# CloudWatch Event Target
resource "aws_cloudwatch_event_target" "lambda_target" {
  rule      = aws_cloudwatch_event_rule.daily.name
  target_id = "snapshot_cleaner"
  arn       = aws_lambda_function.snapshot_cleaner.arn
}

# Lambda Permission for CloudWatch
resource "aws_lambda_permission" "allow_cloudwatch" {
  statement_id  = "AllowExecutionFromCloudWatch"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.snapshot_cleaner.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.daily.arn
}

# Budget Alert for $2 Limit
resource "aws_budgets_budget" "snapshot_budget" {
  name              = "snapshot-cleaner-budget-${random_id.suffix.hex}"
  budget_type       = "COST"
  limit_amount      = "2.0"
  limit_unit        = "USD"
  time_period_start = "2025-09-29_00:00"
  time_period_end   = "2025-10-29_00:00"
  time_unit         = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = ["venkyvenky7353@gmail.com"] # Replace with your email
  }
}
