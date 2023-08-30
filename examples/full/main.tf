variable "env" {}
variable "vpc_id" {}
variable "subnets" {}
variable "ec2_key_pair_name" {}
variable "ssh_public_key" {}
variable "vpc_cidr_block" {}
variable "ssh_key_id" {}
variable "aws_key_name" {}

# Obtain Tailscale auth key from AWS SSM Parameter Store
data "aws_ssm_parameter" "tailscale_auth_key" {
  name = "/${var.env}/global/tailscale_auth_key"
}

module "tailscale" {
  source              = "registry.terraform.io/hazelops/tailscale/aws"
  version             = "~>0.1"
  name                = "tailscale-instance"
  allowed_cidr_blocks = [var.vpc_cidr_block]
  ec2_key_pair_name   = var.aws_key_name
  env                 = var.env
  subnets             = var.subnets
  vpc_id              = var.vpc_id
  public_ip_enabled   = true
  ami_id              = "ami-0e1c5d8c23330dee3"
  instance_type       = "t3.micro"
  tailscale_auth_key  = data.aws_ssm_parameter.tailscale_auth_key.value # Please don't store secrets in plain text
  monitoring_enabled  = true
  ext_security_groups = []
}
