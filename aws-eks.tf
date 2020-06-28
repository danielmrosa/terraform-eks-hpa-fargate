locals {
  node-userdata               = <<EOF
              #!/bin/bash
              set -o xtrace
              /etc/eks/bootstrap.sh --apiserver-endpoint '${aws_eks_cluster.aws-eks-master.endpoint}' \
                                    --b64-cluster-ca '${aws_eks_cluster.aws-eks-master.certificate_authority.0.data}' '${var.cluster-name}'
            EOF
  k8s-version                 = "1.14"
  kubernetes-tag-cluster-name = "kubernetes.io/cluster/${var.cluster-name}"
}

data "aws_ami" "eks-worker" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${aws_eks_cluster.aws-eks-master.version}-v*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon EKS AMI Account ID
}

resource "aws_cloudwatch_log_group" "eks-cloudwatch" {
  name              = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = 7
}

resource "aws_eks_cluster" "aws-eks-master" {
  name                      = var.cluster-name
  role_arn                  = aws_iam_role.aws-iam-eks-master-poc-eks-academy.arn
  version                   = local.k8s-version
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  vpc_config {
    subnet_ids         = data.aws_subnet_ids.subnet-ids-private.ids
    security_group_ids = [aws_security_group.aws-eks-security-master-group.id]
  }
//Evita sempre recriar o cluster
  lifecycle {
    ignore_changes = [
      "certificate_authority",
      "identity",
      "vpc_config"
    ]
  }

  depends_on = [
    aws_iam_role_policy_attachment.aws-iam-eks-cluster-poc-eks-academy,
    aws_iam_role_policy_attachment.aws-iam-eks-service-poc-eks-academy,
    aws_cloudwatch_log_group.eks-cloudwatch
  ]
}

resource "aws_launch_configuration" "aws-launch-nodes" {
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.aws-iam-node-profile-poc-eks-academy.name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "m5.large"
  name_prefix                 = "node-${var.cluster-name}-"
  security_groups             = [aws_security_group.aws-eks-node-security-group.id]
  user_data_base64            = base64encode(local.node-userdata)

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_launch_template" "aws-launch-template-academy" {
  name                        = var.cluster-name
  image_id                    = data.aws_ami.eks-worker.id
  instance_type               = "m5.large"
  user_data                   = base64encode(local.node-userdata)
  iam_instance_profile {
    name = aws_iam_instance_profile.aws-iam-node-profile-poc-eks-academy.name
  }
  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.aws-eks-node-security-group.id]
  }
}


resource "aws_autoscaling_group" "aws-autoscaling-group-nodes" {
  # launch_configuration = aws_launch_configuration.aws-launch-nodes.id
  desired_capacity     = "${var.desired_capacity-kubernetes}"
  max_size             = "${var.max-size-kubernetes}"
  min_size             = "${var.min-size-kubernetes}"
  name                 = "nodes-${var.cluster-name}"
  vpc_zone_identifier  = data.aws_subnet_ids.subnet-ids-private.ids
  //  target_group_arns    = [aws_lb_target_group.node-target-group.arn]

  mixed_instances_policy {
    launch_template {
      launch_template_specification {
        launch_template_id = aws_launch_template.aws-launch-template-academy.id
      }
    }
    instances_distribution {
          on_demand_base_capacity                   = var.on_demand_base_capacity
          on_demand_percentage_above_base_capacity  = var.on_demand_percent
          spot_allocation_strategy                = "capacity-optimized"
    }
  }

  //Evita atualizar o cluster quando gerenciado pelo "ClusterAutoscaling"
  lifecycle {
    ignore_changes = ["desired_capacity", mixed_instances_policy.0.launch_template.0.override]
  }

  tag {
    key                 = "Name"
    value               = "node-${var.cluster-name}"
    propagate_at_launch = true
  }

  tag {
    key                 = "kubernetes.io/cluster/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/${var.cluster-name}"
    value               = "owned"
    propagate_at_launch = true
  }

  tag {
    key                 = "k8s.io/cluster-autoscaler/enabled"
    value               = "true"
    propagate_at_launch = true
  }

  tag {
    key = "customer"
    value = "Acme"
    propagate_at_launch = true
  }
}

output "eks-endpoint" {
  value = aws_eks_cluster.aws-eks-master.endpoint
}

output "eks-arn" {
  value = aws_eks_cluster.aws-eks-master.arn
}

output "eks-certificate_authority" {
  value = aws_eks_cluster.aws-eks-master.certificate_authority.0.data
}

resource "aws_eks_fargate_profile" "fargate-profile-1" {
# //Evita sempre recriar
  lifecycle {
    ignore_changes = [
      "cluster_name",
      "fargate_profile_name",
      "pod_execution_role_arn",
      "subnet_ids "
    ]
  }
  cluster_name           = var.cluster-name
  fargate_profile_name   = "fargate-profile-1"
  pod_execution_role_arn = aws_iam_role.aws-iam-eks-fargate-role-poc-eks-academy.arn
  subnet_ids             = data.aws_subnet_ids.subnet-ids-private.ids
  selector {
    namespace = "fargate"
  }
}