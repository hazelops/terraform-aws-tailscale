# Generate Tailscale auth key
resource "tailscale_tailnet_key" "this" {
  reusable      = var.key_reusable
  ephemeral     = var.key_ephemeral
  preauthorized = var.key_preauthorized
  expiry        = var.key_expiry
  tags          = local.tags
}
