# Terraform AWS Tailscale Module
This module deploys a [Tailscale](https://tailscale.com) subnet router on AWS using an Auto Scaling Group and launch template. It authenticates via the Tailscale Terraform provider using an OAuth client and generates an auth key for the instance automatically.

## Usage

_Please refer to [Tailscale Configuration](#tailscale-configuration) first._

```terraform
data "aws_ssm_parameter" "tailscale_oauth_client_id" {
  name = "/${var.env}/global/tailscale_oauth_client_id"
}

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
  tailscale_oauth_client_id     = data.aws_ssm_parameter.tailscale_oauth_client_id.value
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

Save the **Client ID** and **Client Secret**.

### 2. Store credentials in SSM Parameter Store

Create two SSM parameters (SecureString recommended for the secret):

```bash
aws ssm put-parameter \
  --name "/<env>/global/tailscale_oauth_client_id" \
  --type "String" \
  --value "<your-client-id>"

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
- `tailscale.health.issues` (gauge)
- `tailscale.up` (service check, OK or CRITICAL)

## Troubleshooting

The following error may occur during module removal:

```text
Error: Provider configuration not present

To work with module.tailscale.tailscale_tailnet_key.this (orphan) its
original provider configuration at
module.tailscale.provider["registry.terraform.io/tailscale/tailscale"] is
required, but it has been removed. This occurs when a provider
configuration is removed while objects created by that provider still exist
in the state. Re-add the provider configuration to destroy
module.tailscale.tailscale_tailnet_key.this (orphan), after which you can
remove the provider configuration again.
```

To remove it, run the following code:

```shell
terraform state rm module.tailscale.tailscale_tailnet_key.this
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >=1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >=4.30.0 |
| <a name="requirement_tailscale"></a> [tailscale](#requirement\_tailscale) | ~> 0.29 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=4.30.0 |
| <a name="provider_tailscale"></a> [tailscale](#provider\_tailscale) | ~> 0.29 |

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
| [tailscale_tailnet_key.this](https://registry.terraform.io/providers/tailscale/tailscale/latest/docs/resources/tailnet_key) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | List of network subnets that are allowed. According to PCI-DSS, CIS AWS and SOC2 providing a default wide-open CIDR is not secure. | `list(string)` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used. One might want to lock this down to avoid unexpected upgrades. | `string` | `""` | no |
| <a name="input_asg"></a> [asg](#input\_asg) | Scaling settings of an Auto Scaling Group | `map(any)` | <pre>{<br>  "max_size": 1,<br>  "min_size": 1<br>}</pre> | no |
| <a name="input_datadog_api_key"></a> [datadog\_api\_key](#input\_datadog\_api\_key) | Datadog API key (required if datadog\_enabled is true) | `string` | `""` | no |
| <a name="input_datadog_enabled"></a> [datadog\_enabled](#input\_datadog\_enabled) | Whether to enable Datadog Agent monitoring on the Tailscale instance | `bool` | `false` | no |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | EC2 key pair name to use for Tailscale instance | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name (typically dev/prod) | `string` | n/a | yes |
| <a name="input_ext_security_groups"></a> [ext\_security\_groups](#input\_ext\_security\_groups) | External security groups to add to the Tailscale instance | `list(any)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Type of Tailscale instance | `string` | `"t4g.nano"` | no |
| <a name="input_key_ephemeral"></a> [key\_ephemeral](#input\_key\_ephemeral) | Indicates whether the key is ephemeral | `bool` | `true` | no |
| <a name="input_key_expiry"></a> [key\_expiry](#input\_key\_expiry) | Expiry of the key in seconds. Defaults to 7776000 (90 days) | `number` | `7776000` | no |
| <a name="input_key_preauthorized"></a> [key\_preauthorized](#input\_key\_preauthorized) | Determines whether or not the machines authenticated by the key will be authorized for the Tailnet by default | `bool` | `true` | no |
| <a name="input_key_reusable"></a> [key\_reusable](#input\_key\_reusable) | Indicates whether the key is reusable | `bool` | `true` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Whether to enable monitoring for the Auto Scaling Group | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for Tailscale instance | `string` | `"tailscale-router"` | no |
| <a name="input_public_ip_enabled"></a> [public\_ip\_enabled](#input\_public\_ip\_enabled) | Whether to enable a public IP for Tailscale instance | `bool` | `false` | no |
| <a name="input_ssm_role_arn"></a> [ssm\_role\_arn](#input\_ssm\_role\_arn) | SSM policy ARN to attach to the Tailscale instance IAM role | `string` | `"arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets where the Tailscale instance will be placed. It is recommended to use a private subnet for better security. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS tags for the Tailscale instance | `map(string)` | `{}` | no |
| <a name="input_tailscale_oauth_client_id"></a> [tailscale\_oauth\_client\_id](#input\_tailscale\_oauth\_client\_id) | Tailscale OAuth client ID | `string` | n/a | yes |
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
