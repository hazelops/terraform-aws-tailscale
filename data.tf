# Instance AMI
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-*-x86_64"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}
