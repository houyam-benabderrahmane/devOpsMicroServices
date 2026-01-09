terraform {
  backend "s3" {
    bucket = "ml-terraform-state-8749f2b4"
    key    = "k8/terraform.tfstate"
    region = "us-east-1"
  }
}

# VPC Data Source
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["Lab-VPC"]
  }
}

# Subnet Data Source - UPDATE "SUBNET-NAME-HERE" with your actual subnet name from the command above
data "aws_subnet" "subnet-1" {
  filter {
    name   = "tag:Name"
    values = ["SUBNET-NAME-HERE"]  # Replace with actual subnet name
  }
  vpc_id = data.aws_vpc.main.id
}

# Security Group Data Source
data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = ["Lab-SG"]
  }
  vpc_id = data.aws_vpc.main.id
}

# Add your other resources here (EKS cluster, node groups, etc.)