data "aws_subnet" "subnet-1" {
  filter {
    name   = "tag:Name"
    values = ["my-subnet-1"]
  }
  vpc_id = data.aws_vpc.main.id
}

data "aws_security_group" "selected" {
  filter {
    name   = "group-name"
    values = ["my-security-group"]
  }
  vpc_id = data.aws_vpc.main.id
}
