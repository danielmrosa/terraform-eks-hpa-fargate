data "template_file" "kibana-extravars" {
  template = file("${path.module}/templates/kibana-extravars.tpl")
  vars = {
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    certificate-arn-kibana = aws_acm_certificate.kibana.arn
    kibana-address = "kibana.${var.domain-name}"
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    hostname        = var.domain-name
  }

  depends_on = [
    aws_acm_certificate.kibana
  ]
}

data "template_file" "fluentd-extravars" {
  template = file("${path.module}/templates/fluentd-extravars.tpl")
  vars = {
    efk-es-host       = "elasticsearch-master.observability.svc"
    efk-es-port       = "9200"
    efk-es-scheme     = "http"
    es-user           = "user"
    es-passwd         = "passwd"
    es-auth-enabled   = false
  }
}

data "template_file" "prometheus-operator-extravars" {
  template = file("${path.module}/templates/prometheus-operator-extravars.tpl")
}

data "template_file" "jaeger-extravars" {
  template = file("${path.module}/templates/jaeger-extravars.tpl")
  vars = {
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    certificate-arn-jaeger = aws_acm_certificate.jaeger.arn
    jaeger-address = "jaeger.${var.domain-name}"
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    hostname        = var.domain-name

  }
}

data "template_file" "kiali-extravars" {
  template = file("${path.module}/templates/kiali-extravars.tpl")
  vars = {
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    certificate-arn-kiali = aws_acm_certificate.kiali.arn
    kiali-address = "kiali.${var.domain-name}"
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    hostname        = var.domain-name

  }
}

data "template_file" "grafana-extravars" {
  template = file("${path.module}/templates/grafana-extravars.tpl")
  vars = {
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    certificate-arn-grafana = aws_acm_certificate.grafana.arn
    grafana-address = "grafana.${var.domain-name}"
    subnets         = join(", ", data.aws_subnet_ids.subnet-ids-public.ids)
    hostname        = var.domain-name
  }
}


# data "template_file" "kafka-exporter-extravars" {
#   template = file("${path.module}/templates/kafka-exporter-extravars.tpl")
# }
