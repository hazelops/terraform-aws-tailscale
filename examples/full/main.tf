variable "env" {}
variable "vpc_id" {}
variable "subnets" {}
variable "vpc_cidr_block" {}
variable "aws_key_name" {}
variable "datadog_api_key" { default = "" }

data "aws_ssm_parameter" "tailscale_oauth_client_id" {
  name = "/${var.env}/global/tailscale_oauth_client_id"
}

data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name = "/${var.env}/global/tailscale_oauth_client_secret"
}

module "tailscale" {
  source                        = "registry.terraform.io/hazelops/tailscale/aws"
  version                       = "~> 3.0"
  name                          = "tailscale-router"
  allowed_cidr_blocks           = [var.vpc_cidr_block]
  ec2_key_pair_name             = var.aws_key_name
  env                           = var.env
  subnets                       = var.subnets
  vpc_id                        = var.vpc_id
  public_ip_enabled             = true
  instance_type                 = "t4g.nano"
  tailscale_oauth_client_id     = data.aws_ssm_parameter.tailscale_oauth_client_id.value
  tailscale_oauth_client_secret = data.aws_ssm_parameter.tailscale_oauth_client_secret.value
  monitoring_enabled            = true
  ext_security_groups           = []
  asg = {
    min_size = 2
    max_size = 2
  }
  tailscale_tags = ["tag:server"]
  tags = {
    Team = "infrastructure"
  }
  key_expiry        = 7776000
  key_reusable      = true
  key_ephemeral     = true
  key_preauthorized = true
  datadog_enabled   = true
  datadog_api_key   = var.datadog_api_key
}
