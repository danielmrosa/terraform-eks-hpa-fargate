data "aws_iam_policy_document" "aws-assume-role-policy-eks-demo" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "aws-assume-role-policy-ec2-demo" {
  version = "2012-10-17"
  statement {
    actions = ["sts:AssumeRole"]
    effect  = "Allow"
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "aws-cluster-auto-scaler-policy-document-demo" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "aws-ingress-policy-document-demo" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "acm:DescribeCertificate",
      "acm:ListCertificates",
      "acm:GetCertificate",
      "ec2:AuthorizeSecurityGroupIngress",
      "ec2:CreateSecurityGroup",
      "ec2:CreateTags",
      "ec2:DeleteTags",
      "ec2:DeleteSecurityGroup",
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeInstances",
      "ec2:DescribeInstanceStatus",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:ModifyInstanceAttribute",
      "ec2:ModifyNetworkInterfaceAttribute",
      "ec2:RevokeSecurityGroupIngress",
      "elasticloadbalancing:AddListenerCertificates",
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:DescribeListenerCertificates",
      "elasticloadbalancing:DescribeListeners",
      "elasticloadbalancing:DescribeLoadBalancers",
      "elasticloadbalancing:DescribeLoadBalancerAttributes",
      "elasticloadbalancing:DescribeRules",
      "elasticloadbalancing:DescribeSSLPolicies",
      "elasticloadbalancing:DescribeTags",
      "elasticloadbalancing:DescribeTargetGroups",
      "elasticloadbalancing:DescribeTargetGroupAttributes",
      "elasticloadbalancing:DescribeTargetHealth",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:RemoveListenerCertificates",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets",
      "elasticloadbalancing:SetWebACL",
      "iam:CreateServiceLinkedRole",
      "iam:GetServerCertificate",
      "iam:ListServerCertificates",
      "cognito-idp:DescribeUserPoolClient",
      "waf-regional:GetWebACLForResource",
      "waf-regional:GetWebACL",
      "waf-regional:AssociateWebACL",
      "waf-regional:DisassociateWebACL",
      "waf:GetWebACL",
      "tag:GetResources",
      "tag:TagResources",
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "aws-external-dns-policy-document-demo" {
  version = "2012-10-17"
  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "aws-external-dns-policy-poc-eks-academy" {
  name   = "aws-external-dns-policy-${var.cluster-name}"
  policy = data.aws_iam_policy_document.aws-external-dns-policy-document-demo.json
}

resource "aws_iam_role_policy_attachment" "aws-external-dns-attachment-poc-eks-academy" {
  # name       = "aws-external-dns-attachment-${var.cluster-name}"
  policy_arn = aws_iam_policy.aws-external-dns-policy-poc-eks-academy.arn
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_policy" "aws-ingress-policy-poc-eks-academy" {
  name   = "aws-ingress-policy-${var.cluster-name}"
  policy = data.aws_iam_policy_document.aws-ingress-policy-document-demo.json
}

resource "aws_iam_role_policy_attachment" "aws-ingress-policy-attachment-poc-eks-academy" {
  policy_arn = aws_iam_policy.aws-ingress-policy-poc-eks-academy.arn
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_policy" "aws-cluster-auto-scaler-policy-poc-eks-academy" {
  name   = "ClusterAutoScaler-${var.cluster-name}"
  policy = data.aws_iam_policy_document.aws-cluster-auto-scaler-policy-document-demo.json
}

resource "aws_iam_role_policy_attachment" "aws-cluster-auto-scaler-attachment-poc-eks-academy" {
  policy_arn = aws_iam_policy.aws-cluster-auto-scaler-policy-poc-eks-academy.arn
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_role" "aws-iam-eks-master-poc-eks-academy" {
  name                  = "eks-role-master-${var.cluster-name}"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.aws-assume-role-policy-eks-demo.json
}

resource "aws_iam_role" "aws-iam-eks-nodes-poc-eks-academy" {
  name                  = "eks-role-nodes-${var.cluster-name}"
  force_detach_policies = true
  assume_role_policy    = data.aws_iam_policy_document.aws-assume-role-policy-ec2-demo.json
}

resource "aws_iam_role_policy_attachment" "aws-iam-eks-cluster-poc-eks-academy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role      = aws_iam_role.aws-iam-eks-master-poc-eks-academy.name
}

resource "aws_iam_role_policy_attachment" "aws-iam-eks-service-poc-eks-academy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role      = aws_iam_role.aws-iam-eks-master-poc-eks-academy.name
}

resource "aws_iam_role_policy_attachment" "aws-iam-eks-node-policy-poc-eks-academy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_role_policy_attachment" "aws-iam-eks-node-CNI-Policy-poc-eks-academy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_role_policy_attachment" "aws-iam-eks-ec2-container-registry-readOnly-poc-eks-academy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role      = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

resource "aws_iam_instance_profile" "aws-iam-node-profile-poc-eks-academy" {
  name = "aws-iam-node-profile-${var.cluster-name}"
  role = aws_iam_role.aws-iam-eks-nodes-poc-eks-academy.name
}

data "aws_region" "current" {}

data "aws_caller_identity" "current" {}


#Fargate
resource "aws_iam_role" "aws-iam-eks-fargate-role-poc-eks-academy" {
  name = "eks-fargate-role-poc-eks-academy"
  assume_role_policy = jsonencode({
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = {
        Service = "eks-fargate-pods.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}
resource "aws_iam_role_policy_attachment" "example-AmazonEKSFargatePodExecutionRolePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSFargatePodExecutionRolePolicy"
  role       = aws_iam_role.aws-iam-eks-fargate-role-poc-eks-academy.name
}