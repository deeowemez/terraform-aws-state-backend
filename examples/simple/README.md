# simple

The whole of a typical bootstrap configuration: one module call, AWS-managed encryption,
90-day version history. No backend block — this configuration's own state stays local.

```bash
terraform init
terraform apply
terraform output -raw backend_config   # paste into other configurations
```

> This example uses `source = "../../"` so it can be validated in CI before any version is
> published. In your own code use the registry address and a version pin:
>
> ```hcl
> source  = "deeowemez/state-backend/aws"
> version = "~> 0.1.0"
> ```

<!-- BEGIN_TF_DOCS -->
examples/simple/main.tf

## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.9.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.40, < 7.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
| ---- | ------ | ------- |
| <a name="module_state_backend"></a> [state\_backend](#module\_state\_backend) | ../../ | n/a |

## Resources

No resources.

## Inputs

No inputs.

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_backend_config"></a> [backend\_config](#output\_backend\_config) | Backend block to paste into other configurations. |
| <a name="output_bucket_id"></a> [bucket\_id](#output\_bucket\_id) | Name of the state bucket, for backend blocks. |
<!-- END_TF_DOCS -->
