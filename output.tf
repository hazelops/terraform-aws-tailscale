output "security_group_id" {
  value = element(aws_security_group.this.*.id, 0)
}

output "autoscaling_group_id" {
  value = aws_autoscaling_group.this.id
}

output "name" {
  value = local.name
}
