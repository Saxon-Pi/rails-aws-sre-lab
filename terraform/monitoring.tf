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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
          period = 300

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
