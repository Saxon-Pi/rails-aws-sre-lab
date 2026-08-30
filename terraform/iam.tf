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

// Secrets Manager から DB_PASSWORD を取得する Policy
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
        Resource = aws_db_instance.postgres.master_user_secret[0].secret_arn
      }
    ]
  })
}
