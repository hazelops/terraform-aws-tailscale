# Tailscale autoscaling group
resource "aws_autoscaling_group" "this" {
  name                = local.name
  vpc_zone_identifier = var.subnets
  min_size            = var.asg["min_size"]
  max_size            = var.asg["max_size"]
  launch_template {
    id      = aws_launch_template.this.id
    version = aws_launch_template.this.latest_version
  }

  instance_refresh {
    strategy = "Rolling"
    preferences {
      min_healthy_percentage = var.asg["min_size"] > 1 ? 50 : 0
      max_healthy_percentage = var.asg["min_size"] > 1 ? 150 : 200
    }
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
  user_data = base64encode(templatefile("${path.module}/templates/ec2_user_data.tpl.yml", {
    oauth_client_secret = var.tailscale_oauth_client_secret
    advertise_routes    = join(",", var.allowed_cidr_blocks)
    advertise_tags      = join(",", distinct(concat(["tag:${var.env}"], var.tailscale_tags)))
    hostname            = local.name
    datadog_enabled     = var.datadog_enabled
    datadog_api_key     = var.datadog_api_key
    env                 = var.env
  }))
  update_default_version = true
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
  }
  monitoring {
    enabled = var.monitoring_enabled
  }
  network_interfaces {
    associate_public_ip_address = var.public_ip_enabled
    security_groups             = concat(var.ext_security_groups, [aws_security_group.this.id])
  }
  tags = merge({
    Name      = local.name
    TailScale = "true"
  }, var.tags)

  lifecycle {
    precondition {
      condition     = !var.datadog_enabled || var.datadog_api_key != ""
      error_message = "datadog_api_key is required when datadog_enabled is true."
    }
  }

  tag_specifications {
    resource_type = "instance"
    tags = merge({
      Name      = local.name
      TailScale = "true"
    }, var.tags)
  }
}
