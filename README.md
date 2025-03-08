# Terraform AWS Tailscale Module
This module is used to deploy a [Tailscale](https://tailscale.com) router instance to set up access from VPC to the
Tailscale Cloud.

Module logic is the following:
1. Connect to TailScale API using the Terraform Provider and Tailscale api token.
2. Generate TailScale Auth Key and place it into the instance.
3. Create an Autoscale Group with a single instance using and connect it to the TailScale network.

## Usage

_Please refer to [Tailscale Configuration](#tailscale-configuration) first_

```terraform
module "tailscale" {
  source            = "registry.terraform.io/hazelops/tailscale/aws"
  version           = "~>0.2"
  allowed_cidr_blocks = ["0.0.0.0/0"] # Please lock this down to your specific CIDR
  ec2_key_pair_name = "default-key"
  env               = "prod"
  subnets           = ["subnet-0000000", "subnet-0000000"]
  vpc_id            = "vpc-0000000"
  api_token         = "00000000000000000000000000" # Please don't store secrets in plain text
}

```
More examples can be found in the [examples directory](./examples).

## Tailscale Configuration

1. Create [Tailscale API access token](https://login.tailscale.com/admin/settings/keys) (More info on Access tokens can be found [here](https://tailscale.com/kb/1083/acl-tags#access-tokens)
2. Add tag to the [ACL control list](https://login.tailscale.com/admin/acls/file). ACL should look like this:
  ```json
  {
  "acls": [
    {
      "action": "accept",
      "ports": [
        "*:*"
      ],
      "users": [
        "*"
      ]
    }
  ],
  "tagOwners": {
    "tag:<your-environment>": []
  }
}
```

Make sure to approve the advertised route:
1. Go to [Machines](https://login.tailscale.com/admin/machines) page
2. Find the machine and click on the `...` button.
3. Select "Edit route settings", check the checkbox and then click "Save".

**_The tag must be added to the ACL to disable automatic key expiration!_**

Default parameter for tag is `tag:<your-environment>`.

More examples can be found in [Tailscale Tag Docs](https://tailscale.com/kb/1068/acl-tags#defining-a-tag).

3. Create AWS SSM Parameter using the obtained Tailscale API access token. For example, use the following path
   pattern: `<env-name>/global/tailscale_api_token`. For more information please refer
   to [AWS Docs](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-create-console.html).
4. Add data source to Terraform code like in the [example configuration main.tf file](./examples/minimum/main.tf).
5. In the module call parameters, set `api_token` variable like in
   the [example configuration main.tf file](./examples/minimum/main.tf).
6. Alternatively Tailscale API token could be set as string, but this is very unsafe, therefore it is *
   *_highly not recommended_** to do this.

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
| <a name="requirement_local"></a> [local](#requirement\_local) | ~> 1.2 |
| <a name="requirement_tailscale"></a> [tailscale](#requirement\_tailscale) | 0.13.13 |
| <a name="requirement_template"></a> [template](#requirement\_template) | >=2.2 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >=4.30.0 |
| <a name="provider_tailscale"></a> [tailscale](#provider\_tailscale) | 0.13.13 |
| <a name="provider_template"></a> [template](#provider\_template) | >=2.2 |

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
| [tailscale_tailnet_key.this](https://registry.terraform.io/providers/tailscale/tailscale/0.13.13/docs/resources/tailnet_key) | resource |
| [aws_ami.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_iam_policy_document.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [template_file.ec2_user_data](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allowed_cidr_blocks"></a> [allowed\_cidr\_blocks](#input\_allowed\_cidr\_blocks) | List of network subnets that are allowed. According to PCI-DSS, CIS AWS and SOC2 providing a default wide-open CIDR is not secure. | `list(string)` | n/a | yes |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used. One might want to lock this down to avoid unexpected upgrades. | `string` | `""` | no |
| <a name="input_api_token"></a> [api\_token](#input\_api\_token) | Tailscale API access token | `string` | n/a | yes |
| <a name="input_asg"></a> [asg](#input\_asg) | Scaling settings of an Auto Scaling Group | `map(any)` | <pre>{<br/>  "max_size": 1,<br/>  "min_size": 1<br/>}</pre> | no |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | EC2 key pair name to use for Tailscale instance | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | Environment name (typically dev/prod) | `string` | n/a | yes |
| <a name="input_ext_security_groups"></a> [ext\_security\_groups](#input\_ext\_security\_groups) | External security groups to add to the Tailscale instance | `list(any)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Type of Tailscale instance | `string` | `"t3.nano"` | no |
| <a name="input_key_ephemeral"></a> [key\_ephemeral](#input\_key\_ephemeral) | Indicates whether the key is ephemeral | `bool` | `true` | no |
| <a name="input_key_expiry"></a> [key\_expiry](#input\_key\_expiry) | Expiry of the key in seconds. Defaults to 7776000 (90 days) | `number` | `7776000` | no |
| <a name="input_key_preauthorized"></a> [key\_preauthorized](#input\_key\_preauthorized) | Determines whether or not the machines authenticated by the key will be authorized for the Tailnet by default | `bool` | `true` | no |
| <a name="input_key_reusable"></a> [key\_reusable](#input\_key\_reusable) | Indicates whether the key is reusable | `bool` | `true` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Whether to enable monitoring for the Auto Scaling Group | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for Tailscale instance | `string` | `"tailscale-router"` | no |
| <a name="input_public_ip_enabled"></a> [public\_ip\_enabled](#input\_public\_ip\_enabled) | Wheter to enable a public IP for Tailscale instance | `bool` | `false` | no |
| <a name="input_ssm_role_arn"></a> [ssm\_role\_arn](#input\_ssm\_role\_arn) | SSM role to attach to a Tailscale instance | `string` | `"arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets where the Taiscale instance will be placed. It is recommended to use a private subnet for better security. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | AWS tags for the Tailscale instance | `map(string)` | `{}` | no |
| <a name="input_tailscale_tags"></a> [tailscale\_tags](#input\_tailscale\_tags) | List of Tailscale tags for the Tailnet device. It would be automatically tagged when it is authenticated with this key | `set(string)` | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the Tailscale instance will be placed | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_id"></a> [autoscaling\_group\_id](#output\_autoscaling\_group\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
<!-- END_TF_DOCS -->
