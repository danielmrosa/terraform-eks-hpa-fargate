provider "aws" {
  region  = var.region
  version = "~> 2.8"
}

provider "aws" {
  alias = "oregon"
  region = "us-west-2"
}

terraform {
  required_version = ">= 0.12.13"
  required_providers {
    aws        = "~> 2.43"
    kubernetes = "~> 1.8"
    local      = "~> 1.3"
    template   = "~> 2.1"
    helm       = "~> 0.10"
    external   = "~> 1.2"
    tls        = "~> 2.1"
    archive    = "~> 1.2"
    random     = "~> 2.2"
  }

  backend "s3" {
    region = "us-west-2"
    key    = "terraform.tfstate"
    bucket = "terraform-talk-security-eks"
  }
}

data "aws_eks_cluster_auth" "cluster_auth" {
  name = var.cluster-name
}

provider "helm" {
  kubernetes {
    host                   = aws_eks_cluster.aws-eks-master.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.aws-eks-master.certificate_authority.0.data)
    token                  = data.aws_eks_cluster_auth.cluster_auth.token
    load_config_file       = false
  }
  service_account = "tiller"
  install_tiller  = true
  init_helm_home  = true
  debug           = true
}

provider "kubernetes" {
  host                   = aws_eks_cluster.aws-eks-master.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.aws-eks-master.certificate_authority.0.data)
  token                  =  data.aws_eks_cluster_auth.cluster_auth.token
  load_config_file       = false
}