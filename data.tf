# Instance AMI
# Get latest AMI info for Amazon Linux
data "aws_ami" "this" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-*-${local.instance_arch}"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  owners = ["amazon"]
}
