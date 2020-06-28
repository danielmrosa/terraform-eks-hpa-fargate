replicaCount: 1

image:
  repository: danielqsj/kafka-exporter
  tag: latest
  pullPolicy: Always

service:
  name: kafka-exporter
  type: ClusterIP
  ports:
  - name: http
    port: 9308

configmaps:
  enabled: false
  files: {}

startcommand: 
  enabled: true
  value: 
    - "/bin/sh"
    - "-c"
    - "/bin/kafka_exporter --kafka.server=kafka-cp-kafka:9092"

ingress:
  enabled: false

resources:
   limits:
    cpu: 1
    memory: 256Mi
   requests:
    cpu: 128m
    memory: 256Mi

nodeSelector: {}

tolerations: []

affinity: {}

livenessProbe:
  enabled: true
  failureThreshold: 3
  httpGet:
    path: /
    port: 9308
    scheme: HTTP
  initialDelaySeconds: 10
  periodSeconds: 30
  successThreshold: 1
  timeoutSeconds: 1
readinessProbe:
  failureThreshold: 3
  httpGet:
    path: /
    port: 9308
    scheme: HTTP
  initialDelaySeconds: 10
  periodSeconds: 10
  successThreshold: 1
  timeoutSeconds: 1
istio:
  enabled: false

imageCredentials:
  registry: "docker.io"
