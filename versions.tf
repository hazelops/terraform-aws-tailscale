terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = ">=4.30.0"
    }
    template = {
      source  = "hashicorp/template"
      version = ">=2.2"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 1.2"
    }
  }
  required_version = ">=1.2.0"
}
