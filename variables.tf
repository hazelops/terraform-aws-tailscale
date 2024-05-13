variable "env" {
  type        = string
  description = "Environment name (typically dev/prod)"
}
variable "vpc_id" {
  type        = string
  description = "VPC ID where the Tailscale instance will be placed"
}

variable "ec2_key_pair_name" {
  type        = string
  description = "EC2 key pair name to use for Tailscale instance"
}

variable "subnets" {
  type        = list(string)
  description = "Subnets where the Taiscale instance will be placed. It is recommended to use a private subnet for better security."
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used. One might want to lock this down to avoid unexpected upgrades."
  default     = ""
}

variable "name" {
  type        = string
  default     = "tailscale-router"
  description = "Name for Tailscale instance"
}

variable "instance_type" {
  type        = string
  default     = "t3.nano"
  description = "Type of Tailscale instance"
}

variable "public_ip_enabled" {
  type        = bool
  default     = false
  description = "Wheter to enable a public IP for Tailscale instance"
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
  type = map(any)
  default = {
    min_size = 1
    max_size = 1
  }
  description = "Scaling settings of an Auto Scaling Group"
}

variable "monitoring_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable monitoring for the Auto Scaling Group"
}

variable "api_token" {
  type        = string
  description = "Tailscale API access token"
}

variable "key_expiry" {
  type        = number
  default     = 7776000
  description = "Expiry of the key in seconds. Defaults to 7776000 (90 days)"
}

variable "key_reusable" {
  type        = bool
  default     = true
  description = "Indicates whether the key is reusable"
}

variable "key_ephemeral" {
  type        = bool
  default     = true
  description = "Indicates whether the key is ephemeral"
}

variable "key_preauthorized" {
  type        = bool
  default     = true
  description = "Determines whether or not the machines authenticated by the key will be authorized for the Tailnet by default"
}

variable "tags" {
  type        = list(string)
  default     = []
  description = "List of tags for the Tailnet device. It would be automatically tagged when it is authenticated with this key"
}
