output "security_group_id" {
  value = aws_security_group.this.id
}

output "autoscaling_group_id" {
  value = aws_autoscaling_group.this.id
}

output "name" {
  value = local.name
}
