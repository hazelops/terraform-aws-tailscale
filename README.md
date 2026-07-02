# Terraform AWS Tailscale Module
This module deploys a [Tailscale](https://tailscale.com) subnet router on AWS using an Auto Scaling Group and launch template. Instances authenticate directly with Tailscale using an OAuth client secret.

## Usage

_Please refer to [Tailscale Configuration](#tailscale-configuration) first._

```terraform
data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name = "/${var.env}/global/tailscale_oauth_client_secret"
}

module "tailscale" {
  source  = "registry.terraform.io/hazelops/tailscale/aws"
  version = "~> 3.0"

  env                           = "prod"
  vpc_id                        = "vpc-0000000"
  subnets                       = ["subnet-aaa0001", "subnet-bbb0002"] # Two AZs for HA
  allowed_cidr_blocks           = ["10.0.0.0/16"]
  ec2_key_pair_name             = "default-key"
  tailscale_oauth_client_secret = data.aws_ssm_parameter.tailscale_oauth_client_secret.value

  asg = {
    min_size = 2
    max_size = 2
  }
}
```

More examples can be found in the [examples directory](./examples).

## Tailscale Configuration

### 1. Create an OAuth client

Go to the [Tailscale Admin Console](https://login.tailscale.com/admin/settings/oauth) → **Settings** → **OAuth clients** → **Generate OAuth client**.

Set the scope to **Auth Keys — Write** and select the tags used by the module (e.g. `tag:<your-environment>`).

Save the **Client Secret** — this is the only credential the module needs.

### 2. Store credentials in SSM Parameter Store

```bash
aws ssm put-parameter \
  --name "/<env>/global/tailscale_oauth_client_secret" \
  --type "SecureString" \
  --value "<your-client-secret>"
```

### 3. Configure the ACL

Add the tag and `autoApprovers` to your [ACL policy](https://login.tailscale.com/admin/acls/file):

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ],
  "tagOwners": {
    "tag:<your-environment>": []
  },
  "autoApprovers": {
    "routes": {
      "10.0.0.0/16": ["tag:<your-environment>"]
    }
  }
}
```

With `autoApprovers` configured, advertised routes are approved automatically — no manual approval in the admin console is needed.

**The tag must be added to the ACL to disable automatic key expiration.**

More info on tags: [Tailscale ACL Tags](https://tailscale.com/kb/1068/acl-tags#defining-a-tag).

## High Availability

Running two instances (e.g. `asg = { min_size = 2, max_size = 2 }`) in subnets across two Availability Zones provides automatic failover. Both instances advertise the same routes, and Tailscale handles failover transparently with ~15 seconds of downtime.

**Prerequisite:** `autoApprovers` must be configured in the Tailscale ACL (see [Configure the ACL](#3-configure-the-acl)). Without it, routes require manual approval and failover will not work automatically.

**Recovery cycle:** When one instance fails, Tailscale switches traffic to the surviving instance. The ASG detects the failure and launches a replacement. The new instance automatically joins the Tailnet, advertises the same routes, and becomes the standby node — restoring the HA pair without manual intervention.

**Updates:** The module adjusts rolling update behaviour based on `asg.min_size`. With a single instance (`min_size = 1`), the replacement is launched first and the old instance is terminated only after the new one is healthy — this temporarily runs two instances to avoid downtime. With two instances (`min_size = 2`), they are replaced one at a time so at least one is always active.

## Datadog Monitoring (Optional)

Enable Datadog Agent with a custom Tailscale health check:

```terraform
module "tailscale" {
  # ... other variables ...
  datadog_enabled = true
  datadog_api_key = var.datadog_api_key
}
```

This installs Datadog Agent 7 and a custom check that emits:

- `tailscale.self.online` (gauge, 0/1)
- `tailscale.peers.count` (gauge)
- `tailscale.peers.online` / `tailscale.peers.direct` / `tailscale.peers.relayed` (gauges) — tailnet-wide aggregates
- `tailscale.peer.online` / `tailscale.peer.rx_bytes` / `tailscale.peer.tx_bytes` / `tailscale.peer.direct` / `tailscale.peer.last_handshake_age_seconds` (gauges, tagged `peer:<hostname>`)
- `tailscale.routes.primary_count` (gauge) — subnets this node serves as primary subnet router (approved and active)
- `tailscale.health.issues` (gauge) — total count of Tailscale health messages
- `tailscale.up` (service check)

### Service check states

The `tailscale.up` service check distinguishes real failures from benign health
warnings, so it does not page on issues that are normal for a subnet router:

| Node state | Health messages | `tailscale.up` |
|------------|-----------------|----------------|
| Online | none | `OK` |
| Online | only benign (e.g. "advertising routes but `--accept-routes` is false") | `OK` |
| Online | real issue present (e.g. DERP region unreachable) | `WARNING` (message lists the real issues only) |
| Offline | any | `CRITICAL` |

Benign messages are filtered out before evaluation, so a subnet router that
advertises routes without accepting others' does not trigger a false alert.
`tailscale.health.issues` still reports the **total** count of health messages
(including benign ones) for dashboard visibility.

## Migrating from v2.x

1. Remove `api_token` from your module call and replace with `tailscale_oauth_client_secret`.
2. Drop the orphaned auth key from state (the Tailscale provider is no longer part of the module):
   ```shell
   terraform state rm module.tailscale.tailscale_tailnet_key.this
   ```
3. Revoke the old auth key in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines).
4. Run `terraform init -upgrade` then `terraform plan` — expect only a launch template update followed by an instance refresh.

## Security

### IMDSv2

The launch template enforces IMDSv2 (`http_tokens = required`). This prevents unauthenticated access to the instance metadata endpoint (`http://169.254.169.254`), where EC2 user-data is served. Without IMDSv2, any process on the instance can retrieve user-data — including the Tailscale OAuth secret and Datadog API key — with a plain HTTP GET. IMDSv2 requires a session token obtained via a PUT request first, which blocks the most common SSRF-based metadata theft patterns.


<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=4.30.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=4.30.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_autoscaling_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group) | resource |
| [aws_iam_instance_profile.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | List of network subnets that are allowed. According to PCI-DSS, CIS AWS and SOC2 providing a default wide-open CIDR is not secure. | `list(string)` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used. One might want to lock this down to avoid unexpected upgrades. | `string` | `""` | no |
| <a name="input_asg"></a> [asg](#input\_asg) | Scaling settings of an Auto Scaling Group | `object({ min_size = number, max_size = number })` | `{ min_size = 1, max_size = 1 }` | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key (required if datadog\_enabled is true) | `string` | `""` | no |
| <a name="input_datadog_enabled"></a> [datadog\_enabled](#input\_datadog\_enabled) | Whether to enable Datadog Agent monitoring on the Tailscale instance | `bool` | `false` | no |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | EC2 key pair name to use for Tailscale instance | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name (typically dev/prod) | `string` | n/a | yes |
| <a name="input_ext_security_groups"></a> [ext\_security\_groups](#input\_ext\_security\_groups) | External security groups to add to the Tailscale instance | `list(any)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Type of Tailscale instance | `string` | `"t4g.nano"` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Whether to enable monitoring for the Auto Scaling Group | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for Tailscale instance | `string` | `"tailscale-router"` | no |
| <a name="input_public_ip_enabled"></a> [public\_ip\_enabled](#input\_public\_ip\_enabled) | Whether to enable a public IP for Tailscale instance | `bool` | `false` | no |
| <a name="input_ssm_role_arn"></a> [ssm\_role\_arn](#input\_ssm\_role\_arn) | SSM policy ARN to attach to the Tailscale instance IAM role | `string` | `"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets where the Tailscale instance will be placed. It is recommended to use a private subnet for better security. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS tags for the Tailscale instance | `map(string)` | `{}` | no |
| <a name="input_tailscale_oauth_client_secret"></a> [tailscale\_oauth\_client\_secret](#input\_tailscale\_oauth\_client\_secret) | Tailscale OAuth client secret | `string` | n/a | yes |
| <a name="input_tailscale_tags"></a> [tailscale\_tags](#input\_tailscale\_tags) | List of Tailscale tags for the Tailnet device. It would be automatically tagged when it is authenticated with this key | `list(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the Tailscale instance will be placed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_id"></a> [autoscaling\_group\_id](#output\_autoscaling\_group\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
<!-- END_TF_DOCS -->
