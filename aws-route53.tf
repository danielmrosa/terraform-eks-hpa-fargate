resource "aws_route53_zone" "dns-demo" {
  name = var.domain-name
}

resource "aws_route53_record" "kibana-record-CNAME" {
  name    = lookup(aws_acm_certificate.kibana.domain_validation_options[0], "resource_record_name")
  type    = lookup(aws_acm_certificate.kibana.domain_validation_options[0], "resource_record_type")
  ttl     = "300"
  zone_id = aws_route53_zone.dns-demo.zone_id
  records = [
    lookup(aws_acm_certificate.kibana.domain_validation_options[0], "resource_record_value")
  ]
}


resource "aws_route53_record" "jaeger-CNAME" {
  name    = lookup(aws_acm_certificate.jaeger.domain_validation_options[0], "resource_record_name")
  type    = lookup(aws_acm_certificate.jaeger.domain_validation_options[0], "resource_record_type")
  ttl     = "300"
  zone_id = aws_route53_zone.dns-demo.zone_id
  records = [
    lookup(aws_acm_certificate.jaeger.domain_validation_options[0], "resource_record_value")
  ]
}

resource "aws_route53_record" "grafana-CNAME" {
  name    = lookup(aws_acm_certificate.grafana.domain_validation_options[0], "resource_record_name")
  type    = lookup(aws_acm_certificate.grafana.domain_validation_options[0], "resource_record_type")
  ttl     = "300"
  zone_id = aws_route53_zone.dns-demo.zone_id
  records = [
    lookup(aws_acm_certificate.grafana.domain_validation_options[0], "resource_record_value")
  ]
}

resource "aws_route53_record" "kiali-CNAME" {
  name    = lookup(aws_acm_certificate.kiali.domain_validation_options[0], "resource_record_name")
  type    = lookup(aws_acm_certificate.kiali.domain_validation_options[0], "resource_record_type")
  ttl     = "300"
  zone_id = aws_route53_zone.dns-demo.zone_id
  records = [
    lookup(aws_acm_certificate.kiali.domain_validation_options[0], "resource_record_value")
  ]
}