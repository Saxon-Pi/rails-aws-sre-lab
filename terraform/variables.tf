variable "aws_region" {
  type    = string
  default = "ap-northeast-1"
}

variable "ecr_repository_name" {
  type    = string
  default = "rails-aws-sre-lab"
}

# Amazon Q Developer in chat applications の Slack ワークスペース ID
variable "slack_workspace_id" {
  description = "Slack Workspace ID"
  type        = string
}

# Slack のチャンネル詳細から確認できるチャンネル ID
variable "slack_channel_id" {
  description = "Slack Channel ID for alerts"
  type        = string
}

# Kiro Web の IAM Role の Trust Policy に設定する STS SourceIdentity
# https://app.kiro.dev/settings/account -> UserID から確認可能
variable "kiro_user_id" {
  description = "Kiro Web user ID used as STS SourceIdentity"
  type        = string
}