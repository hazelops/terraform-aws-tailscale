locals {
  name = "${var.env}-${var.name}"
  tags = concat(["tag:${var.env}"], var.tags)
}
