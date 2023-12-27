# Generate Tailscale auth key
resource "tailscale_tailnet_key" "this" {
  reusable      = true
  ephemeral     = true
  preauthorized = true
  expiry        = var.tailscale_key_expiry
  tags          = var.tailscale_tags
}
