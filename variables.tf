/**
 * variables.tf
 */

# ---------------------------------------------------------------------------
# Bucket
# ---------------------------------------------------------------------------

variable "bucket_name" {
  description = "Name of the state bucket. Must be globally unique across all of AWS — including the original owner, for a period after any bucket of this name is deleted. Every `backend \"s3\"` block must name it literally, because backend blocks cannot use variables, so choose something you will not want to change, e.g. `<org>-tfstate-<account-id>`."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9.-]{1,61}[a-z0-9]$", var.bucket_name))
    error_message = "bucket_name must be 3-63 characters of lowercase letters, digits, dots and hyphens, starting and ending with a letter or digit."
  }
}

variable "access_logging" {
  description = "Server access logging for the state bucket. null (default) disables it. The target bucket must already exist, be in the same region, and grant `logging.s3.amazonaws.com` write access; it should not be this bucket."
  type = object({
    target_bucket = string
    target_prefix = optional(string, "tfstate/")
  })
  default = null
}

# ---------------------------------------------------------------------------
# Encryption
# ---------------------------------------------------------------------------

variable "kms_key_arn" {
  description = "ARN of a customer-managed KMS key for state encryption. null (default) uses the AWS-managed `aws/s3` key, which needs no key policy and no extra IAM permissions. A customer-managed key's key policy must allow every role that runs Terraform, or plans fail with AccessDenied on state read; `state_access_policy_json` adds the matching IAM side."
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws[a-z-]*:kms:", var.kms_key_arn))
    error_message = "kms_key_arn must be a KMS key ARN (arn:aws:kms:...), not a key ID or alias name."
  }
}

# ---------------------------------------------------------------------------
# Retention
# ---------------------------------------------------------------------------

variable "noncurrent_version_expiration_days" {
  description = "Days to keep superseded state versions — your window for recovering from a corrupted or mistaken apply. null keeps every version forever. Also governs cleanup of the deleted `.tflock` versions `use_lockfile` leaves behind on every run."
  type        = number
  default     = 90

  validation {
    condition     = var.noncurrent_version_expiration_days == null || try(var.noncurrent_version_expiration_days >= 1, false)
    error_message = "noncurrent_version_expiration_days must be at least 1, or null."
  }
}

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------

variable "tags" {
  description = "Tags applied to the state bucket. The provider merges in its `default_tags` as usual."
  type        = map(string)
  default     = {}
}
