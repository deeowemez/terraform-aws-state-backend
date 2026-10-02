/**
 * outputs.tf
 */

output "bucket_id" {
  description = "Name of the state bucket. This is what a `backend \"s3\"` block's `bucket` argument needs — not the ARN."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the state bucket."
  value       = aws_s3_bucket.this.arn
}

output "bucket_region" {
  description = "Region the state bucket is in. Every backend block's `region` argument must match it."
  value       = aws_s3_bucket.this.region
}

output "state_access_policy_json" {
  description = "IAM policy granting exactly what Terraform needs to read and write state and take `use_lockfile` locks in this bucket, plus KMS use when `kms_key_arn` is set. Not attached to anything: attach it to the roles that run Terraform. Covers the whole bucket; scope `Resource` to a key prefix yourself if one role should only reach one stack's state."
  value       = data.aws_iam_policy_document.access.json
}

output "backend_config" {
  description = "A `backend \"s3\"` block for this bucket, with a placeholder key. Paste it into a configuration's `terraform {}` block and replace the key; backend blocks cannot reference outputs, so this is a copy-paste aid rather than something to wire up."
  value       = <<-EOT
    backend "s3" {
      bucket       = "${aws_s3_bucket.this.id}"
      key          = "<stack>/terraform.tfstate"
      region       = "${aws_s3_bucket.this.region}"
      encrypt      = true
      use_lockfile = true # requires Terraform >= 1.10
    }
  EOT
}
