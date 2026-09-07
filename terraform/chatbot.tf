resource "aws_chatbot_slack_channel_configuration" "alerts" {
  configuration_name = "rails-aws-sre-lab-alerts"

  slack_team_id    = var.slack_workspace_id
  slack_channel_id = var.slack_channel_id

  iam_role_arn = aws_iam_role.chatbot.arn

  sns_topic_arns = [
    aws_sns_topic.alerts.arn
  ]
}
