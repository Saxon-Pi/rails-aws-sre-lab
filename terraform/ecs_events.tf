# AWS Account 情報
data "aws_caller_identity" "current" {}

# ECS Event Capture 用 CloudWatch Logs
resource "aws_cloudwatch_log_group" "ecs_events" {
  name              = "/aws/events/ecs/containerinsights/${aws_ecs_cluster.main.name}/performance"
  retention_in_days = 7

  tags = {
    Name = "rails-aws-sre-lab-ecs-events"
  }
}

# EventBridge -> CloudWatch Logs を許可
resource "aws_cloudwatch_log_resource_policy" "ecs_events" {
  policy_name = "rails-aws-sre-lab-ecs-events-policy"

  policy_document = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "EventBridgeToCloudWatchLogs"
        Effect = "Allow"

        Principal = {
          Service = "events.amazonaws.com"
        }

        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]

        Resource = "${aws_cloudwatch_log_group.ecs_events.arn}:*"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "${aws_cloudwatch_event_rule.ecs_events.arn}"
          }
        }
      }
    ]
  })
}

# ECS が生成するイベントをすべて取得
resource "aws_cloudwatch_event_rule" "ecs_events" {
  name        = "EventsToLogs-rails-aws-sre-lab"
  description = "Capture ECS events for incident investigation"

  event_pattern = jsonencode({
    source = [
      "aws.ecs"
    ]
  })
}

# EventBridge Rule -> CloudWatch Logs
resource "aws_cloudwatch_event_target" "ecs_events" {
  rule = aws_cloudwatch_event_rule.ecs_events.name
  arn  = aws_cloudwatch_log_group.ecs_events.arn

  depends_on = [
    aws_cloudwatch_log_resource_policy.ecs_events
  ]
}
