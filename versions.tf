terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">=4.30.0"
    }
    tailscale = {
      source  = "tailscale/tailscale"
      version = "0.18"
    }
  }
  required_version = ">=1.2.0"
}
