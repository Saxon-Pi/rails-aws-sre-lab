resource "aws_acm_certificate" "app" {
  domain_name       = "app.saxon-aws-lab.click"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }

  tags = {
    Name = "rails-aws-sre-lab"
  }
}

resource "aws_route53_record" "acm_validation" {
  # ACM が返してきた DNS 検証情報を 1件ずつ取り出して、Route 53レコード作成用のデータに変換する
  for_each = {
    for dvo in aws_acm_certificate.app.domain_validation_options :
    dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
  
  # Route 53 に実際の CNAME を作る
  # → 検証用 CNAME を Route 53に登録できると、
  #   「DNS を制御できる ＝ ドメイン管理権限を持っている」と判断され、
  #   ACM 証明書を発行してもらえる
  zone_id = data.aws_route53_zone.main.zone_id
  name    = each.value.name
  type    = each.value.type
  ttl     = 300
  records = [each.value.record]
}

# ACM の検証完了を待つための Terraformリソース
# → aws_route53_record.acm_validation で作った CNAME の FQDN を全部集めて、
#   「この DNS検証レコードを使って、証明書の検証が完了する」まで待機する
resource "aws_acm_certificate_validation" "app" {
  certificate_arn = aws_acm_certificate.app.arn

  validation_record_fqdns = [
    for record in aws_route53_record.acm_validation :
    record.fqdn
  ]
}
