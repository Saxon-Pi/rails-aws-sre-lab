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

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }

  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "rails-app"
      image = "${aws_ecr_repository.rails_app.repository_url}:7420020"

      essential = true

      portMappings = [
        {
          containerPort = 8080
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

      environment = [
        {
          name  = "THRUSTER_HTTP_PORT"
          value = "8080"
        },
        {
          name  = "DB_HOST"
          value = aws_db_instance.postgres.address
        },
        {
          name  = "DB_PORT"
          value = "5432"
        },
        {
          name  = "DB_USER"
          value = "app"
        }
      ]

      secrets = [
        {
          name      = "DB_PASSWORD"
          valueFrom = "${aws_db_instance.postgres.master_user_secret[0].secret_arn}:password::"
        },
        {
          name      = "RAILS_MASTER_KEY"
          valueFrom = "${data.aws_secretsmanager_secret.rails_master_key.arn}:RAILS_MASTER_KEY::"
        }
      ]

    }
  ])

  tags = {
    Name = "rails-aws-sre-lab-task"
  }
}

resource "aws_ecs_service" "rails" {
  name            = "rails-aws-sre-lab-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.rails.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets = [
      aws_subnet.private_1.id,
      aws_subnet.private_2.id
    ]

    security_groups = [
      aws_security_group.ecs.id
    ]

    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.rails.arn
    container_name   = "rails-app"
    container_port   = 8080
  }
}
