# Generate Tailscale auth key
resource "tailscale_tailnet_key" "this" {
  reusable      = var.tailscale_key_reusable
  ephemeral     = var.tailscale_key_ephemeral
  preauthorized = var.tailscale_key_preauthorized
  expiry        = var.tailscale_key_expiry
  tags          = local.tags
}
