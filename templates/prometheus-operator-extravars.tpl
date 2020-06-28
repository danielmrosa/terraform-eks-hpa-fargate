defaultRules:
  create: false
kubeApiServer:
  enabled: false
kubelet:
  enabled: false
kubeControllerManager:
  enabled: false
coreDns:
  enabled: false
kubeEtcd:
  enabled: false
kubeScheduler:
  enabled: false
kubeStateMetrics:
  enabled: true
nodeExporter:
  enabled: true
prometheus:
  enabled: true
  prometheusSpec:
    resources:
      limits:
        cpu: 1000m
        memory: 2000Mi
      requests:
        cpu: 100m
        memory: 2000Mi
    additionalScrapeConfigs:
      - job_name: 'kafka-exporter'
        dns_sd_configs:
        - names:
          - 'kafka-exporter.qa.svc.cluster.local'
          type: 'A'
          port: 9308
      - job_name: 'kubernetes-service-endpoints-zup'

        kubernetes_sd_configs:
          - role: endpoints

        relabel_configs:
          # Example relabel to scrape only endpoints that have
          # "prometheus.io/scrape: true" annotation.
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
            action: keep
            regex: true

          # Example relabel to customize metric path based on endpoints
          # "prometheus.io/path = <metric path>" annotation.
          - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
            action: replace
            target_label: __metrics_path__
            regex: (.+)

          # Example relabel to scrape only single, desired port for the service based
          # on endpoints "prometheus.io/port = <port>" annotation.
          - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
            action: replace
            regex: ([^:]+)(?::\d+)?;(\d+)
            replacement: $1:$2
            target_label: __address__

          - action: labelmap
            regex: __meta_kubernetes_service_label_(.+)
          - source_labels: [__meta_kubernetes_namespace]
            action: replace
            target_label: kubernetes_namespace
          - source_labels: [__meta_kubernetes_service_name]
            action: replace
            target_label: kubernetes_name
  
prometheusOperator:
  manageCrds: true
  admissionWebhooks:
    enabled: false
  tlsProxy:
    enabled: false
  patch:
    enabled: false
grafana:
  enabled: false
  persistence:
    enabled: false
    size: 10Gi
    type: pvc
alertmanager:
  enabled: false
  apiVersion: v2
  service:
    type: ClusterIP
  config:
    global:
      slack_api_url: https://hooks.slack.com/services/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
      resolve_timeout: 5m
    route:
      group_by: ['job']
      group_wait: 30s
      group_interval: 30s
      repeat_interval: 12h
      receiver: 'slack'
      routes:
      - match:
          severity: high
        receiver: 'slack'
      - match:
          severity: critical
        receiver: 'slack'
    receivers:
    - name: slack
      slack_configs:
      - api_url: https://hooks.slack.com/services/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
        send_resolved: true
        channel: '#notifications1'
        title: |-
          [{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .CommonLabels.alertname }} for {{ .CommonLabels.job }}
          {{- if gt (len .CommonLabels) (len .GroupLabels) -}}
            {{" "}}(
            {{- with .CommonLabels.Remove .GroupLabels.Names }}
              {{- range $index, $label := .SortedPairs -}}
                {{ if $index }}, {{ end }}
                {{- $label.Name }}="{{ $label.Value -}}"
              {{- end }}
            {{- end -}}
            )
          {{- end }}
        text: >-
          {{ with index .Alerts 0 -}}
            :chart_with_upwards_trend: *<{{ .GeneratorURL }}|Graph>*
            {{- if .Annotations.runbook_url }}   :notebook: *<{{ .Annotations.runbook_url }}|Runbook>*{{ end }}
          {{ end }}
          *Alert details*:
          {{ range .Alerts -}}
            *Alert:* {{ .Annotations.title }}{{ if .Labels.severity }} - `{{ .Labels.severity }}`{{ end }}
          *Description:* {{ .Annotations.description }}
          *Details:*
            {{ range .Labels.SortedPairs }} • *{{ .Name }}:* `{{ .Value }}`
            {{ end }}
          {{ end }}
    - name: 'sns-forwarder'
      webhook_configs:
      - send_resolved: false
        url: http://alertmanager-sns-forwarder/alert/notify
    route:
      group_by:
      - job
      group_interval: 30s
      group_wait: 30s
      receiver: sns-forwarder
      repeat_interval: 12h
      routes:
      - match:
          severity: high
        receiver: sns-forwarder
      - match:
          severity: critical
        receiver: sns-forwarder

