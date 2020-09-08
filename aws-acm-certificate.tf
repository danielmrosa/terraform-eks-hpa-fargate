resource "aws_acm_certificate" "jaeger" {
  domain_name       = "jaeger.${aws_route53_zone.dns-demo.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "grafana" {
  domain_name       = "grafana.${aws_route53_zone.dns-demo.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "kibana" {
  domain_name       = "kibana.${aws_route53_zone.dns-demo.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "kiali" {
  domain_name       = "kiali.${aws_route53_zone.dns-demo.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_acm_certificate" "demo" {
  domain_name       = "demo.${aws_route53_zone.dns-demo.name}"
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}