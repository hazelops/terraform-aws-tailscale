# Tailscale instance user data
data "template_file" "ec2_user_data" {
  template = file("${path.module}/templates/ec2_user_data.tpl.yml")

  vars = {
    auth_key         = tailscale_tailnet_key.this.key
    advertise_routes = join(",", var.allowed_cidr_blocks)
    hostname         = local.name
  }
}

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
