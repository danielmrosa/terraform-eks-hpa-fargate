resource "kubernetes_config_map" "aws-auth" {
  metadata {
    name      = "aws-auth"
    namespace = "kube-system"
  }
  data = {
    mapRoles = <<EOF
- rolearn: ${aws_iam_role.aws-iam-eks-nodes-poc-eks-talk-security.arn}
  username: system:node:{{EC2PrivateDNSName}}
  groups:
    - system:bootstrappers
    - system:nodes

- rolearn: ${aws_iam_role.aws-iam-eks-fargate-role-poc-eks-talk-security.arn}
  username: system:node:{{SessionName}}
  groups:
    - system:bootstrappers
    - system:nodes
    - system:node-proxier
   EOF
    
    mapUsers = <<EOF
- userarn: arn:aws:iam::237930432518:user/daniel.rosa
  username: daniel.rosa
  groups:
   - system:masters
   EOF
  }
  depends_on = [
    aws_eks_cluster.aws-eks-master,
    aws_autoscaling_group.aws-autoscaling-group-nodes
  ]
}