# terraform-aws-state-backend

Creates the S3 bucket that holds Terraform state for an AWS account — versioned, encrypted,
private, TLS-only, and ready for S3-native state locking.

[![Terraform Registry](https://img.shields.io/badge/terraform-registry-7B42BC?logo=terraform)](https://registry.terraform.io/modules/deeowemez/state-backend/aws/latest)
[![CI](https://github.com/deeowemez/terraform-aws-state-backend/actions/workflows/ci.yml/badge.svg)](https://github.com/deeowemez/terraform-aws-state-backend/actions/workflows/ci.yml)

## What it creates

- An S3 bucket with `prevent_destroy`, `BucketOwnerEnforced` ownership and all four public
  access blocks on.
- **Versioning, always on.** It is what makes a corrupted or mistaken state recoverable.
- **SSE-KMS with Bucket Keys**, using `aws/s3` by default or your own key.
- A **lifecycle rule** that expires old state versions and the `.tflock` leftovers that
  locking produces on every run.
- A **TLS-only bucket policy**.
- A **state access policy document** (`state_access_policy_json`) scoped to this bucket,
  for you to attach to the roles that run Terraform.

No DynamoDB table: locking uses `use_lockfile = true`, which needs Terraform >= 1.10 in the
configurations that store state here.

## Usage

The configuration that creates the state bucket cannot store its own state in it. Call the
module from a small bootstrap configuration with **no backend block**, apply it once, and
commit that configuration's local `terraform.tfstate` — it describes one bucket and holds
nothing sensitive.

```hcl
module "state_backend" {
  source  = "deeowemez/state-backend/aws"
  version = "~> 0.1.0"

  bucket_name = "acme-tfstate-123456789012"
}

output "backend_config" {
  value = module.state_backend.backend_config
}
```

Every other configuration then uses:

```hcl
terraform {
  required_version = ">= 1.10.0"

  backend "s3" {
    bucket       = "acme-tfstate-123456789012"
    key          = "<stack>/terraform.tfstate" # unique per configuration
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}
```

Backend blocks cannot use variables, so `bucket` and `region` are literal. **Never reuse a
`key` across configurations** — each apply would overwrite the other's state.

## Examples

| Example | What it shows |
|---|---|
| [simple](examples/simple) | The whole of a typical bootstrap configuration |
| [complete](examples/complete) | Customer-managed KMS key, access logging, custom retention, managed IAM policy |

## Tearing it down

`prevent_destroy` is hard-coded rather than a variable: destroying this bucket destroys
the state describing every other stack. To remove it deliberately:

1. Destroy, or migrate elsewhere, every configuration whose state lives in the bucket.
2. Empty the bucket, including all versions and delete markers.
3. In the bootstrap configuration, replace the module block with a `removed` block so
   Terraform forgets the resources without destroying them, then apply:
   ```hcl
   removed {
     from = module.state_backend
     lifecycle { destroy = false }
   }
   ```
4. Delete the bucket: `aws s3api delete-bucket --bucket <name>`.

<!-- BEGIN_TF_DOCS -->
Creates the S3 bucket that holds Terraform state for an AWS account: versioned,
encrypted, private, TLS-only, with S3-native state locking (`use_lockfile`) in mind.

The configuration that calls this module cannot keep its own state in the bucket it
creates. Call it from a small bootstrap configuration with local state, apply it once,
and point every other configuration's `backend "s3"` block at the `bucket_id` output.

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40, < 7.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.40, < 7.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_s3_bucket.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_lifecycle_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_lifecycle_configuration) | resource |
| [aws_s3_bucket_logging.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_ownership_controls.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_ownership_controls) | resource |
| [aws_s3_bucket_policy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_iam_policy_document.access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.bucket](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the state bucket. Must be globally unique across all of AWS — including the original owner, for a period after any bucket of this name is deleted. Every `backend "s3"` block must name it literally, because backend blocks cannot use variables, so choose something you will not want to change, e.g. `<org>-tfstate-<account-id>`. | `string` | n/a | yes |
| <a name="input_access_logging"></a> [access\_logging](#input\_access\_logging) | Server access logging for the state bucket. null (default) disables it. The target bucket must already exist, be in the same region, and grant `logging.s3.amazonaws.com` write access; it should not be this bucket. | <pre>object({<br/>    target_bucket = string<br/>    target_prefix = optional(string, "tfstate/")<br/>  })</pre> | `null` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of a customer-managed KMS key for state encryption. null (default) uses the AWS-managed `aws/s3` key, which needs no key policy and no extra IAM permissions. A customer-managed key's key policy must allow every role that runs Terraform, or plans fail with AccessDenied on state read; `state_access_policy_json` adds the matching IAM side. | `string` | `null` | no |
| <a name="input_noncurrent_version_expiration_days"></a> [noncurrent\_version\_expiration\_days](#input\_noncurrent\_version\_expiration\_days) | Days to keep superseded state versions — your window for recovering from a corrupted or mistaken apply. null keeps every version forever. Also governs cleanup of the deleted `.tflock` versions `use_lockfile` leaves behind on every run. | `number` | `90` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to the state bucket. The provider merges in its `default_tags` as usual. | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | A `backend "s3"` block for this bucket, with a placeholder key. Paste it into a configuration's `terraform {}` block and replace the key; backend blocks cannot reference outputs, so this is a copy-paste aid rather than something to wire up. |
| <a name="output_bucket_arn"></a> [bucket\_arn](#output\_bucket\_arn) | ARN of the state bucket. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the state bucket. This is what a `backend "s3"` block's `bucket` argument needs — not the ARN. |
| <a name="output_bucket_region"></a> [bucket\_region](#output\_bucket\_region) | Region the state bucket is in. Every backend block's `region` argument must match it. |
| <a name="output_state_access_policy_json"></a> [state\_access\_policy\_json](#output\_state\_access\_policy\_json) | IAM policy granting exactly what Terraform needs to read and write state and take `use_lockfile` locks in this bucket, plus KMS use when `kms_key_arn` is set. Not attached to anything: attach it to the roles that run Terraform. Covers the whole bucket; scope `Resource` to a key prefix yourself if one role should only reach one stack's state. |
<!-- END_TF_DOCS -->
