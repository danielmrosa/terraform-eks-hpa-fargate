resource "helm_release" "metrics-server" {
  name       = "metrics-server"
  repository = "stable"
  chart      = "stable/metrics-server"
  version    = "2.10.1"
  namespace  = "kube-system"

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}

resource "helm_release" "cluster-autoscaler" {
  name       = "cluster-autoscaler"
  repository = "stable"
  chart      = "stable/cluster-autoscaler"
  version    = "7.2.0"
  namespace  = "cluster-autoscaler"

  set {
    name  = "autoDiscovery.clusterName"
    value = var.cluster-name
  }

  set {
    name  = "cloud-provider"
    value = "aws"
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "rbac.create"
    value = true
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}

resource "helm_release" "external-dns" {
  name       = "external-dns"
  repository = "stable"
  chart      = "stable/external-dns"
  version    = "2.9.4"
  namespace  = "external-dns"

  set {
    name  = "provider"
    value = "aws"
  }

  set {
    name  = "aws.zoneType"
    value = "public"
  }

  set {
    name  = "txtOwnerId"
    value = aws_route53_zone.dns-demo.zone_id
  }

  set {
    name  = "rbac.create"
    value = true
  }

  set {
    name  = "policy"
    value = "sync"
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.aws-alb-ingress-controller
  ]
}


resource "helm_release" "aws-alb-ingress-controller" {
  name       = "aws-alb-ingress-controller"
  repository = "incubator"
  chart      = "incubator/aws-alb-ingress-controller"
  version    = "0.1.11"
  namespace  = "aws-alb-ingress-controller"

  set {
    name  = "clusterName"
    value = var.cluster-name
  }

  set {
    name  = "awsRegion"
    value = var.region
  }

  set {
    name  = "awsVpcID"
    value = aws_vpc.vpc.id
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}


# resource "helm_release" "consul" {
#   name       = "consul"
#   repository = "stable"
#   chart      = "stable/consul"
#   version    = "3.9.2"
#   namespace  = "qa"

#   set {
#     name  = "uiService.enabled"
#     value = "true"
#   }

#   depends_on = [
#     kubernetes_cluster_role_binding.tiller,
#     kubernetes_service_account.tiller,
#   ]
# }

resource "helm_release" "istio-init" {
  name       = "istio-init"
  repository = "istio.io"
  chart      = "istio-init"
  version    = "1.5.1"
  namespace  = "istio-system"

  provisioner "local-exec" {
    command = "sleep 30"
  }
  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller
  ]
}


resource "helm_release" "istio" {
  name       = "istio"
  repository = "istio.io"
  chart      = "istio"
  version    = "1.5.1"
  namespace  = "istio-system"
  timeout = "600"

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
    helm_release.istio-init,
  ]
  set {
    name  = "gateways.enabled"
    value = "true"
  }

  set {
    name  = "gateways.istio-ingressgateway.enabled"
    value = "true"
  }
  
  set {
    name  = "gateways.istio-ilbgateway.enabled"
    value = "true"

  }
  set {
    name  = "gateways.istio-ingressgateway.type"
    value = "NodePort"
  }

  set {
    name  = "grafana.enabled"
    value = "false"
  }

  set {
    name  = "kiali.enabled"
    value = "false"
  }

  set {
    name  = "tracing.enabled"
    value = "false"
  }

// Disable below in production
  set {
    name  = "kiali.createDemoSecret"
    value = "true"
  }
}

# resource "helm_release" "kafka" {
#   name       = "kafka"
#   repository = "confluentinc"
#   chart      = "confluentinc/cp-helm-charts"
#   version    = "0.1.0"
#   namespace  = "qa"
#   timeout = "600"
  
#   set {
#     name  = "cp-schema-registry.enabled"
#     value = "false"
#   }
#   set {
#     name  = "cp-kafka-rest.enabled"
#     value = "false"
#   }
#   set {
#     name  = "cp-kafka-connect.enabled"
#     value = "false"
#   }
#   set {
#     name  = "cp-ksql-server.enabled"
#     value = "false"
#   }
#   set {
#     name  = "cp-control-center.enabled"
#     value = "false"
#   }
#   depends_on = [
#     kubernetes_cluster_role_binding.tiller,
#     kubernetes_service_account.tiller,
#   ]
# }

resource "helm_release" "postgres" {
  name       = "postgres"
  repository = "stable"
  chart      = "stable/postgresql"
  version    = "8.1.2"
  namespace  = "qa"
  timeout = "600"

  set {
    name  = "postgresqlPassword"
    value = "postgres"
  }

  depends_on = [
    kubernetes_cluster_role_binding.tiller,
    kubernetes_service_account.tiller,
  ]

}