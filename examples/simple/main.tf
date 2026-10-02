/**
 * examples/simple/main.tf
 */

provider "aws" {
  region = "us-east-1"
}

# AWS-managed encryption, 90-day version history, no access logging. This is the whole of
# a typical bootstrap configuration.
module "state_backend" {
  source = "../../"

  bucket_name = "example-tfstate-123456789012"
}
