ingress:
  enabled: true
  path: /*
  hosts:
    - ${grafana-address}
  annotations: 
     kubernetes.io/ingress.class: alb
     alb.ingress.kubernetes.io/scheme: internet-facing
     alb.ingress.kubernetes.io/subnets: ${subnets}
     alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn-grafana}
     external-dns.alpha.kubernetes.io/hostname: ${grafana-address}

resources:
   limits:
    cpu: 1
    memory: 1536Mi
   requests:
    cpu: 128m
    memory: 256Mi