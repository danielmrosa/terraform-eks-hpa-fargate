ingress:
  enabled: true
  hosts:
    - ${kiali-address}
  annotations: 
     kubernetes.io/ingress.class: alb
     alb.ingress.kubernetes.io/scheme: internet-facing
     alb.ingress.kubernetes.io/subnets: ${subnets}
     alb.ingress.kubernetes.io/certificate-arn: ${certificate-arn-kiali}
     external-dns.alpha.kubernetes.io/hostname: ${kiali-address}

  path: /*
service:
  name: kiali
  type: NodePort
  ports:
  - name: http
    port: 20001
    target_port: 20001

contextPath: /kiali

replicaCount: 1