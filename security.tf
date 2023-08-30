# Security Groups
resource "aws_security_group" "this" {
  name        = local.name
  description = "Security Group for Tailscale connector"
  vpc_id      = var.vpc_id

  ingress {
    description = "Allow all ingress traffic"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = var.allowed_cidr_blocks
  }

  egress {
    description = "Allow all egress traffic"
    protocol    = -1
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = local.name
  }

  lifecycle {
    create_before_destroy = true
  }
}
