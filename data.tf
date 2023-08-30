# Generate userdata for Tailscale instance
data "template_file" "ec2_user_data" {
  template = file("${path.module}/ec2_user_data.yml.tpl")

  vars = {
    tailscale_auth_key         = var.tailscale_auth_key
    tailscale_advertise_routes = join(",", var.allowed_cidr_blocks)
    hostname                   = local.name
  }
}

# Download latest AMI info for Amazon Linux 2023
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
