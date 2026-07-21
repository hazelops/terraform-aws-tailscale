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
  description = "Subnets where the Tailscale instance will be placed. It is recommended to use a private subnet for better security."
}

variable "ami_id" {
  type        = string
  description = "Optional AMI ID for Tailscale instance. Otherwise the latest Amazon Linux 2023 AMI will be used. One might want to lock this down to avoid unexpected upgrades. Must be an Amazon Linux 2023 (or AL2023-derived) AMI: the module's cloud-init content assumes a yum/dnf-based OS, and root-volume encryption (see ebs_encrypted) assumes a /dev/xvda root device."
  default     = ""
}

variable "name" {
  type        = string
  default     = "tailscale-router"
  description = "Name for Tailscale instance"
}

variable "instance_type" {
  type        = string
  default     = "t4g.nano"
  description = "Type of Tailscale instance"
}

variable "public_ip_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable a public IP for Tailscale instance"
}

variable "ext_security_groups" {
  type        = list(any)
  default     = []
  description = "External security groups to add to the Tailscale instance"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  description = "List of network subnets that are allowed. According to PCI-DSS, CIS AWS and SOC2 providing a default wide-open CIDR is not secure."
  validation {
    condition     = length(var.allowed_cidr_blocks) > 0
    error_message = "allowed_cidr_blocks must contain at least one CIDR block."
  }
}

variable "ssm_role_arn" {
  type        = string
  default     = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  description = "SSM policy ARN to attach to the Tailscale instance IAM role"
}

variable "asg" {
  type = object({
    min_size = number
    max_size = number
  })
  default = {
    min_size = 1
    max_size = 1
  }
  description = "Scaling settings of an Auto Scaling Group"
}

variable "ebs_encrypted" {
  type        = bool
  default     = true
  description = "Whether to encrypt the root EBS volume using the AWS-managed EBS key (alias/aws/ebs)"
}

variable "monitoring_enabled" {
  type        = bool
  default     = true
  description = "Whether to enable monitoring for the Auto Scaling Group"
}

variable "tailscale_oauth_client_secret" {
  type        = string
  sensitive   = true
  description = "Tailscale OAuth client secret"
}

variable "tailscale_tags" {
  type        = list(string)
  default     = []
  description = "List of Tailscale tags for the Tailnet device. It would be automatically tagged when it is authenticated with this key"
}

variable "exit_node_enabled" {
  type        = bool
  default     = false
  description = "Whether to advertise this instance as a Tailscale exit node (--advertise-exit-node), allowing tailnet traffic to be routed through it"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "AWS tags for the Tailscale instance"
}

variable "datadog_enabled" {
  type        = bool
  default     = false
  description = "Whether to enable Datadog Agent monitoring on the Tailscale instance"
}

variable "datadog_api_key" {
  type        = string
  default     = ""
  sensitive   = true
  description = "Datadog API key (required if datadog_enabled is true)"
}
