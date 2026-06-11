# Changelog

## 3.0.0 (2026-06-11)

### Breaking Changes

- **OAuth authentication required.** The `api_token` variable has been removed.
  The module now uses `tailscale_oauth_client_id` and `tailscale_oauth_client_secret`
  for provider authentication.

### Migration Steps

1. Create an OAuth client in the Tailscale Admin Console:
   Admin Console → Settings → OAuth clients → Generate OAuth client.
   Scope: `auth_keys` — Write. Select the tags used by the module (e.g. `tag:<env>`).
2. Store the OAuth client ID and secret in AWS SSM Parameter Store
   (e.g. `/<env>/global/tailscale_oauth_client_id` and `/<env>/global/tailscale_oauth_client_secret`).
3. Update your module call: replace `api_token` with `tailscale_oauth_client_id`
   and `tailscale_oauth_client_secret`.
4. Run `terraform init -upgrade` to pull the updated tailscale provider.
5. Run `terraform plan` to verify — expect no destructive changes to infrastructure
   (the ASG and launch template remain unchanged).
6. Revoke the old Tailscale API token.

### Features

- **Fix ASG min/max bug.** `min_size` and `max_size` were swapped — corrected.
- **HA support.** Set `asg = { min_size = 2, max_size = 2 }` with subnets in two AZs
  for automatic failover (~15s).
- **Optional Datadog monitoring.** Set `datadog_enabled = true` and
  `datadog_api_key` to install Datadog Agent with a custom Tailscale
  health check (gauges: `tailscale.self.online`, `tailscale.peers.count`,
  `tailscale.health.issues`; service check: `tailscale.up`).
- Tailscale provider updated to `~> 0.29`.

### Internal

- Simplified output syntax.
- Updated examples for v3.
- Fixed Tailscale yum repo URL to match Amazon Linux 2023 AMI.
- Fixed `ssm_role_arn` default: replaced deprecated `AmazonEC2RoleforSSM` with `AmazonSSMManagedInstanceCore`.
