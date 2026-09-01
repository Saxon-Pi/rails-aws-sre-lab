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
      }
    ]
  })
}
