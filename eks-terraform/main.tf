# VPC Data Source
data "aws_vpc" "main" {
  filter {
    name   = "tag:Name"
    values = ["Lab-VPC"]
  }
}

# Subnet Data Source - using subnet ID
data "aws_subnet" "subnet-1" {
  id = "subnet-0a279c13410eafe84"
}

# Security Group Data Source
data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = ["Lab-SG"]
  }
  vpc_id = data.aws_vpc.main.id
}

# Add your EKS cluster and other resources below this line