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

// Rails アプリケーションの CI/CD 用 Role
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
            "token.actions.githubusercontent.com:sub" = "repo:Saxon-Pi@107937925/rails-aws-sre-lab@1342346266:*"
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

// Terraform インフラ用の CI/CD 用 Role
resource "aws_iam_role" "github_actions_terraform" {
  name = "rails-aws-sre-lab-github-actions-terraform-role"

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
            "token.actions.githubusercontent.com:sub" = "repo:Saxon-Pi@107937925/rails-aws-sre-lab@1342346266:*"
          }
        }
      }
    ]
  })

  tags = {
    Name = "rails-aws-sre-lab-github-actions-terraform-role"
  }
}

resource "aws_iam_policy" "github_actions_terraform" {
  name        = "rails-aws-sre-lab-github-actions-terraform-policy"
  description = "Permissions for GitHub Actions to manage Rails AWS SRE Lab infrastructure with Terraform"

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      # =====================================================
      # Terraform Remote State
      # =====================================================
      {
        Sid    = "TerraformStateBucket"
        Effect = "Allow"

        Action = [
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]

        Resource = "arn:aws:s3:::rails-aws-sre-lab-terraform-state"
      },

      {
        Sid    = "TerraformStateObject"
        Effect = "Allow"

        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]

        Resource = [
          "arn:aws:s3:::rails-aws-sre-lab-terraform-state/terraform.tfstate",
          "arn:aws:s3:::rails-aws-sre-lab-terraform-state/terraform.tfstate.tflock"
        ]
      },

      # =====================================================
      # VPC / Network
      # =====================================================
      {
        Sid    = "EC2Infrastructure"
        Effect = "Allow"

        Action = [
          "ec2:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # ALB
      # =====================================================
      {
        Sid    = "ElasticLoadBalancing"
        Effect = "Allow"

        Action = [
          "elasticloadbalancing:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # ECS
      # =====================================================
      {
        Sid    = "ECS"
        Effect = "Allow"

        Action = [
          "ecs:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # ECR
      # =====================================================
      {
        Sid    = "ECR"
        Effect = "Allow"

        Action = [
          "ecr:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # RDS
      # =====================================================
      {
        Sid    = "RDS"
        Effect = "Allow"

        Action = [
          "rds:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # CloudWatch / Logs
      # =====================================================
      {
        Sid    = "CloudWatch"
        Effect = "Allow"

        Action = [
          "cloudwatch:*",
          "logs:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # SNS
      # =====================================================
      {
        Sid    = "SNS"
        Effect = "Allow"

        Action = [
          "sns:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # Secrets Manager
      # =====================================================
      {
        Sid    = "SecretsManager"
        Effect = "Allow"

        Action = [
          "secretsmanager:DescribeSecret",
          "secretsmanager:GetResourcePolicy",
          "secretsmanager:ListSecretVersionIds"
        ]

        Resource = "*"
      },

      # =====================================================
      # Application Auto Scaling
      # =====================================================
      {
        Sid    = "ApplicationAutoScaling"
        Effect = "Allow"

        Action = [
          "application-autoscaling:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # IAM
      # =====================================================
      {
        Sid    = "IAM"
        Effect = "Allow"

        Action = [
          "iam:GetRole",
          "iam:GetPolicy",
          "iam:GetPolicyVersion",
          "iam:GetOpenIDConnectProvider",

          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:ListPolicyVersions",

          "iam:CreateRole",
          "iam:UpdateAssumeRolePolicy",
          "iam:DeleteRole",

          "iam:CreatePolicy",
          "iam:CreatePolicyVersion",
          "iam:DeletePolicy",
          "iam:DeletePolicyVersion",

          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",

          "iam:PutRolePolicy",
          "iam:GetRolePolicy",
          "iam:DeleteRolePolicy",

          "iam:TagRole",
          "iam:UntagRole",
          "iam:TagPolicy",
          "iam:UntagPolicy",

          "iam:PassRole"
        ]

        Resource = "*"
      },

      # =====================================================
      # Amazon Q Developer in chat applications
      # AWS Chatbot API namespace
      # =====================================================
      {
        Sid    = "Chatbot"
        Effect = "Allow"

        Action = [
          "chatbot:*"
        ]

        Resource = "*"
      },

      # =====================================================
      # Route 53
      # =====================================================
      {
        Sid    = "Route53"
        Effect = "Allow"

        Action = [
          "route53:ListHostedZones",
          "route53:GetHostedZone",
          "route53:ListResourceRecordSets",
          "route53:ListTagsForResource",
          "route53:ChangeResourceRecordSets",
          "route53:GetChange"
        ]

        Resource = "*"
      },

      # =====================================================
      # AWS Certificate Manager
      # =====================================================
      {
        Sid    = "ACM"
        Effect = "Allow"

        Action = [
          "acm:RequestCertificate",
          "acm:DescribeCertificate",
          "acm:DeleteCertificate",
          "acm:ListTagsForCertificate",
          "acm:AddTagsToCertificate",
          "acm:RemoveTagsFromCertificate"
        ]

        Resource = "*"
      },

      # =====================================================
      # EventBridge Rule
      # =====================================================
      {
        Sid    = "EventBridge"
        Effect = "Allow"

        Action = [
          "events:DescribeRule",
          "events:ListTargetsByRule",
          "events:PutRule",
          "events:PutTargets",
          "events:RemoveTargets",
          "events:DeleteRule",
          "events:ListTagsForResource",
          "events:TagResource",
          "events:UntagResource"
        ]

        Resource = "*"
      },

      # =====================================================
      # DevOps Agent & CloudFormation
      # → awscc Provider が AWS Cloud Control API / CloudFormation resource API
      #   を使って awscc_devopsagent_agent_space を作成するため
      # =====================================================
      {
        Sid = "CloudControl"

        Effect = "Allow"

        Action = [
          "cloudformation:CreateResource",
          "cloudformation:GetResource",
          "cloudformation:UpdateResource",
          "cloudformation:DeleteResource",
          "cloudformation:ListResources"
        ]

        Resource = "*"
      },

      {
        Sid    = "DevOpsAgent"
        Effect = "Allow"

        Action = [
          "aidevops:GetAgentSpace",
          "aidevops:ListAgentSpaces",

          "aidevops:GetAssociation",
          "aidevops:ListAssociations",

          "aidevops:CreateAgentSpace",
          "aidevops:UpdateAgentSpace",
          "aidevops:DeleteAgentSpace",

          "aidevops:AssociateService",
          "aidevops:UpdateAssociation",
          "aidevops:DisassociateService",

          "aidevops:GetOperatorApp",
          "aidevops:ListTagsForResource",
          "aidevops:TagResource",
          "aidevops:UntagResource"
        ]

        Resource = "*"
      }
    ]
  })

  tags = {
    Name = "rails-aws-sre-lab-github-actions-terraform-policy"
  }
}

resource "aws_iam_role_policy_attachment" "github_actions_terraform" {
  role       = aws_iam_role.github_actions_terraform.name
  policy_arn = aws_iam_policy.github_actions_terraform.arn
}

// DevOps Agent - 調査用 Agent Space Role

resource "aws_iam_role" "devops_agent_space" {
  name = "rails-aws-sre-lab-devops-agent-space-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "aidevops.amazonaws.com"
        }

        Action = "sts:AssumeRole"

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devops_agent_space" {
  role = aws_iam_role.devops_agent_space.name

  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsAgentAccessPolicy"
}

// DevOps Agent - Operator App 用 Role

resource "aws_iam_role" "devops_operator_app" {
  name = "rails-aws-sre-lab-devops-operator-app-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "aidevops.amazonaws.com"
        }

        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]

        Condition = {
          StringEquals = {
            "aws:SourceAccount" = data.aws_caller_identity.current.account_id
          }

          ArnLike = {
            "aws:SourceArn" = "arn:aws:aidevops:${var.aws_region}:${data.aws_caller_identity.current.account_id}:agentspace/*"
          }
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "devops_operator_app" {
  role = aws_iam_role.devops_operator_app.name

  policy_arn = "arn:aws:iam::aws:policy/AIDevOpsOperatorAppAccessPolicy"
}

// Agent Space Role に Resource Explorer 用 Service-linked Role 作成権限を追加
// (Topology discovery で Resource Explorer を使うため)
resource "aws_iam_role_policy" "devops_agent_space_resource_explorer" {
  name = "AllowCreateResourceExplorerServiceLinkedRole"
  role = aws_iam_role.devops_agent_space.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "iam:CreateServiceLinkedRole"
        ]

        Resource = "arn:aws:iam::*:role/aws-service-role/resource-explorer-2.amazonaws.com/AWSServiceRoleForResourceExplorer"
      }
    ]
  })
}
