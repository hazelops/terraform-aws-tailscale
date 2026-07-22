variable "env" {}
variable "vpc_id" {}
variable "subnets" {}
variable "vpc_cidr_block" {}
variable "aws_key_name" {}

data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name = "/${var.env}/global/tailscale_oauth_client_secret"
}

module "tailscale" {
  source                        = "registry.terraform.io/hazelops/tailscale/aws"
  version                       = "~> 3.1"
  allowed_cidr_blocks           = [var.vpc_cidr_block]
  ec2_key_pair_name             = var.aws_key_name
  env                           = var.env
  subnets                       = var.subnets
  vpc_id                        = var.vpc_id
  tailscale_oauth_client_secret = data.aws_ssm_parameter.tailscale_oauth_client_secret.value
}
