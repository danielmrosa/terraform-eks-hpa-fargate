query:
  ingress:
    enabled: true
    path: /*
    hosts:
      - ${jaeger-address}
    annotations:
     kubernetes.io/ingress.class: alb
     alb.ingress.kubernetes.io/scheme: internet-facing
     alb.ingress.kubernetes.io/subnets: ${subnets}
     alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn-jaeger}
     external-dns.alpha.kubernetes.io/hostname: ${jaeger-address}

replicas: 1

resources:
  requests:
    cpu: "1000m"
    memory: "1Gi"
  limits:
    cpu: "1000m"
    memory: "1Gi"