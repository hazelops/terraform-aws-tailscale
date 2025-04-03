locals {
  name = "${var.env}-${var.name}"
  instance_arch = can(regex("\\w\\dg\\..*", var.instance_type)) ? "arm64" : "x86_64"
}
