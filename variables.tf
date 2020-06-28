variable "region" {
  type    = "string"
  default = "us-west-2"
}

variable "vpc-cidr" {
  type    = "string"
  default = "10.22.0.0/16"
}

variable "cluster-name" {
  type    = "string"
  default = "academy"
}

variable "domain-name" {
  type    = "string"
  default = "cloudacademy.eti.br"
}

variable "company" {
    default = "Acme"
}

variable "elasticsearch-domain-name" {
  type    = "string"
  default = "jaeger-tracing"
}

variable "network-private" {
  type = list(object({
    subnets-cidr      = string
    availability_zone = string
    access-layer      = string
  }))

  default = [
    { subnets-cidr : "10.22.0.0/21", availability_zone : "us-west-2a", access-layer : "private" },
    { subnets-cidr : "10.22.8.0/21", availability_zone : "us-west-2b", access-layer : "private" },
    { subnets-cidr : "10.22.16.0/21", availability_zone : "us-west-2c", access-layer : "private" },
  ]
}

variable "network-public" {
  type = list(object({
    subnets-cidr      = string
    availability_zone = string
    access-layer      = string
  }))

  default = [
    { subnets-cidr : "10.22.24.0/21", availability_zone : "us-west-2a", access-layer : "public" },
    { subnets-cidr : "10.22.32.0/21", availability_zone : "us-west-2b", access-layer : "public" },
    { subnets-cidr : "10.22.64.0/21", availability_zone : "us-west-2c", access-layer : "public" },
  ]
}

variable  "instance_type" {
    type    = "map"
    default = {
        nexus  = "t2.large"

}
}

variable "desired_capacity-kubernetes" {
  type    = number
  default = 4
}

variable "min-size-kubernetes" {
  type    = number
  default = 4
}

variable "max-size-kubernetes" {
  type    = number
  default = 8
}

variable "on_demand_percent" {
  type = number
  default = 0
}

variable "on_demand_base_capacity" {
  type = number
  default = 0
}

# variable "map-users-k8s" {
#   type = "string"
# }