resource "aws_security_group" "aws-eks-security-master-group" {
  name        = "eks-master"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
  }
}

resource "aws_security_group" "aws-eks-node-security-group" {
  name        = "eks-node"
  description = "Security group for all nodes in the cluster"
  vpc_id      = aws_vpc.vpc.id

  egress {
    from_port   = 0
    protocol    = "-1"
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    "kubernetes.io/cluster/${var.cluster-name}" = "owned"
     customer = "iti"
     cost = "iti"
  }
}

resource "aws_security_group_rule" "aws-eks-node-ingress-cluster" {
  description = "Allow worker Kubelets and pods to receive communication from the cluster control plane"
  type        = "ingress"
  from_port   = 1025
  to_port     = 65535
  protocol    = "tcp"

  security_group_id        = aws_security_group.aws-eks-node-security-group.id
  source_security_group_id = aws_security_group.aws-eks-security-master-group.id

}

resource "aws_security_group_rule" "aws-eks-node-ingress-self" {
  description = "Allow node to communicate with each other"
  type        = "ingress"
  from_port   = 0
  to_port     = 65535
  protocol    = "-1"

  security_group_id        = aws_security_group.aws-eks-node-security-group.id
  source_security_group_id = aws_security_group.aws-eks-node-security-group.id
}

resource "aws_security_group_rule" "aws-eks-cluster-ingress-master-https" {
  description              = "Allow pods running extension API servers on port 443 to receive communication from cluster control plane"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aws-eks-node-security-group.id
  source_security_group_id = aws_security_group.aws-eks-security-master-group.id
}

resource "aws_security_group_rule" "aws-eks-cluster-ingress-node-https" {
  description              = "Allow pods to communicate with the cluster API Server"
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.aws-eks-security-master-group.id
  source_security_group_id = aws_security_group.aws-eks-node-security-group.id
}