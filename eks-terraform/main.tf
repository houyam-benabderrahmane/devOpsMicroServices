# Provider
provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# IAM Roles existants (LabRole)
# ----------------------------
data "aws_iam_role" "master" {
  name = "LabRole"
}

data "aws_iam_role" "worker" {
  name = "LabRole"
}

# ----------------------------
# VPC et Subnets
# ----------------------------
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["Lab-VPC"]
  }
}

# Utilisation directe des IDs de subnet (pas de tags Name disponibles)
data "aws_subnet" "subnet-1" {
  id = "subnet-0a279c13410eafe84"
}

data "aws_subnet" "subnet-2" {
  id = "subnet-02354de7499256418"
}

data "aws_security_group" "selected" {
  vpc_id = data.aws_vpc.main.id
  filter {
    name   = "group-name"
    values = ["Lab-SG"]
  }
}

# ----------------------------
# EKS Cluster
# ----------------------------
resource "aws_eks_cluster" "eks" {
  name     = "MelCluster"
  role_arn = data.aws_iam_role.master.arn

  vpc_config {
    subnet_ids         = [data.aws_subnet.subnet-1.id, data.aws_subnet.subnet-2.id]
    security_group_ids = [data.aws_security_group.selected.id]
  }

  tags = {
    Name        = "MelCluster"
    Environment = "dev"
    Terraform   = "true"
  }
}

# ----------------------------
# EKS Node Group
# ----------------------------
resource "aws_eks_node_group" "node-grp" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = var.node_group_name
  node_role_arn   = data.aws_iam_role.worker.arn
  subnet_ids      = [data.aws_subnet.subnet-1.id, data.aws_subnet.subnet-2.id]
  
  capacity_type  = "ON_DEMAND"
  disk_size      = 20
  instance_types = ["t2.large"]

  scaling_config {
    desired_size = 3
    max_size     = 10
    min_size     = 2
  }

  tags = {
    Name = "lab-eks-node-group"
  }
}

# ----------------------------
# OIDC Provider pour ServiceAccount IAM Roles
# ----------------------------
data "aws_eks_cluster" "eks_oidc" {
  name = aws_eks_cluster.eks.name
}

data "tls_certificate" "oidc_thumbprint" {
  url = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks_oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.oidc_thumbprint.certificates[0].sha1_fingerprint]
  url             = data.aws_eks_cluster.eks_oidc.identity[0].oidc[0].issuer

  tags = {
    Name = "eks-oidc-provider"
  }
}