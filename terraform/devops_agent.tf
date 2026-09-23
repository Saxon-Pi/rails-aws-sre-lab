# AWS DevOps Agent
# Agent Space / Operator App / AWS Account Association

# IAM Role / Policy の反映待ち (作成順序を保証しながら一定時間待機)
resource "time_sleep" "wait_for_devops_agent_iam" {
  depends_on = [
    aws_iam_role.devops_agent_space,
    aws_iam_role_policy_attachment.devops_agent_space,
    aws_iam_role_policy.devops_agent_space_resource_explorer,
    aws_iam_role.devops_operator_app,
    aws_iam_role_policy_attachment.devops_operator_app
  ]

  create_duration = "30s"
}

# Agent Space + Operator App
resource "awscc_devopsagent_agent_space" "main" {
  name        = "rails-aws-sre-lab"
  description = "DevOps Agent Space for rails-aws-sre-lab"

  operator_app = {
    iam = {
      operator_app_role_arn = aws_iam_role.devops_operator_app.arn
    }
  }

  depends_on = [
    time_sleep.wait_for_devops_agent_iam
  ]
}

# 現在の AWS Account を monitor account として Agent Space に関連付ける
resource "awscc_devopsagent_association" "monitoring_account" {
  agent_space_id = awscc_devopsagent_agent_space.main.id
  service_id     = "aws"

  configuration = {
    aws = {
      assumable_role_arn = aws_iam_role.devops_agent_space.arn
      account_id         = data.aws_caller_identity.current.account_id
      account_type       = "monitor"
      resources          = []
    }
  }

  depends_on = [
    awscc_devopsagent_agent_space.main
  ]
}
