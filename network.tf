resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc-cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  assign_generated_ipv6_cidr_block = false
  enable_classiclink               = false
  enable_classiclink_dns_support   = false
  instance_tenancy                 = "default"

  tags = {
    Name                                        = var.cluster-name
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    customer = "iti"
  }
}

resource "aws_subnet" "aws-subnets-public" {
  count             = length(var.network-public)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.network-public[count.index].subnets-cidr
  availability_zone = var.network-public[count.index].availability_zone

  tags = {
    Name                                        = "subnet-public ${var.network-private[count.index].availability_zone}"
    Public                                      = 1
    "kubernetes.io/role/elb"                    = 1
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    customer = "Acme"
  }
}

resource "aws_subnet" "aws-subnets-private" {
  count             = length(var.network-private)
  vpc_id            = aws_vpc.vpc.id
  cidr_block        = var.network-private[count.index].subnets-cidr
  availability_zone = var.network-private[count.index].availability_zone

  tags = {
    Name                                        = "subnet-private ${var.network-private[count.index].availability_zone}"
    Private                                     = 1
    "kubernetes.io/role/internal-elb"           = 1
    "kubernetes.io/cluster/${var.cluster-name}" = "shared"
    customer = "Acme"

  }
}

resource "aws_internet_gateway" "internet-gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Name = var.cluster-name
    customer = "Acme"
  }
}

data "aws_subnet_ids" "subnet-ids-private" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Private = "1"
    customer = "Acme"
  }

  depends_on = [aws_subnet.aws-subnets-public,
    aws_subnet.aws-subnets-private
  ]
}

data "aws_subnet_ids" "subnet-ids-public" {
  vpc_id = aws_vpc.vpc.id

  tags = {
    Public = "1"
    customer = "Acme"
  }

  depends_on = [aws_subnet.aws-subnets-public,
    aws_subnet.aws-subnets-private
  ]
}

