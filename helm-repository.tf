# kube-metrics-adapter
data "helm_repository" "banzaicloud" {
  name = "banzaicloud"
  url  = "https://kubernetes-charts.banzaicloud.com"
}

#hpa-operator
data "helm_repository" "banzaicloud-stable" {
  name = "banzaicloud-stable"
  url  = "https://kubernetes-charts.banzaicloud.com"
}

data "helm_repository" "istio-repository" {
  name = "istio.io"
  url  = "https://storage.googleapis.com/istio-release/releases/1.5.1/charts/"
}

data "helm_repository" "bitnami-repository" {
  name = "bitnami-repository"
  url  = "https://charts.bitnami.com/bitnami"
  
}

data "helm_repository" "stable" {
  name = "stable"
  url  = "https://kubernetes-charts.storage.googleapis.com"
}

data "helm_repository" "incubator" {
  name = "incubator"
  url  = "http://storage.googleapis.com/kubernetes-charts-incubator"
}