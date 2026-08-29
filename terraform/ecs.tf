resource "aws_ecs_cluster" "main" {
  name = "rails-aws-sre-lab-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Name = "rails-aws-sre-lab-cluster"
  }
}

resource "aws_cloudwatch_log_group" "ecs" {
  name              = "/ecs/rails-aws-sre-lab"
  retention_in_days = 7

  tags = {
    Name = "rails-aws-sre-lab-logs"
  }
}

resource "aws_ecs_task_definition" "rails" {
  family                   = "rails-aws-sre-lab"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"

  cpu    = "256"
  memory = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "rails-app"
      image = "${aws_ecr_repository.rails_app.repository_url}:7420020"

      essential = true

      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]

      # Rails/Puma の標準出力を、AWS では CloudWatch Logs で確認できるようにする
      logConfiguration = {
        logDriver = "awslogs"

        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.ecs.name
          "awslogs-region"        = "ap-northeast-1"
          "awslogs-stream-prefix" = "rails"
        }
      }
    }
  ])

  tags = {
    Name = "rails-aws-sre-lab-task"
  }
}
