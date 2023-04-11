provider "aws" {
    region = "us-east-1"
}

resource "aws_iam_role" "lambda_role" {
    name = "terraform_aws_lambda_role"
    assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}

/* resource "aws_iam_policy" "iam_policy_for_lambda" {
name = "aws_iam_policy_for_terraform_aws_lambda_role"
path = "/"
description = "AWS IAM Policy for managing aws lambda role"
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "logs: CreateLogGroup",
                "logs: CreateLogStream",
                "logs: PutLogEvents"
            ],
            "Resource": "*",
            "Effect": "Allow"
        }
    ]
}
EOF
} */

resource "aws_iam_policy" "iam_policy_for_lambda" {
name = "aws_iam_policy_for_terraform_aws_lambda_role"
path = "/"
description = "AWS IAM Policy for managing aws lambda role"
policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "*"
        },
        {
            "Action": "ec2:*",
            "Effect": "Allow",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "elasticloadbalancing:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "cloudwatch:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "autoscaling:*",
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": "iam:CreateServiceLinkedRole",
            "Resource": "*",
            "Condition": {
                "StringEquals": {
                    "iam:AWSServiceName": [
                        "autoscaling.amazonaws.com",
                        "ec2scheduled.amazonaws.com",
                        "elasticloadbalancing.amazonaws.com",
                        "spot.amazonaws.com",
                        "spotfleet.amazonaws.com",
                        "transitgateway.amazonaws.com"
                    ]
                }
            }
        }
    ]
}
EOF
}

# Policy Attachment on the role.
resource "aws_iam_role_policy_attachment" "attach_iam_policy_to_iam_role" {
    role       = aws_iam_role.lambda_role.name
    policy_arn = aws_iam_policy.iam_policy_for_lambda.arn
}

data "archive_file" "zip_the_python_code" {
    type = "zip"
    source_dir = "${path.module}/python/"
    output_path = "${path.module}/python/EBS-volumes.zip"
}

resource "aws_lambda_function" "terraform_lambda_function" {
    filename = "${path.module}/python/EBS-volumes.zip"
    function_name = "Test-lambda-function"
    role = aws_iam_role.lambda_role.arn
    handler = "EBS-volumes.lambda_handler"
    runtime = "python3.9"
    depends_on = [aws_iam_role_policy_attachment.attach_iam_policy_to_iam_role]
}



# Create a CloudWatch Event Rule to trigger the Lambda function
resource "aws_cloudwatch_event_rule" "example" {
  name        = "Test_lambda_function_event_rule"
  description = "Trigger the example Lambda function at midnight every day"
  /* schedule_expression = "rate(5 minutes)" */
  schedule_expression = "cron(0 0 * * ? *)"
}

# Create a CloudWatch Event Target to trigger the Lambda function
resource "aws_cloudwatch_event_target" "example" {
  rule      = aws_cloudwatch_event_rule.example.name
  arn       = aws_lambda_function.terraform_lambda_function.arn
  target_id = "example_target"
}

# Add the EventBridge trigger to the Lambda function
resource "aws_lambda_permission" "example" {
  statement_id  = "example_statement"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.terraform_lambda_function.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.example.arn
}


output "terraform_aws_role_output" {
    value = aws_iam_role.lambda_role.name
}

output "terraform_aws_role_arn_output" {
    value = aws_iam_role.lambda_role.arn
}

output "terraform_logging_arn_output" {
    value = aws_iam_policy.iam_policy_for_lambda.arn
}
