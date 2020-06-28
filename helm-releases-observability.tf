resource "helm_release" "prometheus-operator" {
  name       = "prometheus-operator"
  repository = "stable"
  chart      = "stable/prometheus-operator"
  version    = "8.12.3"
  namespace  = "observability"
  timeout = "600"
  values = [data.template_file.prometheus-operator-extravars.rendered]
  depends_on = [
    helm_release.kube-metrics-adapter
  ]
}

resource "helm_release" "kube-metrics-adapter" {
  name       = "kube-metrics-adapter"
  repository = "banzaicloud"
  chart      = "banzaicloud/kube-metrics-adapter"
  version    = "0.1.3"
  namespace  = "kube-system"
  timeout = "600"

  set {
    name = "prometheus.url"
    value = "http://prometheus-operator-prometheus.observability.svc:9090"
  }
  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
  ]
}

resource "helm_release" "hpa-operator" {
  name       = "hpa-operator"
  repository = "banzaicloud"
  chart      = "banzaicloud-stable/hpa-operator"
  version    = "0.2.2"
  namespace  = "kube-system"
  timeout = "600"
  set {
    name = "kube-metrics-adapter.enabled"
    value = "false"
    }
  depends_on = [
    helm_release.kube-metrics-adapter
  ]
}

resource "helm_release" "fluentd" {
  name      = "efk"
  chart     = "${path.module}/charts/fluentd-elasticsearch"
  namespace = "kube-system"
  values = [data.template_file.fluentd-extravars.rendered]

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.elasticsearch
  ]
}

resource "helm_release" "kibana" {
  name       = "kibana"
  repository = "elastic"
  chart      = "elastic/kibana"
  version    = "7.6.1"
  namespace  = "observability"
  timeout = "600"
  values = [data.template_file.kibana-extravars.rendered]

  set {
    name  = "elasticsearchHosts"
    value = "http://elasticsearch-master.observability.svc:9200"
  }
  set {
    name = "imageTag"
    value = "7.6.1"
  }
  set {
    name = "service.type"
    value = "NodePort"
  }
  set {
    name = "healthCheckPath"
    value = "/app/kibana"
  }
  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.elasticsearch
  ]
}

resource "helm_release" "jaeger-tracing" {
  name       = "jaeger-tracing"
  repository = "jaegertracing"
  chart      = "jaegertracing/jaeger"
  version    = "0.18.2"
  namespace  = "observability"
  timeout = "600"
  values = [data.template_file.jaeger-extravars.rendered]
  
  set {
    name  = "agent.enabled"
    value = "true"
  }

  set {
    name  = "collector.enabled"
    value = "true"
  }

  set {
    name  = "query.enabled"
    value = "true"
  }
  set {
    name = "query.service.type"
    value = "NodePort"
  }

  set {
    name = "query.service.port"
    value = "80"
  }

  set {
    name  = "provisionDataStore.cassandra"
    value = "false"
  }

  set {
    name  = "storage.type"
    value = "elasticsearch"
  }

  set {
    name  = "storage.elasticsearch.host"
    value = "elasticsearch-master.observability.svc"
  }

  set {
    name  = "storage.elasticsearch.scheme"
    value = "http"
  }

  set {
    name  = "storage.elasticsearch.port"
    value = "9200"
  }

  set {
    name  = "storage.elasticsearch.usePassword"
    value = "false"
  }

  set {
    name  = "storage.elasticsearch.user"
    value = ""
  }
  
  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.elasticsearch
  ]
}

resource "helm_release" "grafana" {
  name       = "grafana"
  repository = "stable"
  chart      = "stable/grafana"
  version    = "4.3.0"
  namespace  = "observability"
  timeout = "600"
  values = [data.template_file.grafana-extravars.rendered]

  set {
    name  = "persistence.type"
    value = "pvc"
  }
  set {
    name  = "persistence.enabled"
    value = "true"
  }
  set {
    name  = "persistence.size"
    value = "15Gi"
  }
  set {
    name = "service.type"
    value = "NodePort"
  }
  set {
    name = "service.port"
    value = "3000"
  }
}

resource "helm_release" "elasticsearch" {
  name       = "elasticsearch"
  repository = "elastic"
  chart      = "elastic/elasticsearch"
  version    = "7.6.1"
  namespace  = "observability"
  timeout = "600"

  set {
    name = "client.replicas"
    value = "1"
  }
  set {
    name = "data.replicas"
    value = "1"
  }
  set {
    name = "replicas"
    value = "2"
  }
  set {
    name  = "client.serviceType"
    value = "ClusterIP"
  }
  set {
    name  = "client.ingress.enabled"
    value = "false"
  }
  set {
    name  = "master.persistence.enabled"
    value = "false"
  }
  set {
    name  = "data.persistence.enabled"
    value = "false"
  }
  set {
    name = "imageTag"
    value = "7.6.1"
  }
  set {
    name = "resources.requests.cpu"
    value = "100m"
  }
  set {
    name = "resources.requests.memory"
    value = "256Mi"
  }
  set {
    name = "esJavaOpts"
    value = "-Xmx512m -Xms512m"
  }
  set {
    name = "persistence.enabled"
    value = "false"
  }
  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
  ]
}

resource "helm_release" "kiali" {
  name       = "kiali"
  chart      = "${path.module}/charts/kiali"
  namespace  = "istio-system"
  timeout = "600"
  values = [data.template_file.kiali-extravars.rendered]

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.external-dns,
  ]
  
  force_update = true

  recreate_pods = true

}

resource "helm_release" "kafka-exporter" {
  name       = "kafka-exporter"
  chart      = "${path.module}/charts/kafka-exporter"
  namespace  = "qa"
  timeout = "600"
  values = [data.template_file.kafka-exporter-extravars.rendered]

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
  ]
  
  force_update = true

  recreate_pods = true

}