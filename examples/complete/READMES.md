<!-- BEGIN_TF_DOCS -->
examples/complete/main.tf

Exercises the whole surface: a customer-managed KMS key, access logging to an existing
log bucket, a custom retention window, and a managed IAM policy built from the module's
own state\_access\_policy\_json, ready to attach to a CI role.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.67.0 |

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_state_backend"></a> [state\_backend](#module\_state\_backend) | ../../ | n/a |

## Resources

| Name | Type |
| ---- | ---- |
| [aws_iam_policy.terraform_state](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of an existing customer-managed KMS key to encrypt state with. | `string` | n/a | yes |
| <a name="input_log_bucket_name"></a> [log\_bucket\_name](#input\_log\_bucket\_name) | Name of an existing bucket, in the same region, that accepts S3 server access logs. | `string` | n/a | yes |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Backend block to paste into other configurations. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the state bucket, for backend blocks. |
| <a name="output_state_access_policy_arn"></a> [state\_access\_policy\_arn](#output\_state\_access\_policy\_arn) | ARN of the managed policy to attach to roles that run Terraform. |
<!-- END_TF_DOCS -->