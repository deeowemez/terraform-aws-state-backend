/**
 * examples/complete/main.tf
 *
 * Exercises the whole surface: a customer-managed KMS key, access logging to an existing
 * log bucket, a custom retention window, and a managed IAM policy built from the module's
 * own state_access_policy_json, ready to attach to a CI role.
 */

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "example"
      Environment = "sandbox"
    }
  }
}

module "state_backend" {
  source = "../../"

  bucket_name = "example-tfstate-complete-123456789012"

  # The key's policy must also allow every role that runs Terraform; the IAM policy below
  # covers only the IAM side.
  kms_key_arn = var.kms_key_arn

  access_logging = {
    target_bucket = var.log_bucket_name
  }

  noncurrent_version_expiration_days = 30

  tags = {
    Scope = "bootstrap"
  }
}

resource "aws_iam_policy" "terraform_state" {
  name   = "terraform-state-access"
  policy = module.state_backend.state_access_policy_json
}
