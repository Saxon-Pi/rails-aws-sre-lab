# SecretsManager で rails-aws-sre-lab-master-key: RAILS_MASTER_KEY を手動作成すること
data "aws_secretsmanager_secret" "rails_master_key" {
  name = "rails-aws-sre-lab-master-key"
}
