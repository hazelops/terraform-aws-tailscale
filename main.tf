# Tailscale autoscaling group
resource "aws_autoscaling_group" "this" {
  name                = local.name
  vpc_zone_identifier = var.subnets
  min_size            = var.asg["max_size"]
  max_size            = var.asg["min_size"]
  launch_template {
    id = aws_launch_template.this.id
  }
  tag {
    key                 = "Name"
    value               = local.name
    propagate_at_launch = true
  }
}

# Tailscale launch template
resource "aws_launch_template" "this" {
  name = local.name
  iam_instance_profile {
    name = aws_iam_instance_profile.this.name
  }
  image_id                             = var.ami_id != "" ? var.ami_id : join("", data.aws_ami.this.*.id)
  instance_initiated_shutdown_behavior = "terminate"
  instance_type                        = var.instance_type
  key_name                             = var.ec2_key_pair_name
  user_data                            = base64encode(data.template_file.ec2_user_data.rendered)
  update_default_version               = true
  monitoring {
    enabled = var.monitoring_enabled
  }
  network_interfaces {
    associate_public_ip_address = var.public_ip_enabled
    security_groups             = concat(var.ext_security_groups, [aws_security_group.this.id])
  }
  tags = merge({
    Name      = local.name
    TailScale = "enabled"
  }, var.tags)
}

# Tailscale key
resource "tailscale_tailnet_key" "this" {
  reusable      = var.key_reusable
  ephemeral     = var.key_ephemeral
  preauthorized = var.key_preauthorized
  expiry        = var.key_expiry
  tags          = concat(["tag:${var.env}"], var.tailscale_tags)
}
