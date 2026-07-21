# Terraform AWS Tailscale Module
This module deploys a [Tailscale](https://tailscale.com) subnet router on AWS using an Auto Scaling Group and launch template. Instances authenticate directly with Tailscale using an OAuth client secret.

## Tailscale Configuration

⚠️ **Do this before deploying.**

Please complete the following steps before running `terraform apply` for the first time:

1. [Configure the ACL](#1-configure-the-acl)
2. [Create an OAuth client](#2-create-an-oauth-client)

Otherwise the OAuth client can't be scoped to the right tag, and advertised routes get stuck pending instead of auto-propagating (see step 1 for why).

### 1. Configure the ACL

Do this step **first**, before creating the OAuth client. Two things depend on it:

- An OAuth client scoped to `auth_keys` (used in step 2) can only be assigned an existing tag — a tag that doesn't exist yet cannot be selected.
- `autoApprovers` only applies to route advertisements Tailscale receives *after* it's configured. Updating it later does not retroactively approve routes that are already pending — if the ACL isn't in place before the instance's first `terraform apply`, its advertised route will get stuck pending and must be manually removed and re-advertised.

1. Open the [Access Controls](https://login.tailscale.com/admin/acls) page in the Tailscale Admin Console.
2. In the JSON editor, merge the following keys into the **existing** policy file — most tailnets already have other rules in place, so add to it rather than replacing the whole file:

```json
{
  "tagOwners": {
    "tag:<environment>": []
  },
  "autoApprovers": {
    "routes": {
      "10.0.0.0/16": ["tag:<environment>"]
    }
  }
}
```

3. Make sure the `acls` rules actually permit traffic to/from this tag, e.g.:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["*"],
      "dst": ["*:*"]
    }
  ]
}
```

4. Save.

With `autoApprovers` configured, advertised routes are approved automatically — no manual approval in the admin console is needed.

**The tag must be added to the ACL to disable automatic key expiration.**

More info on tags: [Tailscale ACL Tags](https://tailscale.com/kb/1068/acl-tags#defining-a-tag).

### 2. Create an OAuth client

In the Tailscale Admin Console: **Settings** (top nav) → **Trust credentials** (left sidebar, under Tailnet Settings) → **+ Credential** → **OAuth**.

Set the scope to **Auth Keys — Write** and select the tag created in step 1 (e.g. `tag:<environment>`).

Save the **Client Secret** — this is the only credential the module needs. See [Storing the OAuth Secret](#storing-the-oauth-secret) further down for where to put it.

## Usage

```terraform
module "tailscale" {
  source  = "registry.terraform.io/hazelops/tailscale/aws"
  version = "~> 3.1"

  env                           = "prod"
  vpc_id                        = "vpc-0000000"
  subnets                       = ["subnet-aaa0001", "subnet-bbb0002"] # Two AZs for HA
  allowed_cidr_blocks           = ["10.0.0.0/16"]
  ec2_key_pair_name             = "default-key"
  tailscale_oauth_client_secret = "ts-xxxx1234567890"

  asg = {
    min_size = 2
    max_size = 2
  }
}
```

⚠️ **Warning:** Never hardcode secrets in Terraform code. Please fetch `tailscale_oauth_client_secret` at runtime from [Secrets Manager](#secrets-manager) or [SSM Parameter Store](#ssm-parameter-store).

More examples can be found in the [examples directory](./examples).

## High Availability

Running two instances (e.g. `asg = { min_size = 2, max_size = 2 }`) in subnets across two Availability Zones provides automatic failover. Both instances advertise the same routes, and Tailscale handles failover transparently with ~15 seconds of downtime.

**Prerequisite:** `autoApprovers` must be configured in the Tailscale ACL (see [Configure the ACL](#1-configure-the-acl)). Without it, routes require manual approval and failover will not work automatically.

**Recovery cycle:** When one instance fails, Tailscale switches traffic to the surviving instance. The ASG detects the failure and launches a replacement. The new instance automatically joins the Tailnet, advertises the same routes, and becomes the standby node — restoring the HA pair without manual intervention.

**Updates:** The module adjusts rolling update behaviour based on `asg.min_size`. With a single instance (`min_size = 1`), the replacement is launched first and the old instance is terminated only after the new one is healthy — this temporarily runs two instances to avoid downtime. With two instances (`min_size = 2`), they are replaced one at a time so at least one is always active.

## Exit Node

Set `exit_node_enabled = true` to advertise this instance as a [Tailscale exit node](https://tailscale.com/kb/1103/exit-nodes), routing all tailnet traffic (not just the advertised subnet routes) through it:

```terraform
module "tailscale" {
  # ... other variables ...
  exit_node_enabled = true
}
```

Exit nodes must be approved in the Tailscale Admin Console (or via `autoApprovers.exitNode` in the ACL) before tailnet clients can select them.

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

1. Remove `api_token` from the module call and replace with `tailscale_oauth_client_secret`.
2. Drop the orphaned auth key from state (the Tailscale provider is no longer part of the module):
   ```shell
   terraform state rm module.tailscale.tailscale_tailnet_key.this
   ```
3. Revoke the old auth key in the [Tailscale Admin Console](https://login.tailscale.com/admin/machines).
4. Run `terraform init -upgrade` then `terraform plan` — expect only a launch template update followed by an instance refresh.

## Security

### IMDSv2

The launch template enforces IMDSv2 (`http_tokens = required`). This prevents unauthenticated access to the instance metadata endpoint (`http://169.254.169.254`), where EC2 user-data is served. Without IMDSv2, any process on the instance can retrieve user-data — including the Tailscale OAuth secret and Datadog API key — with a plain HTTP GET. IMDSv2 requires a session token obtained via a PUT request first, which blocks the most common SSRF-based metadata theft patterns.

### EBS Encryption

The root EBS volume is encrypted by default using the AWS-managed key (`alias/aws/ebs`) — no extra setup required. To disable:

```terraform
module "tailscale" {
  # ... other variables ...
  ebs_encrypted = false
}
```

There is no customer-supplied-KMS-key option: a customer-managed key would require granting the `AWSServiceRoleForAutoScaling` service-linked role explicit KMS permissions, which this module does not manage.

**If using a custom `ami_id`:** it must be an Amazon Linux 2023 (or AL2023-derived) AMI. The module's cloud-init content assumes a yum/dnf-based OS, and root-volume encryption assumes the AMI's root device is `/dev/xvda` — both are AL2023 defaults but are not validated by Terraform for arbitrary custom AMIs.

## Storing the OAuth Secret

`tailscale_oauth_client_secret` accepts a plain string — store the Client Secret from step 2 above wherever fits the deployment. Two options:

### SSM Parameter Store

```bash
aws ssm put-parameter \
  --name "/<env>/global/tailscale_oauth_client_secret" \
  --type "SecureString" \
  --value "<client-secret>"
```

```terraform
data "aws_ssm_parameter" "tailscale_oauth_client_secret" {
  name = "/${var.env}/global/tailscale_oauth_client_secret"
}

module "tailscale" {
  # ... other variables ...
  tailscale_oauth_client_secret = data.aws_ssm_parameter.tailscale_oauth_client_secret.value
}
```

### Secrets Manager

```bash
aws secretsmanager create-secret \
  --name "/<env>/global/tailscale_oauth_client_secret" \
  --secret-string "<client-secret>"
```

```terraform
data "aws_secretsmanager_secret_version" "tailscale_oauth_client_secret" {
  secret_id = "/${var.env}/global/tailscale_oauth_client_secret"
}

module "tailscale" {
  # ... other variables ...
  tailscale_oauth_client_secret = data.aws_secretsmanager_secret_version.tailscale_oauth_client_secret.secret_string
}
```


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
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID for Tailscale instance. Otherwise the latest Amazon Linux 2023 AMI will be used. One might want to lock this down to avoid unexpected upgrades. Must be an Amazon Linux 2023 (or AL2023-derived) AMI: the module's cloud-init content assumes a yum/dnf-based OS, and root-volume encryption (see ebs\_encrypted) assumes a /dev/xvda root device. | `string` | `""` | no |
| <a name="input_asg"></a> [asg](#input\_asg) | Scaling settings of an Auto Scaling Group | <pre>object({<br>    min_size = number<br>    max_size = number<br>  })</pre> | <pre>{<br>  "max_size": 1,<br>  "min_size": 1<br>}</pre> | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key (required if datadog\_enabled is true) | `string` | `""` | no |
| <a name="input_datadog_enabled"></a> [datadog\_enabled](#input\_datadog\_enabled) | Whether to enable Datadog Agent monitoring on the Tailscale instance | `bool` | `false` | no |
| <a name="input_ebs_encrypted"></a> [ebs\_encrypted](#input\_ebs\_encrypted) | Whether to encrypt the root EBS volume using the AWS-managed EBS key (alias/aws/ebs) | `bool` | `true` | no |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | EC2 key pair name to use for Tailscale instance | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name (typically dev/prod) | `string` | n/a | yes |
| <a name="input_exit_node_enabled"></a> [exit\_node\_enabled](#input\_exit\_node\_enabled) | Whether to advertise this instance as a Tailscale exit node (--advertise-exit-node), allowing tailnet traffic to be routed through it | `bool` | `false` | no |
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
