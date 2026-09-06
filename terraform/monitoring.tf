# CloudWatch Dashboard は横幅が 24 のため、以下のようなレイアウトにする
#        x=0                 x=12                x=24
#         │                    │                    │
# y=0     ┌────────────────────┬────────────────────┐
#         │ RequestCount       │ TargetResponseTime │
#         │                    │                    │
#         │ width=12           │ width=12           │
#         │ height=6           │ height=6           │
# y=6     ├────────────────────┼────────────────────┤
#         │ ALB 5XX            │ Target Health      │
#         │                    │                    │
#         │ width=12           │ width=12           │
#         │ height=6           │ height=6           │
# y=12    └────────────────────┴────────────────────┘

resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "rails-aws-sre-lab"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "ALB Request Count"
          region = "ap-northeast-1"
          stat   = "Sum"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "RequestCount",
              "LoadBalancer",
              aws_lb.main.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6

        properties = {
          title  = "Target Response Time"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "TargetResponseTime",
              "LoadBalancer",
              aws_lb.main.arn_suffix,
              "TargetGroup",
              aws_lb_target_group.rails.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "ALB 5XX"
          region = "ap-northeast-1"
          stat   = "Sum"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "HTTPCode_ELB_5XX_Count",
              "LoadBalancer",
              aws_lb.main.arn_suffix
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 6
        width  = 12
        height = 6

        properties = {
          title  = "Target Health"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ApplicationELB",
              "HealthyHostCount",
              "TargetGroup",
              aws_lb_target_group.rails.arn_suffix,
              "LoadBalancer",
              aws_lb.main.arn_suffix
            ],
            [
              ".",
              "UnHealthyHostCount",
              ".",
              ".",
              ".",
              "."
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "ECS CPU Utilization"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ECS",
              "CPUUtilization",
              "ClusterName",
              aws_ecs_cluster.main.name,
              "ServiceName",
              aws_ecs_service.rails.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 12
        width  = 12
        height = 6

        properties = {
          title  = "ECS Memory Utilization"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/ECS",
              "MemoryUtilization",
              "ClusterName",
              aws_ecs_cluster.main.name,
              "ServiceName",
              aws_ecs_service.rails.name
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 18
        width  = 12
        height = 6

        properties = {
          title  = "RDS CPU Utilization"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/RDS",
              "CPUUtilization",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 18
        width  = 12
        height = 6

        properties = {
          title  = "RDS Database Connections"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/RDS",
              "DatabaseConnections",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 0
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "RDS Freeable Memory"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/RDS",
              "FreeableMemory",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 24
        width  = 12
        height = 6

        properties = {
          title  = "RDS Free Storage Space"
          region = "ap-northeast-1"
          stat   = "Average"
          period = 60

          metrics = [
            [
              "AWS/RDS",
              "FreeStorageSpace",
              "DBInstanceIdentifier",
              aws_db_instance.postgres.identifier
            ]
          ]
        }
      }
    ]
  })
}

# SNS 通知
resource "aws_sns_topic" "alerts" {
  name = "rails-aws-sre-lab-alerts"

  tags = {
    Name = "rails-aws-sre-lab-alerts"
  }
}

# アラームテストは CLI から実行可能
# aws cloudwatch set-alarm-state \
#   --alarm-name rails-aws-sre-lab-ecs-cpu-high \
#   --state-value ALARM \
#   --state-reason "Manual alarm test"

resource "aws_cloudwatch_metric_alarm" "ecs_cpu_high" {
  alarm_name        = "rails-aws-sre-lab-ecs-cpu-high"
  alarm_description = "ECS service CPU utilization is high"

  namespace   = "AWS/ECS"
  metric_name = "CPUUtilization"

  # 5分平均で80%超が2期間連続したらアラームを発報
  statistic           = "Average"
  period              = 300
  evaluation_periods  = 2
  threshold           = 80
  comparison_operator = "GreaterThanThreshold"

  dimensions = {
    ClusterName = aws_ecs_cluster.main.name
    ServiceName = aws_ecs_service.rails.name
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  # 回復したらOK通知をする
  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  # メトリクスが一時的に取得できなかった場合に異常扱いしない
  treat_missing_data = "notBreaching"

  tags = {
    Name = "rails-aws-sre-lab-ecs-cpu-high"
  }
}

# ALB 自身が返す 5XX を監視
# ->「ALBそのものの障害」だけでなく、「Healthy Target が 0」など、
#    ALB が Target に正常に転送・処理できず、ALB側で 5XX を生成した状況を捉える
resource "aws_cloudwatch_metric_alarm" "alb_5xx" {
  alarm_name        = "rails-aws-sre-lab-alb-5xx"
  alarm_description = "ALB returned 5XX responses"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_ELB_5XX_Count"

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"

  tags = {
    Name = "rails-aws-sre-lab-alb-5xx"
  }
}

# Healthy な Task の台数を監視
resource "aws_cloudwatch_metric_alarm" "alb_target_unhealthy" {
  alarm_name        = "rails-aws-sre-lab-target-unhealthy"
  alarm_description = "No healthy targets are available in the ALB target group"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HealthyHostCount"

  statistic           = "Minimum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "LessThanThreshold"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.rails.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  # メトリクスが一時的に取得できなかった場合に異常扱いする
  # -> Healthy な Task が 0台のとき、Missing 状態になるため
  treat_missing_data = "breaching"

  tags = {
    Name = "rails-aws-sre-lab-target-unhealthy"
  }
}

# Task が返す 5XX を監視
resource "aws_cloudwatch_metric_alarm" "target_5xx" {
  alarm_name        = "rails-aws-sre-lab-target-5xx"
  alarm_description = "ALB target returned 5XX responses"

  namespace   = "AWS/ApplicationELB"
  metric_name = "HTTPCode_Target_5XX_Count"

  statistic           = "Sum"
  period              = 60
  evaluation_periods  = 1
  threshold           = 1
  comparison_operator = "GreaterThanOrEqualToThreshold"

  dimensions = {
    LoadBalancer = aws_lb.main.arn_suffix
    TargetGroup  = aws_lb_target_group.rails.arn_suffix
  }

  alarm_actions = [
    aws_sns_topic.alerts.arn
  ]

  ok_actions = [
    aws_sns_topic.alerts.arn
  ]

  treat_missing_data = "notBreaching"

  tags = {
    Name = "rails-aws-sre-lab-target-5xx"
  }
}
