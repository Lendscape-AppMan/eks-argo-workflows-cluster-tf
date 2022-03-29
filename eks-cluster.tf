#
# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_eks_cluster" "argo-workflows-cluster" {
  name     = var.cluster-name
  role_arn = aws_iam_role.iam-cluster-role.arn


  vpc_config {
    security_group_ids = [aws_security_group.argo-workflows-security-group.id]
    subnet_ids         = aws_subnet.public-subnets[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.argo-workflows-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.argo-workflows-AmazonEKSVPCResourceController,
  ]
}

data "aws_availability_zones" "available" {}

# Not required: currently used in conjunction with using
# icanhazip.com to determine local workstation external IP
# to open EC2 Security Group access to the Kubernetes cluster.
# See workstation-external-ip.tf for additional information.
provider "http" {}

resource "aws_iam_role" "iam-cluster-role" {
  name = "argo-workflows-cluster-role"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "argo-workflows-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.iam-cluster-role.name
}

resource "aws_iam_role_policy_attachment" "argo-workflows-AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.iam-cluster-role.name
}

resource "aws_security_group" "argo-workflows-security-group" {
  name        = "argo-workflows-security-group"
  description = "Cluster communication with worker nodes"
  vpc_id      = aws_vpc.argo-workflows-vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-argo-workflows"
  }
}

resource "aws_security_group_rule" "argo-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.argo-workflows-security-group.id
  to_port           = 443
  type              = "ingress"
}


