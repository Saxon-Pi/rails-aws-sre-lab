// Task Execution Role (ECS/Fargateが使用)
resource "aws_iam_role" "ecs_task_execution" {
  name = "rails-aws-sre-lab-ecs-task-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "rails-aws-sre-lab-ecs-task-execution-role"
  }
}

// ECS Task 起動時に必要な Policy をアタッチ
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role = aws_iam_role.ecs_task_execution.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

// Secrets Manager から DB_PASSWORD / Secret を取得する Policy
resource "aws_iam_role_policy" "ecs_task_execution_secrets" {
  name = "rails-aws-sre-lab-ecs-secrets-policy"
  role = aws_iam_role.ecs_task_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          aws_db_instance.postgres.master_user_secret[0].secret_arn,
          data.aws_secretsmanager_secret.rails_master_key.arn
        ]
      }
    ]
  })
}

// Amazon Q Developer in chat applications の Slack チャネルロール
resource "aws_iam_role" "chatbot" {
  name = "AWSChatbot-role"
  path = "/service-role/"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [{
      Effect = "Allow"

      Principal = {
        Service = "chatbot.amazonaws.com"
      }

      Action = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "chatbot_notifications_only" {
  name = "rails-aws-sre-lab-chatbot-notifications-only"

  description = "NotificationsOnly policy for Amazon Q Developer in chat applications"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "cloudwatch:Describe*",
          "cloudwatch:Get*",
          "cloudwatch:List*"
        ]

        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "chatbot_notifications_only" {
  role       = aws_iam_role.chatbot.name
  policy_arn = aws_iam_policy.chatbot_notifications_only.arn
}

resource "aws_iam_role_policy_attachment" "chatbot_amazon_q" {
  role       = aws_iam_role.chatbot.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonQDeveloperAccess"
}

// GitHub Actions OIDC
resource "aws_iam_openid_connect_provider" "github_actions" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com"
  ]
}

resource "aws_iam_role" "github_actions_deploy" {
  name = "rails-aws-sre-lab-github-actions-deploy-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Federated = aws_iam_openid_connect_provider.github_actions.arn
        }

        Action = "sts:AssumeRoleWithWebIdentity"

        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }

          StringLike = {
            # このGitHub Repository から発行された OIDC Token のみ、この IAM Role を Assume できる
            "token.actions.githubusercontent.com:sub" = "repo:Saxon-Pi/rails-aws-sre-lab:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "rails-aws-sre-lab-github-actions-deploy-role"
  }
}

# GitHub Actions Deploy Policy
resource "aws_iam_policy" "github_actions_deploy" {
  name        = "rails-aws-sre-lab-github-actions-deploy-policy"
  description = "Permissions for GitHub Actions to deploy Rails application to ECS"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # ECR login
      {
        Effect = "Allow"

        Action = [
          "ecr:GetAuthorizationToken"
        ]

        Resource = "*"
      },

      # ECR push
      {
        Effect = "Allow"

        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage"
        ]

        Resource = aws_ecr_repository.rails_app.arn
      },

      # ECS deployment
      {
        Effect = "Allow"

        Action = [
          "ecs:RegisterTaskDefinition",
          "ecs:DescribeTaskDefinition",
          "ecs:DescribeServices",
          "ecs:UpdateService"
        ]

        Resource = "*"
      },

      # Pass ECS Task Execution Role
      {
        Effect = "Allow"

        Action = [
          "iam:PassRole"
        ]

        Resource = aws_iam_role.ecs_task_execution.arn

        Condition = {
          StringEquals = {
            "iam:PassedToService" = "ecs-tasks.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = {
    Name = "rails-aws-sre-lab-github-actions-deploy-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_deploy" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.github_actions_deploy.arn
}
