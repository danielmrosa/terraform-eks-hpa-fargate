priorityClassName: "system-node-critical"

elasticsearch:
  auth:
    enabled: ${es-auth-enabled}
    user: "${es-user}"
    password: "${es-passwd}"
  host: ${efk-es-host}
  port: ${efk-es-port}
  scheme: ${efk-es-scheme}

resources:
  limits:
    cpu: 100m
    memory: 256Mi

configMaps:
  logsPath: '/var/log/containers/*_observability_*.log, /var/log/containers/*_microservices_*.log'
  excludePath: '["/var/log/containers/*_istio-*.log"]'
  removeKeys: '$.docker.container_id, $.kubernetes.labels, $.kubernetes.labels.app, $.kubernetes.labels.pod-template-hash, $.kubernetes.pod_id, $.kubernetes.master_url, $.kubernetes.namespace_labels.fluxcd_io/sync-gc-mark, $.kubernetes.namespace_labels.name, $.kubernetes.namespace_labels.istio-injection, $.kubernetes.namespace_id, $.kubernetes.container_image_id'
  extraNamespaceFilter: 
    - observability