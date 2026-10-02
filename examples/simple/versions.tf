/**
 * examples/simple/versions.tf
 */

terraform {
  required_version = ">= 1.9.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.40, < 7.0"
    }
  }

  # No backend block: the configuration that creates the state bucket keeps its own state
  # locally. See the module README.
}
