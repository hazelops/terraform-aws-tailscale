# Terraform AWS Tailscale Module
This module is used to deploy a [Tailscale powered image](https://tailscale.com) to create access from VPC to the Tailscale Cloud.

## Security & Compliance [<img src="https://bridgecrew.io/wp-content/themes/bridgecrew/assets/images/bc-by-pc-color.svg" width="250" align="right" />](https://bridgecrew.io/)

Security scanning is graciously provided by Bridgecrew.

| Benchmark | Description |
|-------|---------------|
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_azure)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+AZURE+V1.1) | Center for Internet Security, AZURE V1.1 Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_gcp)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+GCP+V1.1) | Center for Internet Security, GCP Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_kubernetes)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+KUBERNETES+V1.5) | Center for Internet Security, KUBERNETES V1.5 Compliance  |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_azure_13)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+AZURE+V1.3) | Center for Internet Security, AZURE V1.3 Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_docker_12)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+DOCKER+V1.2) | Center for Internet Security, Docker V1.2 Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_eks_11)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+EKS+V1.1) | Center for Internet Security, EKS V1.1 Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_gke_11)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+GKE+V1.1) | Center for Internet Security, GKE V1.1 Compliance |
| [![Infrastructure Tests](https://www.bridgecrew.cloud/badges/github/hazelops/terraform-aws-tailscale/cis_kubernetes_16)](https://www.bridgecrew.cloud/link/badge?vcs=github&fullRepo=hazelops%2Fterraform-aws-tailscale&benchmark=CIS+KUBERNETES+V1.6) | Center for Internet Security, KUBERNETES V1.6 Compliance |

## To deploy this module: 

  1. Create [Tailscale API access token](https://tailscale.com/kb/1252/key-secret-management#api-access-tokens)
  2. Add tag to the [ACL control list](https://login.tailscale.com/admin/acls/file). ACL should look like this:
  ```json
  {
  "acls": [
    {
      "action": "accept",
      "ports": [
        "*:*",
      ],
      "users": [
        "*",
      ],
    },
  ],
  "tagOwners": {
    "tag:<your-environment>": [],
  },
}
  ```
 **_The tag must be added to the ACL to disable automatic key expiration!_** 
 
  Default parameter for tag is `tag:server`.
 
  You could found more examples in [Tailscale manual](https://tailscale.com/kb/1068/acl-tags#defining-a-tag).

  3. Create AWS SSM Parameter using obtained Tailscale API access token. For example, use the following path pattern: `<env-name>/global/tailscale_api_token`. For more information please refer to [AWS manual](https://docs.aws.amazon.com/systems-manager/latest/userguide/parameter-create-console.html).
  4. Add data source to Terraform code like in the [example configuration main.tf file](./examples/minimum/main.tf).
  5. In the module call parameters, set `tailscale_api_token` variable like in the [example configuration main.tf file](./examples/minimum/main.tf).
  6. Alternatively Tailscale API token could be set as string, but this is very unsafe, therefore it is **_highly not recommended_** to do this.



## Possible problems on module destroy:

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
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | Optional AMI ID for Tailscale instance. Otherwise latest Amazon Linux will be used. | `string` | `""` | no |
| <a name="input_api_token"></a> [api\_token](#input\_api\_token) | Set Tailscale API access token here | `string` | n/a | yes |
| <a name="input_asg"></a> [asg](#input\_asg) | Scaling settings of an Auto Scaling Group | `map` | <pre>{<br>  "max_size": 1,<br>  "min_size": 1<br>}</pre> | no |
| <a name="input_ec2_key_pair_name"></a> [ec2\_key\_pair\_name](#input\_ec2\_key\_pair\_name) | n/a | `string` | n/a | yes |
| <a name="input_env"></a> [env](#input\_env) | n/a | `string` | n/a | yes |
| <a name="input_ext_security_groups"></a> [ext\_security\_groups](#input\_ext\_security\_groups) | External security groups to add to the Tailscale instance | `list(any)` | `[]` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | Set type of Tailscale instance | `string` | `"t3.nano"` | no |
| <a name="input_monitoring_enabled"></a> [monitoring\_enabled](#input\_monitoring\_enabled) | Enable monitoring for the Auto Scaling Group | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | Set a name for Tailscale instance | `string` | `"tailscale-router"` | no |
| <a name="input_public_ip_enabled"></a> [public\_ip\_enabled](#input\_public\_ip\_enabled) | Enable Public IP for Tailscale instance | `bool` | `false` | no |
| <a name="input_ssm_role_arn"></a> [ssm\_role\_arn](#input\_ssm\_role\_arn) | SSM role to attach to a Tailscale instance | `string` | `"arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM"` | no |
| <a name="input_subnets"></a> [subnets](#input\_subnets) | Subnets where the Taiscale instance will be placed. It is recommended to use a private subnet for better security. | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | A device is automatically tagged when it is authenticated with this key | `list(string)` | `[]` | no |
| <a name="input_tailscale_key_ephemeral"></a> [tailscale\_key\_ephemeral](#input\_tailscale\_key\_ephemeral) | Indicates if the key is ephemeral | `bool` | `true` | no |
| <a name="input_tailscale_key_expiry"></a> [tailscale\_key\_expiry](#input\_tailscale\_key\_expiry) | The expiry of the key in seconds. Defaults to 7776000 (90 days) | `number` | `7776000` | no |
| <a name="input_tailscale_key_preauthorized"></a> [tailscale\_key\_preauthorized](#input\_tailscale\_key\_preauthorized) | Determines whether or not the machines authenticated by the key will be authorized for the tailnet by default | `bool` | `true` | no |
| <a name="input_tailscale_key_reusable"></a> [tailscale\_key\_reusable](#input\_tailscale\_key\_reusable) | Indicates if the key is reusable or single-use | `bool` | `true` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | n/a | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_autoscaling_group_id"></a> [autoscaling\_group\_id](#output\_autoscaling\_group\_id) | n/a |
| <a name="output_name"></a> [name](#output\_name) | n/a |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | n/a |
