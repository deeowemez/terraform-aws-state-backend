/**
 * examples/complete/variables.tf
 */

variable "kms_key_arn" {
  description = "ARN of an existing customer-managed KMS key to encrypt state with."
  type        = string
}

variable "log_bucket_name" {
  description = "Name of an existing bucket, in the same region, that accepts S3 server access logs."
  type        = string
}