additionalPrometheusRulesMap: 
  - name: prometheus-k8s-rules
    groups:
    - name: node-exporter.rules
      rules:
      - expr: |
          count without (cpu) (
            count without (mode) (
              node_cpu_seconds_total{job="node-exporter"}
            )
          )
        record: instance:node_num_cpu:sum
      - expr: |
          1 - avg without (cpu, mode) (
            rate(node_cpu_seconds_total{job="node-exporter", mode="idle"}[1m])
          )
        record: instance:node_cpu_utilisation:rate1m
      - expr: |
          (
            node_load1{job="node-exporter"}
          /
            instance:node_num_cpu:sum{job="node-exporter"}
          )
        record: instance:node_load1_per_cpu:ratio
      - expr: |
          1 - (
            node_memory_MemAvailable_bytes{job="node-exporter"}
          /
            node_memory_MemTotal_bytes{job="node-exporter"}
          )
        record: instance:node_memory_utilisation:ratio
      - expr: |
          rate(node_vmstat_pgmajfault{job="node-exporter"}[1m])
        record: instance:node_vmstat_pgmajfault:rate1m
      - expr: |
          rate(node_disk_io_time_seconds_total{job="node-exporter", device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+"}[1m])
        record: instance_device:node_disk_io_time_seconds:rate1m
      - expr: |
          rate(node_disk_io_time_weighted_seconds_total{job="node-exporter", device=~"nvme.+|rbd.+|sd.+|vd.+|xvd.+|dm-.+|dasd.+"}[1m])
        record: instance_device:node_disk_io_time_weighted_seconds:rate1m
      - expr: |
          sum without (device) (
            rate(node_network_receive_bytes_total{job="node-exporter", device!="lo"}[1m])
          )
        record: instance:node_network_receive_bytes_excluding_lo:rate1m
      - expr: |
          sum without (device) (
            rate(node_network_transmit_bytes_total{job="node-exporter", device!="lo"}[1m])
          )
        record: instance:node_network_transmit_bytes_excluding_lo:rate1m
      - expr: |
          sum without (device) (
            rate(node_network_receive_drop_total{job="node-exporter", device!="lo"}[1m])
          )
        record: instance:node_network_receive_drop_excluding_lo:rate1m
      - expr: |
          sum without (device) (
            rate(node_network_transmit_drop_total{job="node-exporter", device!="lo"}[1m])
          )
        record: instance:node_network_transmit_drop_excluding_lo:rate1m
    - name: kube-apiserver.rules
      rules:
      - expr: |
          sum(rate(apiserver_request_duration_seconds_sum{subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) without(instance, pod)
          /
          sum(rate(apiserver_request_duration_seconds_count{subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) without(instance, pod)
        record: cluster:apiserver_request_duration_seconds:mean5m
      - expr: |
          histogram_quantile(0.99, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) without(instance, pod))
        labels:
          quantile: "0.99"
        record: cluster_quantile:apiserver_request_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.9, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) without(instance, pod))
        labels:
          quantile: "0.9"
        record: cluster_quantile:apiserver_request_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.5, sum(rate(apiserver_request_duration_seconds_bucket{job="apiserver",subresource!="log",verb!~"LIST|WATCH|WATCHLIST|PROXY|CONNECT"}[5m])) without(instance, pod))
        labels:
          quantile: "0.5"
        record: cluster_quantile:apiserver_request_duration_seconds:histogram_quantile
    - name: k8s.rules
      rules:
      - expr: |
          sum(rate(container_cpu_usage_seconds_total{job="kubelet", metrics_path="/metrics/cadvisor", image!="", container!="POD"}[5m])) by (namespace)
        record: namespace:container_cpu_usage_seconds_total:sum_rate
      - expr: |
          sum by (cluster, namespace, pod, container) (
            rate(container_cpu_usage_seconds_total{job="kubelet", metrics_path="/metrics/cadvisor", image!="", container!="POD"}[5m])
          ) * on (cluster, namespace, pod) group_left(node) max by(cluster, namespace, pod, node) (kube_pod_info)
        record: node_namespace_pod_container:container_cpu_usage_seconds_total:sum_rate
      - expr: |
          container_memory_working_set_bytes{job="kubelet", metrics_path="/metrics/cadvisor", image!=""}
          * on (namespace, pod) group_left(node) max by(namespace, pod, node) (kube_pod_info)
        record: node_namespace_pod_container:container_memory_working_set_bytes
      - expr: |
          container_memory_rss{job="kubelet", metrics_path="/metrics/cadvisor", image!=""}
          * on (namespace, pod) group_left(node) max by(namespace, pod, node) (kube_pod_info)
        record: node_namespace_pod_container:container_memory_rss
      - expr: |
          container_memory_cache{job="kubelet", metrics_path="/metrics/cadvisor", image!=""}
          * on (namespace, pod) group_left(node) max by(namespace, pod, node) (kube_pod_info)
        record: node_namespace_pod_container:container_memory_cache
      - expr: |
          container_memory_swap{job="kubelet", metrics_path="/metrics/cadvisor", image!=""}
          * on (namespace, pod) group_left(node) max by(namespace, pod, node) (kube_pod_info)
        record: node_namespace_pod_container:container_memory_swap
      - expr: |
          sum(container_memory_usage_bytes{job="kubelet", metrics_path="/metrics/cadvisor", image!="", container!="POD"}) by (namespace)
        record: namespace:container_memory_usage_bytes:sum
      - expr: |
          sum by (namespace) (
              sum by (namespace, pod) (
                  max by (namespace, pod, container) (
                      kube_pod_container_resource_requests_memory_bytes{job="kube-state-metrics"}
                  ) * on(namespace, pod) group_left() max by (namespace, pod) (
                      kube_pod_status_phase{phase=~"Pending|Running"} == 1
                  )
              )
          )
        record: namespace:kube_pod_container_resource_requests_memory_bytes:sum
      - expr: |
          sum by (namespace) (
              sum by (namespace, pod) (
                  max by (namespace, pod, container) (
                      kube_pod_container_resource_requests_cpu_cores{job="kube-state-metrics"}
                  ) * on(namespace, pod) group_left() max by (namespace, pod) (
                    kube_pod_status_phase{phase=~"Pending|Running"} == 1
                  )
              )
          )
        record: namespace:kube_pod_container_resource_requests_cpu_cores:sum
      - expr: |
          sum(
            label_replace(
              label_replace(
                kube_pod_owner{job="kube-state-metrics", owner_kind="ReplicaSet"},
                "replicaset", "$1", "owner_name", "(.*)"
              ) * on(replicaset, namespace) group_left(owner_name) kube_replicaset_owner{job="kube-state-metrics"},
              "workload", "$1", "owner_name", "(.*)"
            )
          ) by (cluster, namespace, workload, pod)
        labels:
          workload_type: deployment
        record: mixin_pod_workload
      - expr: |
          sum(
            label_replace(
              kube_pod_owner{job="kube-state-metrics", owner_kind="DaemonSet"},
              "workload", "$1", "owner_name", "(.*)"
            )
          ) by (cluster, namespace, workload, pod)
        labels:
          workload_type: daemonset
        record: mixin_pod_workload
      - expr: |
          sum(
            label_replace(
              kube_pod_owner{job="kube-state-metrics", owner_kind="StatefulSet"},
              "workload", "$1", "owner_name", "(.*)"
            )
          ) by (cluster, namespace, workload, pod)
        labels:
          workload_type: statefulset
        record: mixin_pod_workload
    - name: kube-scheduler.rules
      rules:
      - expr: |
          histogram_quantile(0.99, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.99"
        record: cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.99, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.99"
        record: cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.99, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.99"
        record: cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.9, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.9"
        record: cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.9, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.9"
        record: cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.9, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.9"
        record: cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.5, sum(rate(scheduler_e2e_scheduling_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.5"
        record: cluster_quantile:scheduler_e2e_scheduling_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.5, sum(rate(scheduler_scheduling_algorithm_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.5"
        record: cluster_quantile:scheduler_scheduling_algorithm_duration_seconds:histogram_quantile
      - expr: |
          histogram_quantile(0.5, sum(rate(scheduler_binding_duration_seconds_bucket{job="kube-scheduler"}[5m])) without(instance, pod))
        labels:
          quantile: "0.5"
        record: cluster_quantile:scheduler_binding_duration_seconds:histogram_quantile
    - name: node.rules
      rules:
      - expr: |
          sum(min(kube_pod_info) by (cluster, node))
        record: ':kube_pod_info_node_count:'
      - expr: |
          max(label_replace(kube_pod_info{job="kube-state-metrics"}, "pod", "$1", "pod", "(.*)")) by (node, namespace, pod)
        record: 'node_namespace_pod:kube_pod_info:'
      - expr: |
          count by (cluster, node) (sum by (node, cpu) (
            node_cpu_seconds_total{job="node-exporter"}
          * on (namespace, pod) group_left(node)
            node_namespace_pod:kube_pod_info:
          ))
        record: node:node_num_cpu:sum
      - expr: |
          sum(
            node_memory_MemAvailable_bytes{job="node-exporter"} or
            (
              node_memory_Buffers_bytes{job="node-exporter"} +
              node_memory_Cached_bytes{job="node-exporter"} +
              node_memory_MemFree_bytes{job="node-exporter"} +
              node_memory_Slab_bytes{job="node-exporter"}
            )
          ) by (cluster)
        record: :node_memory_MemAvailable_bytes:sum
    - name: kube-prometheus-node-recording.rules
      rules:
      - expr: sum(rate(node_cpu_seconds_total{mode!="idle",mode!="iowait"}[3m])) BY
          (instance)
        record: instance:node_cpu:rate:sum
      - expr: sum((node_filesystem_size_bytes{mountpoint="/"} - node_filesystem_free_bytes{mountpoint="/"}))
          BY (instance)
        record: instance:node_filesystem_usage:sum
      - expr: sum(rate(node_network_receive_bytes_total[3m])) BY (instance)
        record: instance:node_network_receive_bytes:rate:sum
      - expr: sum(rate(node_network_transmit_bytes_total[3m])) BY (instance)
        record: instance:node_network_transmit_bytes:rate:sum
      - expr: sum(rate(node_cpu_seconds_total{mode!="idle",mode!="iowait"}[5m])) WITHOUT
          (cpu, mode) / ON(instance) GROUP_LEFT() count(sum(node_cpu_seconds_total)
          BY (instance, cpu)) BY (instance)
        record: instance:node_cpu:ratio
      - expr: sum(rate(node_cpu_seconds_total{mode!="idle",mode!="iowait"}[5m]))
        record: cluster:node_cpu:sum_rate5m
      - expr: cluster:node_cpu_seconds_total:rate5m / count(sum(node_cpu_seconds_total)
          BY (instance, cpu))
        record: cluster:node_cpu:ratio
    - name: kube-prometheus-general.rules
      rules:
      - expr: count without(instance, pod, node) (up == 1)
        record: count:up1
      - expr: count without(instance, pod, node) (up == 0)
        record: count:up0
    - name: kube-state-metrics
      rules:
      - alert: KubeStateMetricsListErrors
        annotations:
          message: kube-state-metrics is experiencing errors at an elevated rate in
            list operations. This is likely causing it to not be able to expose metrics
            about Kubernetes objects correctly or at all.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatemetricslisterrors
        expr: |
          (sum(rate(kube_state_metrics_list_total{job="kube-state-metrics",result="error"}[5m]))
            /
          sum(rate(kube_state_metrics_list_total{job="kube-state-metrics"}[5m])))
          > 0.01
        for: 15m
        labels:
          severity: critical
      - alert: KubeStateMetricsWatchErrors
        annotations:
          message: kube-state-metrics is experiencing errors at an elevated rate in
            watch operations. This is likely causing it to not be able to expose metrics
            about Kubernetes objects correctly or at all.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatemetricswatcherrors
        expr: |
          (sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics",result="error"}[5m]))
            /
          sum(rate(kube_state_metrics_watch_total{job="kube-state-metrics"}[5m])))
          > 0.01
        for: 15m
        labels:
          severity: critical
    - name: node-exporter
      rules:
      - alert: NodeFilesystemSpaceFillingUp
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available space left and is filling
            up.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemspacefillingup
          summary: Filesystem is predicted to run out of space within the next 24 hours.
        expr: |
          (
            node_filesystem_avail_bytes{job="node-exporter",fstype!=""} / node_filesystem_size_bytes{job="node-exporter",fstype!=""} * 100 < 40
          and
            predict_linear(node_filesystem_avail_bytes{job="node-exporter",fstype!=""}[6h], 24*60*60) < 0
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: warning
      - alert: NodeFilesystemSpaceFillingUp
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available space left and is filling
            up fast.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemspacefillingup
          summary: Filesystem is predicted to run out of space within the next 4 hours.
        expr: |
          (
            node_filesystem_avail_bytes{job="node-exporter",fstype!=""} / node_filesystem_size_bytes{job="node-exporter",fstype!=""} * 100 < 20
          and
            predict_linear(node_filesystem_avail_bytes{job="node-exporter",fstype!=""}[6h], 4*60*60) < 0
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: critical
      - alert: NodeFilesystemAlmostOutOfSpace
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available space left.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemalmostoutofspace
          summary: Filesystem has less than 5% space left.
        expr: |
          (
            node_filesystem_avail_bytes{job="node-exporter",fstype!=""} / node_filesystem_size_bytes{job="node-exporter",fstype!=""} * 100 < 5
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: warning
      - alert: NodeFilesystemAlmostOutOfSpace
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available space left.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemalmostoutofspace
          summary: Filesystem has less than 3% space left.
        expr: |
          (
            node_filesystem_avail_bytes{job="node-exporter",fstype!=""} / node_filesystem_size_bytes{job="node-exporter",fstype!=""} * 100 < 3
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: critical
      - alert: NodeFilesystemFilesFillingUp
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available inodes left and is filling
            up.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemfilesfillingup
          summary: Filesystem is predicted to run out of inodes within the next 24 hours.
        expr: |
          (
            node_filesystem_files_free{job="node-exporter",fstype!=""} / node_filesystem_files{job="node-exporter",fstype!=""} * 100 < 40
          and
            predict_linear(node_filesystem_files_free{job="node-exporter",fstype!=""}[6h], 24*60*60) < 0
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: warning
      - alert: NodeFilesystemFilesFillingUp
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available inodes left and is filling
            up fast.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemfilesfillingup
          summary: Filesystem is predicted to run out of inodes within the next 4 hours.
        expr: |
          (
            node_filesystem_files_free{job="node-exporter",fstype!=""} / node_filesystem_files{job="node-exporter",fstype!=""} * 100 < 20
          and
            predict_linear(node_filesystem_files_free{job="node-exporter",fstype!=""}[6h], 4*60*60) < 0
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: critical
      - alert: NodeFilesystemAlmostOutOfFiles
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available inodes left.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemalmostoutoffiles
          summary: Filesystem has less than 5% inodes left.
        expr: |
          (
            node_filesystem_files_free{job="node-exporter",fstype!=""} / node_filesystem_files{job="node-exporter",fstype!=""} * 100 < 5
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: warning
      - alert: NodeFilesystemAlmostOutOfFiles
        annotations:
          description: Filesystem on {{ $labels.device }} at {{ $labels.instance }}
            has only {{ printf "%.2f" $value }}% available inodes left.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodefilesystemalmostoutoffiles
          summary: Filesystem has less than 3% inodes left.
        expr: |
          (
            node_filesystem_files_free{job="node-exporter",fstype!=""} / node_filesystem_files{job="node-exporter",fstype!=""} * 100 < 3
          and
            node_filesystem_readonly{job="node-exporter",fstype!=""} == 0
          )
        for: 1h
        labels:
          severity: critical
      - alert: NodeNetworkReceiveErrs
        annotations:
          description: '{{ $labels.instance }} interface {{ $labels.device }} has encountered
            {{ printf "%.0f" $value }} receive errors in the last two minutes.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodenetworkreceiveerrs
          summary: Network interface is reporting many receive errors.
        expr: |
          increase(node_network_receive_errs_total[2m]) > 10
        for: 1h
        labels:
          severity: warning
      - alert: NodeNetworkTransmitErrs
        annotations:
          description: '{{ $labels.instance }} interface {{ $labels.device }} has encountered
            {{ printf "%.0f" $value }} transmit errors in the last two minutes.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-nodenetworktransmiterrs
          summary: Network interface is reporting many transmit errors.
        expr: |
          increase(node_network_transmit_errs_total[2m]) > 10
        for: 1h
        labels:
          severity: warning
    - name: kubernetes-apps
      rules:
      - alert: KubePodCrashLooping
        annotations:
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container
            }}) is restarting {{ printf "%.2f" $value }} times / 5 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodcrashlooping
        expr: |
          rate(kube_pod_container_status_restarts_total{job="kube-state-metrics"}[15m]) * 60 * 5 > 0
        for: 15m
        labels:
          severity: critical
      - alert: KubePodNotReady
        annotations:
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready
            state for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepodnotready
        expr: |
          sum by (namespace, pod) (max by(namespace, pod) (kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown"}) * on(namespace, pod) group_left(owner_kind) max by(namespace, pod, owner_kind) (kube_pod_owner{owner_kind!="Job"})) > 0
        for: 15m
        labels:
          severity: critical
      - alert: KubeDeploymentGenerationMismatch
        annotations:
          message: Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment
            }} does not match, this indicates that the Deployment has failed but has
            not been rolled back.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentgenerationmismatch
        expr: |
          kube_deployment_status_observed_generation{job="kube-state-metrics"}
            !=
          kube_deployment_metadata_generation{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeDeploymentReplicasMismatch
        annotations:
          message: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not
            matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedeploymentreplicasmismatch
        expr: |
          kube_deployment_spec_replicas{job="kube-state-metrics"}
            !=
          kube_deployment_status_replicas_available{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetReplicasMismatch
        annotations:
          message: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has
            not matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetreplicasmismatch
        expr: |
          kube_statefulset_status_replicas_ready{job="kube-state-metrics"}
            !=
          kube_statefulset_status_replicas{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetGenerationMismatch
        annotations:
          message: StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset
            }} does not match, this indicates that the StatefulSet has failed but has
            not been rolled back.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetgenerationmismatch
        expr: |
          kube_statefulset_status_observed_generation{job="kube-state-metrics"}
            !=
          kube_statefulset_metadata_generation{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: critical
      - alert: KubeStatefulSetUpdateNotRolledOut
        annotations:
          message: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update
            has not been rolled out.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubestatefulsetupdatenotrolledout
        expr: |
          max without (revision) (
            kube_statefulset_status_current_revision{job="kube-state-metrics"}
              unless
            kube_statefulset_status_update_revision{job="kube-state-metrics"}
          )
            *
          (
            kube_statefulset_replicas{job="kube-state-metrics"}
              !=
            kube_statefulset_status_replicas_updated{job="kube-state-metrics"}
          )
        for: 15m
        labels:
          severity: critical
      - alert: KubeDaemonSetRolloutStuck
        annotations:
          message: Only {{ $value | humanizePercentage }} of the desired Pods of DaemonSet
            {{ $labels.namespace }}/{{ $labels.daemonset }} are scheduled and ready.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetrolloutstuck
        expr: |
          kube_daemonset_status_number_ready{job="kube-state-metrics"}
            /
          kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"} < 1.00
        for: 15m
        labels:
          severity: critical
      - alert: KubeContainerWaiting
        annotations:
          message: Pod {{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container}}
            has been in waiting state for longer than 1 hour.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecontainerwaiting
        expr: |
          sum by (namespace, pod, container) (kube_pod_container_status_waiting_reason{job="kube-state-metrics"}) > 0
        for: 1h
        labels:
          severity: warning
      - alert: KubeDaemonSetNotScheduled
        annotations:
          message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset
            }} are not scheduled.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetnotscheduled
        expr: |
          kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
            -
          kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"} > 0
        for: 10m
        labels:
          severity: warning
      - alert: KubeDaemonSetMisScheduled
        annotations:
          message: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset
            }} are running where they are not supposed to run.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubedaemonsetmisscheduled
        expr: |
          kube_daemonset_status_number_misscheduled{job="kube-state-metrics"} > 0
        for: 10m
        labels:
          severity: warning
      - alert: KubeCronJobRunning
        annotations:
          message: CronJob {{ $labels.namespace }}/{{ $labels.cronjob }} is taking more
            than 1h to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecronjobrunning
        expr: |
          time() - kube_cronjob_next_schedule_time{job="kube-state-metrics"} > 3600
        for: 1h
        labels:
          severity: warning
      - alert: KubeJobCompletion
        annotations:
          message: Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more
            than one hour to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobcompletion
        expr: |
          kube_job_spec_completions{job="kube-state-metrics"} - kube_job_status_succeeded{job="kube-state-metrics"}  > 0
        for: 1h
        labels:
          severity: warning
      - alert: KubeJobFailed
        annotations:
          message: Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubejobfailed
        expr: |
          kube_job_failed{job="kube-state-metrics"}  > 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeHpaReplicasMismatch
        annotations:
          message: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has not matched the
            desired number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpareplicasmismatch
        expr: |
          (kube_hpa_status_desired_replicas{job="kube-state-metrics"}
            !=
          kube_hpa_status_current_replicas{job="kube-state-metrics"})
            and
          changes(kube_hpa_status_current_replicas[15m]) == 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeHpaMaxedOut
        annotations:
          message: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has been running at
            max replicas for longer than 15 minutes.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubehpamaxedout
        expr: |
          kube_hpa_status_current_replicas{job="kube-state-metrics"}
            ==
          kube_hpa_spec_max_replicas{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: warning
    - name: kubernetes-resources
      rules:
      - alert: KubeCPUOvercommit
        annotations:
          message: Cluster has overcommitted CPU resource requests for Pods and cannot
            tolerate node failure.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuovercommit
        expr: |
          sum(namespace:kube_pod_container_resource_requests_cpu_cores:sum)
            /
          sum(kube_node_status_allocatable_cpu_cores)
            >
          (count(kube_node_status_allocatable_cpu_cores)-1) / count(kube_node_status_allocatable_cpu_cores)
        for: 5m
        labels:
          severity: warning
      - alert: KubeMemOvercommit
        annotations:
          message: Cluster has overcommitted memory resource requests for Pods and cannot
            tolerate node failure.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememovercommit
        expr: |
          sum(namespace:kube_pod_container_resource_requests_memory_bytes:sum)
            /
          sum(kube_node_status_allocatable_memory_bytes)
            >
          (count(kube_node_status_allocatable_memory_bytes)-1)
            /
          count(kube_node_status_allocatable_memory_bytes)
        for: 5m
        labels:
          severity: warning
      - alert: KubeCPUOvercommit
        annotations:
          message: Cluster has overcommitted CPU resource requests for Namespaces.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubecpuovercommit
        expr: |
          sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="cpu"})
            /
          sum(kube_node_status_allocatable_cpu_cores)
            > 1.5
        for: 5m
        labels:
          severity: warning
      - alert: KubeMemOvercommit
        annotations:
          message: Cluster has overcommitted memory resource requests for Namespaces.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubememovercommit
        expr: |
          sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="memory"})
            /
          sum(kube_node_status_allocatable_memory_bytes{job="node-exporter"})
            > 1.5
        for: 5m
        labels:
          severity: warning
      - alert: KubeQuotaExceeded
        annotations:
          message: Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage
            }} of its {{ $labels.resource }} quota.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubequotaexceeded
        expr: |
          kube_resourcequota{job="kube-state-metrics", type="used"}
            / ignoring(instance, job, type)
          (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0)
            > 0.90
        for: 15m
        labels:
          severity: warning
      - alert: CPUThrottlingHigh
        annotations:
          message: '{{ $value | humanizePercentage }} throttling of CPU in namespace
            {{ $labels.namespace }} for container {{ $labels.container }} in pod {{
            $labels.pod }}.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-cputhrottlinghigh
        expr: |
          sum(increase(container_cpu_cfs_throttled_periods_total{container!="", }[5m])) by (container, pod, namespace)
            /
          sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace)
            > ( 25 / 100 )
        for: 15m
        labels:
          severity: warning
    - name: kubernetes-storage
      rules:
      - alert: KubePersistentVolumeUsageCritical
        annotations:
          message: The PersistentVolume claimed by {{ $labels.persistentvolumeclaim
            }} in Namespace {{ $labels.namespace }} is only {{ $value | humanizePercentage
            }} free.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeusagecritical
        expr: |
          kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}
            /
          kubelet_volume_stats_capacity_bytes{job="kubelet", metrics_path="/metrics"}
            < 0.03
        for: 1m
        labels:
          severity: critical
      - alert: KubePersistentVolumeFullInFourDays
        annotations:
          message: Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim
            }} in Namespace {{ $labels.namespace }} is expected to fill up within four
            days. Currently {{ $value | humanizePercentage }} is available.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumefullinfourdays
        expr: |
          (
            kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}
              /
            kubelet_volume_stats_capacity_bytes{job="kubelet", metrics_path="/metrics"}
          ) < 0.15
          and
          predict_linear(kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}[6h], 4 * 24 * 3600) < 0
        for: 1h
        labels:
          severity: critical
      - alert: KubePersistentVolumeErrors
        annotations:
          message: The persistent volume {{ $labels.persistentvolume }} has status {{
            $labels.phase }}.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubepersistentvolumeerrors
        expr: |
          kube_persistentvolume_status_phase{phase=~"Failed|Pending",job="kube-state-metrics"} > 0
        for: 5m
        labels:
          severity: critical
    - name: kubernetes-system
      rules:
      - alert: KubeVersionMismatch
        annotations:
          message: There are {{ $value }} different semantic versions of Kubernetes
            components running.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeversionmismatch
        expr: |
          count(count by (gitVersion) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"gitVersion","$1","gitVersion","(v[0-9]*.[0-9]*.[0-9]*).*"))) > 1
        for: 15m
        labels:
          severity: warning
      - alert: KubeClientErrors
        annotations:
          message: Kubernetes API server client '{{ $labels.job }}/{{ $labels.instance
            }}' is experiencing {{ $value | humanizePercentage }} errors.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclienterrors
        expr: |
          (sum(rate(rest_client_requests_total{code=~"5.."}[5m])) by (instance, job)
            /
          sum(rate(rest_client_requests_total[5m])) by (instance, job))
          > 0.01
        for: 15m
        labels:
          severity: warning
    - name: kube-apiserver-error
      rules:
      - alert: ErrorBudgetBurn
        annotations:
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-errorbudgetburn
        expr: |
          (
            status_class_5xx:apiserver_request_total:ratio_rate1h{job="apiserver"} > (14.4*0.010000)
            and
            status_class_5xx:apiserver_request_total:ratio_rate5m{job="apiserver"} > (14.4*0.010000)
          )
          or
          (
            status_class_5xx:apiserver_request_total:ratio_rate6h{job="apiserver"} > (6*0.010000)
            and
            status_class_5xx:apiserver_request_total:ratio_rate30m{job="apiserver"} > (6*0.010000)
          )
        labels:
          job: apiserver
          severity: critical
      - alert: ErrorBudgetBurn
        annotations:
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-errorbudgetburn
        expr: |
          (
            status_class_5xx:apiserver_request_total:ratio_rate1d{job="apiserver"} > (3*0.010000)
            and
            status_class_5xx:apiserver_request_total:ratio_rate2h{job="apiserver"} > (3*0.010000)
          )
          or
          (
            status_class_5xx:apiserver_request_total:ratio_rate3d{job="apiserver"} > (0.010000)
            and
            status_class_5xx:apiserver_request_total:ratio_rate6h{job="apiserver"} > (0.010000)
          )
        labels:
          job: apiserver
          severity: warning
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[5m]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate5m
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[30m]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate30m
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[1h]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate1h
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[2h]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate2h
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[6h]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate6h
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[1d]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate1d
      - expr: |
          sum by (status_class) (
            label_replace(
              rate(apiserver_request_total{job="apiserver"}[3d]
            ), "status_class", "${1}xx", "code", "([0-9])..")
          )
        labels:
          job: apiserver
        record: status_class:apiserver_request_total:rate3d
      - expr: |
          sum(status_class:apiserver_request_total:rate5m{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate5m{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate5m
      - expr: |
          sum(status_class:apiserver_request_total:rate30m{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate30m{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate30m
      - expr: |
          sum(status_class:apiserver_request_total:rate1h{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate1h{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate1h
      - expr: |
          sum(status_class:apiserver_request_total:rate2h{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate2h{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate2h
      - expr: |
          sum(status_class:apiserver_request_total:rate6h{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate6h{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate6h
      - expr: |
          sum(status_class:apiserver_request_total:rate1d{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate1d{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate1d
      - expr: |
          sum(status_class:apiserver_request_total:rate3d{job="apiserver",status_class="5xx"})
          /
          sum(status_class:apiserver_request_total:rate3d{job="apiserver"})
        labels:
          job: apiserver
        record: status_class_5xx:apiserver_request_total:ratio_rate3d
    - name: kubernetes-system-apiserver
      rules:
      - alert: KubeAPILatencyHigh
        annotations:
          message: The API server has an abnormal latency of {{ $value }} seconds for
            {{ $labels.verb }} {{ $labels.resource }}.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapilatencyhigh
        expr: |
          (
            cluster:apiserver_request_duration_seconds:mean5m{job="apiserver"}
            >
            on (verb) group_left()
            (
              avg by (verb) (cluster:apiserver_request_duration_seconds:mean5m{job="apiserver"} >= 0)
              +
              2*stddev by (verb) (cluster:apiserver_request_duration_seconds:mean5m{job="apiserver"} >= 0)
            )
          ) > on (verb) group_left()
          1.2 * avg by (verb) (cluster:apiserver_request_duration_seconds:mean5m{job="apiserver"} >= 0)
          and on (verb,resource)
          cluster_quantile:apiserver_request_duration_seconds:histogram_quantile{job="apiserver",quantile="0.99"}
          >
          1
        for: 5m
        labels:
          severity: warning
      - alert: KubeAPILatencyHigh
        annotations:
          message: The API server has a 99th percentile latency of {{ $value }} seconds
            for {{ $labels.verb }} {{ $labels.resource }}.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapilatencyhigh
        expr: |
          cluster_quantile:apiserver_request_duration_seconds:histogram_quantile{job="apiserver",quantile="0.99"} > 4
        for: 10m
        labels:
          severity: critical
      - alert: KubeAPIErrorsHigh
        annotations:
          message: API server is returning errors for {{ $value | humanizePercentage
            }} of requests.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorshigh
        expr: |
          sum(rate(apiserver_request_total{job="apiserver",code=~"5.."}[5m]))
            /
          sum(rate(apiserver_request_total{job="apiserver"}[5m])) > 0.03
        for: 10m
        labels:
          severity: critical
      - alert: KubeAPIErrorsHigh
        annotations:
          message: API server is returning errors for {{ $value | humanizePercentage
            }} of requests.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorshigh
        expr: |
          sum(rate(apiserver_request_total{job="apiserver",code=~"5.."}[5m]))
            /
          sum(rate(apiserver_request_total{job="apiserver"}[5m])) > 0.01
        for: 10m
        labels:
          severity: warning
      - alert: KubeAPIErrorsHigh
        annotations:
          message: API server is returning errors for {{ $value | humanizePercentage
            }} of requests for {{ $labels.verb }} {{ $labels.resource }} {{ $labels.subresource
            }}.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorshigh
        expr: |
          sum(rate(apiserver_request_total{job="apiserver",code=~"5.."}[5m])) by (resource,subresource,verb)
            /
          sum(rate(apiserver_request_total{job="apiserver"}[5m])) by (resource,subresource,verb) > 0.10
        for: 10m
        labels:
          severity: critical
      - alert: KubeAPIErrorsHigh
        annotations:
          message: API server is returning errors for {{ $value | humanizePercentage
            }} of requests for {{ $labels.verb }} {{ $labels.resource }} {{ $labels.subresource
            }}.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeapierrorshigh
        expr: |
          sum(rate(apiserver_request_total{job="apiserver",code=~"5.."}[5m])) by (resource,subresource,verb)
            /
          sum(rate(apiserver_request_total{job="apiserver"}[5m])) by (resource,subresource,verb) > 0.05
        for: 10m
        labels:
          severity: warning
      - alert: KubeClientCertificateExpiration
        annotations:
          message: A client certificate used to authenticate to the apiserver is expiring
            in less than 7.0 days.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration
        expr: |
          apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 604800
        labels:
          severity: warning
      - alert: KubeClientCertificateExpiration
        annotations:
          message: A client certificate used to authenticate to the apiserver is expiring
            in less than 24.0 hours.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubeclientcertificateexpiration
        expr: |
          apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 86400
        labels:
          severity: critical
    - name: kubernetes-system-kubelet
      rules:
      - alert: KubeNodeNotReady
        annotations:
          message: '{{ $labels.node }} has been unready for more than 15 minutes.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodenotready
        expr: |
          kube_node_status_condition{job="kube-state-metrics",condition="Ready",status="true"} == 0
        for: 15m
        labels:
          severity: warning
      - alert: KubeNodeUnreachable
        annotations:
          message: '{{ $labels.node }} is unreachable and some workloads may be rescheduled.'
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubenodeunreachable
        expr: |
          kube_node_spec_taint{job="kube-state-metrics",key="node.kubernetes.io/unreachable",effect="NoSchedule"} == 1
        for: 2m
        labels:
          severity: warning
      - alert: KubeletTooManyPods
        annotations:
          message: Kubelet '{{ $labels.node }}' is running at {{ $value | humanizePercentage
            }} of its Pod capacity.
          runbook_url: https://github.com/kubernetes-monitoring/kubernetes-mixin/tree/master/runbook.md#alert-name-kubelettoomanypods
        expr: |
          max(max(kubelet_running_pod_count{job="kubelet", metrics_path="/metrics"}) by(instance) * on(instance) group_left(node) kubelet_node_name{job="kubelet", metrics_path="/metrics"}) by(node) / max(kube_node_status_capacity_pods{job="kube-state-metrics"}) by(node) > 0.95
        for: 15m
        labels:
          severity: warning
    - name: prometheus
      rules:
      - alert: PrometheusBadConfig
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} has failed to
            reload its configuration.
          summary: Failed Prometheus configuration reload.
        expr: |
          # Without max_over_time, failed scrapes could create false negatives, see
          # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
          max_over_time(prometheus_config_last_reload_successful{job="prometheus-k8s",namespace="monitoring"}[5m]) == 0
        for: 10m
        labels:
          severity: critical
      - alert: PrometheusNotificationQueueRunningFull
        annotations:
          description: Alert notification queue of Prometheus {{$labels.namespace}}/{{$labels.pod}}
            is running full.
          summary: Prometheus alert notification queue predicted to run full in less
            than 30m.
        expr: |
          # Without min_over_time, failed scrapes could create false negatives, see
          # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
          (
            predict_linear(prometheus_notifications_queue_length{job="prometheus-k8s",namespace="monitoring"}[5m], 60 * 30)
          >
            min_over_time(prometheus_notifications_queue_capacity{job="prometheus-k8s",namespace="monitoring"}[5m])
          )
        for: 15m
        labels:
          severity: warning
      - alert: PrometheusErrorSendingAlertsToSomeAlertmanagers
        annotations:
          description: '{{ printf "%.1f" $value }}% errors while sending alerts from
            Prometheus {{$labels.namespace}}/{{$labels.pod}} to Alertmanager {{$labels.alertmanager}}.'
          summary: Prometheus has encountered more than 1% errors sending alerts to
            a specific Alertmanager.
        expr: |
          (
            rate(prometheus_notifications_errors_total{job="prometheus-k8s",namespace="monitoring"}[5m])
          /
            rate(prometheus_notifications_sent_total{job="prometheus-k8s",namespace="monitoring"}[5m])
          )
          * 100
          > 1
        for: 15m
        labels:
          severity: warning
      - alert: PrometheusErrorSendingAlertsToAnyAlertmanager
        annotations:
          description: '{{ printf "%.1f" $value }}% minimum errors while sending alerts
            from Prometheus {{$labels.namespace}}/{{$labels.pod}} to any Alertmanager.'
          summary: Prometheus encounters more than 3% errors sending alerts to any Alertmanager.
        expr: |
          min without(alertmanager) (
            rate(prometheus_notifications_errors_total{job="prometheus-k8s",namespace="monitoring"}[5m])
          /
            rate(prometheus_notifications_sent_total{job="prometheus-k8s",namespace="monitoring"}[5m])
          )
          * 100
          > 3
        for: 15m
        labels:
          severity: critical
      - alert: PrometheusNotConnectedToAlertmanagers
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} is not connected
            to any Alertmanagers.
          summary: Prometheus is not connected to any Alertmanagers.
        expr: |
          # Without max_over_time, failed scrapes could create false negatives, see
          # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
          max_over_time(prometheus_notifications_alertmanagers_discovered{job="prometheus-k8s",namespace="monitoring"}[5m]) < 1
        for: 10m
        labels:
          severity: warning
      - alert: PrometheusTSDBReloadsFailing
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} has detected
            {{$value | humanize}} reload failures over the last 3h.
          summary: Prometheus has issues reloading blocks from disk.
        expr: |
          increase(prometheus_tsdb_reloads_failures_total{job="prometheus-k8s",namespace="monitoring"}[3h]) > 0
        for: 4h
        labels:
          severity: warning
      - alert: PrometheusTSDBCompactionsFailing
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} has detected
            {{$value | humanize}} compaction failures over the last 3h.
          summary: Prometheus has issues compacting blocks.
        expr: |
          increase(prometheus_tsdb_compactions_failed_total{job="prometheus-k8s",namespace="monitoring"}[3h]) > 0
        for: 4h
        labels:
          severity: warning
      - alert: PrometheusNotIngestingSamples
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} is not ingesting
            samples.
          summary: Prometheus is not ingesting samples.
        expr: |
          rate(prometheus_tsdb_head_samples_appended_total{job="prometheus-k8s",namespace="monitoring"}[5m]) <= 0
        for: 10m
        labels:
          severity: warning
      - alert: PrometheusDuplicateTimestamps
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} is dropping
            {{ printf "%.4g" $value  }} samples/s with different values but duplicated
            timestamp.
          summary: Prometheus is dropping samples with duplicate timestamps.
        expr: |
          rate(prometheus_target_scrapes_sample_duplicate_timestamp_total{job="prometheus-k8s",namespace="monitoring"}[5m]) > 0
        for: 10m
        labels:
          severity: warning
      - alert: PrometheusOutOfOrderTimestamps
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} is dropping
            {{ printf "%.4g" $value  }} samples/s with timestamps arriving out of order.
          summary: Prometheus drops samples with out-of-order timestamps.
        expr: |
          rate(prometheus_target_scrapes_sample_out_of_order_total{job="prometheus-k8s",namespace="monitoring"}[5m]) > 0
        for: 10m
        labels:
          severity: warning
      - alert: PrometheusRemoteStorageFailures
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} failed to send
            {{ printf "%.1f" $value }}% of the samples to queue {{$labels.queue}}.
          summary: Prometheus fails to send samples to remote storage.
        expr: |
          (
            rate(prometheus_remote_storage_failed_samples_total{job="prometheus-k8s",namespace="monitoring"}[5m])
          /
            (
              rate(prometheus_remote_storage_failed_samples_total{job="prometheus-k8s",namespace="monitoring"}[5m])
            +
              rate(prometheus_remote_storage_succeeded_samples_total{job="prometheus-k8s",namespace="monitoring"}[5m])
            )
          )
          * 100
          > 1
        for: 15m
        labels:
          severity: critical
      - alert: PrometheusRemoteWriteBehind
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} remote write
            is {{ printf "%.1f" $value }}s behind for queue {{$labels.queue}}.
          summary: Prometheus remote write is behind.
        expr: |
          # Without max_over_time, failed scrapes could create false negatives, see
          # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
          (
            max_over_time(prometheus_remote_storage_highest_timestamp_in_seconds{job="prometheus-k8s",namespace="monitoring"}[5m])
          - on(job, instance) group_right
            max_over_time(prometheus_remote_storage_queue_highest_sent_timestamp_seconds{job="prometheus-k8s",namespace="monitoring"}[5m])
          )
          > 120
        for: 15m
        labels:
          severity: critical
      - alert: PrometheusRemoteWriteDesiredShards
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} remote write
            desired shards calculation wants to run {{ $value }} shards, which is more
            than the max of {{ printf `prometheus_remote_storage_shards_max{instance="%s",job="prometheus-k8s",namespace="monitoring"}`
            $labels.instance | query | first | value }}.
          summary: Prometheus remote write desired shards calculation wants to run more
            than configured max shards.
        expr: |
          # Without max_over_time, failed scrapes could create false negatives, see
          # https://www.robustperception.io/alerting-on-gauges-in-prometheus-2-0 for details.
          (
            max_over_time(prometheus_remote_storage_shards_desired{job="prometheus-k8s",namespace="monitoring"}[5m])
          >
            max_over_time(prometheus_remote_storage_shards_max{job="prometheus-k8s",namespace="monitoring"}[5m])
          )
        for: 15m
        labels:
          severity: warning
      - alert: PrometheusRuleFailures
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} has failed to
            evaluate {{ printf "%.0f" $value }} rules in the last 5m.
          summary: Prometheus is failing rule evaluations.
        expr: |
          increase(prometheus_rule_evaluation_failures_total{job="prometheus-k8s",namespace="monitoring"}[5m]) > 0
        for: 15m
        labels:
          severity: critical
      - alert: PrometheusMissingRuleEvaluations
        annotations:
          description: Prometheus {{$labels.namespace}}/{{$labels.pod}} has missed {{
            printf "%.0f" $value }} rule group evaluations in the last 5m.
          summary: Prometheus is missing rule evaluations due to slow rule group evaluation.
        expr: |
          increase(prometheus_rule_group_iterations_missed_total{job="prometheus-k8s",namespace="monitoring"}[5m]) > 0
        for: 15m
        labels:
          severity: warning
    - name: alertmanager.rules
      rules:
      - alert: AlertmanagerConfigInconsistent
        annotations:
          message: The configuration of the instances of the Alertmanager cluster `{{$labels.service}}`
            are out of sync.
        expr: |
          count_values("config_hash", alertmanager_config_hash{job="alertmanager-main",namespace="monitoring"}) BY (service) / ON(service) GROUP_LEFT() label_replace(max(prometheus_operator_spec_replicas{job="prometheus-operator",namespace="monitoring",controller="alertmanager"}) by (name, job, namespace, controller), "service", "alertmanager-$1", "name", "(.*)") != 1
        for: 5m
        labels:
          severity: critical
      - alert: AlertmanagerFailedReload
        annotations:
          message: Reloading Alertmanager's configuration has failed for {{ $labels.namespace
            }}/{{ $labels.pod}}.
        expr: |
          alertmanager_config_last_reload_successful{job="alertmanager-main",namespace="monitoring"} == 0
        for: 10m
        labels:
          severity: warning
      - alert: AlertmanagerMembersInconsistent
        annotations:
          message: Alertmanager has not found all other members of the cluster.
        expr: |
          alertmanager_cluster_members{job="alertmanager-main",namespace="monitoring"}
            != on (service) GROUP_LEFT()
          count by (service) (alertmanager_cluster_members{job="alertmanager-main",namespace="monitoring"})
        for: 5m
        labels:
          severity: critical
    - name: general.rules
      rules:
      - alert: TargetDown
        annotations:
          message: '{{ printf "%.4g" $value }}% of the {{ $labels.job }}/{{ $labels.service
            }} targets in {{ $labels.namespace }} namespace are down.'
        expr: 100 * (count(up == 0) BY (job, namespace, service) / count(up) BY (job,
          namespace, service)) > 10
        for: 10m
        labels:
          severity: warning
      - alert: Watchdog
        annotations:
          message: |
            This is an alert meant to ensure that the entire alerting pipeline is functional.
            This alert is always firing, therefore it should always be firing in Alertmanager
            and always fire against a receiver. There are integrations with various notification
            mechanisms that send a notification when this alert is not firing. For example the
            "DeadMansSnitch" integration in PagerDuty.
        expr: vector(1)
        labels:
          severity: none
    - name: node-time
      rules:
      - alert: ClockSkewDetected
        annotations:
          message: Clock skew detected on node-exporter {{ $labels.namespace }}/{{ $labels.pod
            }}. Ensure NTP is configured correctly on this host.
        expr: |
          abs(node_timex_offset_seconds{job="node-exporter"}) > 0.05
        for: 2m
        labels:
          severity: warning
    - name: node-network
      rules:
      - alert: NodeNetworkInterfaceFlapping
        annotations:
          message: Network interface "{{ $labels.device }}" changing it's up status
            often on node-exporter {{ $labels.namespace }}/{{ $labels.pod }}"
        expr: |
          changes(node_network_up{job="node-exporter",device!~"veth.+"}[2m]) > 2
        for: 2m
        labels:
          severity: warning
    - name: prometheus-operator
      rules:
      - alert: PrometheusOperatorReconcileErrors
        annotations:
          message: Errors while reconciling {{ $labels.controller }} in {{ $labels.namespace
            }} Namespace.
        expr: |
          rate(prometheus_operator_reconcile_errors_total{job="prometheus-operator",namespace="monitoring"}[5m]) > 0.1
        for: 10m
        labels:
          severity: warning
      - alert: PrometheusOperatorNodeLookupErrors
        annotations:
          message: Errors while reconciling Prometheus in {{ $labels.namespace }} Namespace.
        expr: |
          rate(prometheus_operator_node_address_lookup_errors_total{job="prometheus-operator",namespace="monitoring"}[5m]) > 0.1
        for: 10m
        labels:
          severity: warning