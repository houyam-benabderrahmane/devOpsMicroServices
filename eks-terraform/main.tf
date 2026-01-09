# ----------------------------
# Variables
# ----------------------------
variable "node_group_name" {
  type    = string
  default = "eks-node-group"
}

# ----------------------------
# Provider AWS
# ----------------------------
provider "aws" {
  region = "us-east-1"
}

# ----------------------------
# VPC
# ----------------------------
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "Lab-VPC"
  }
}

# ----------------------------
# Subnets
# ----------------------------
resource "aws_subnet" "subnet-1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"
  map_public_ip_on_launch = true

  tags = { Name = "Public-Subnet-1" }
}

resource "aws_subnet" "subnet-2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1b"
  map_public_ip_on_launch = true

  tags = { Name = "Public-Subnet-2" }
}

# ----------------------------
# Security Group
# ----------------------------
resource "aws_security_group" "selected" {
  name        = "Jumphost-sg"
  description = "Allow SSH and all outbound"
  vpc_id      = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "Jumphost-sg" }
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
# EKS Cluster
# ----------------------------
resource "aws_eks_cluster" "eks" {
  name     = "MelCluster"
  role_arn = data.aws_iam_role.master.arn

  vpc_config {
    subnet_ids         = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
    security_group_ids = [aws_security_group.selected.id]
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
  subnet_ids      = [aws_subnet.subnet-1.id, aws_subnet.subnet-2.id]
  capacity_type   = "ON_DEMAND"
  disk_size       = 20
  instance_types  = ["t2.large"]

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

# ----------------------------
# Backend S3
# ----------------------------
terraform {
  backend "s3" {
    bucket = "ml-terraform-state-8749f2b4"
    key    = "k8/terraform.tfstate"
    region = "us-east-1"
  }
}
