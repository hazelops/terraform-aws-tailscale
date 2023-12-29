variable "env" {
  type = string
}
variable "vpc_id" {
  type = string
}

variable "ec2_key_pair_name" {
  type = string
}

variable "subnets" {
  type        = list(string)
  description = "Subnets where the Taiscale instance will be placed. It is recommended to use a private subnet for better security."
}

variable "ami_id" {
  type        = string
  default     = ""
  description = "Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used."
}

variable "name" {
  type        = string
  default     = "tailscale-router"
  description = "Set a name for Tailscale instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.nano"
  description = "Set type of Tailscale instance"
}

variable "public_ip_enabled" {
  type        = bool
  default     = false
  description = "Enable Public IP for Tailscale instance"
}

variable "ext_security_groups" {
  type        = list(any)
  default     = []
  description = "External security groups to add to the Tailscale instance"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of network subnets that are allowed. According to PCI-DSS, CIS AWS and SOC2 providing a default wide-open CIDR is not secure."
}

variable "ssm_role_arn" {
  type        = string
  default     = "arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"
  description = "SSM role to attach to a Tailscale instance"
}

variable "asg" {
  default = {
    min_size = 1
    max_size = 1
  }
  description = "Scaling settings of an Auto Scaling Group"
}

variable "monitoring_enabled" {
  type        = bool
  default     = true
  description = "Enable monitoring for the Auto Scaling Group"
}

variable "api_token" {
  type        = string
  description = "Set Tailscale API access token here"
}

variable "key_expiry" {
  type        = number
  default     = 7776000
  description = "The expiry of the key in seconds. Defaults to 7776000 (90 days)"
}

variable "key_reusable" {
  type        = bool
  default     = true
  description = "Indicates if the key is reusable or single-use"
}

variable "key_ephemeral" {
  type        = bool
  default     = true
  description = "Indicates if the key is ephemeral"
}

variable "key_preauthorized" {
  type        = bool
  default     = true
  description = "Determines whether or not the machines authenticated by the key will be authorized for the tailnet by default"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "A device is automatically tagged when it is authenticated with this key"
}

locals {
  name = "${var.env}-${var.name}"
  tags = concat(["tag:${var.env}"], var.tags)
}
