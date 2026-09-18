/*
Route 53 Hosted Zone ← 手動作成済み / data参照
saxon-aws-lab.click
│
├── NS  ← Route 53 が作成済み
├── SOA ← Route 53 が作成済み
│
├── ACM DNS検証用 CNAME      ← Terraform で作成
│
└── app.saxon-aws-lab.click ← Terraform で作成
        A Alias
           │
           ▼
          ALB
*/

# 既存の Route 53 Hosted Zone
# → import ではなく「既存リソースを検索して、その属性をTerraform内で参照する」 ための Data Source
data "aws_route53_zone" "main" {
  name         = "saxon-aws-lab.click"
  private_zone = false
}

# アプリ用 A Alias レコード
# (Route 53 では ALB に対して Aliasレコードを使用する)
resource "aws_route53_record" "app" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = "app.saxon-aws-lab.click"
  type    = "A"

  alias {
    name                   = aws_lb.main.dns_name
    zone_id                = aws_lb.main.zone_id
    evaluate_target_health = true
  }
}
