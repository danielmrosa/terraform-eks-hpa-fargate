ingress:
  enabled: true
  path: /*
  hosts:
    - ${kibana-address}
  annotations: 
     kubernetes.io/ingress.class: alb
     alb.ingress.kubernetes.io/scheme: internet-facing
     alb.ingress.kubernetes.io/subnets: ${subnets}
     alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn-kibana}
     external-dns.alpha.kubernetes.io/hostname: ${kibana-address}

replicas: 1

resources:
  requests:
    cpu: "1000m"
    memory: "2Gi"
  limits:
    cpu: "1000m"
    memory: "2Gi"

service:
  name: kibana
  type: NodePort
  ports:
  - name: http
    port: 5601
    target_port: 5601