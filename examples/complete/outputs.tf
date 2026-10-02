/**
 * examples/complete/outputs.tf
 */

output "bucket_id" {
  description = "Name of the state bucket, for backend blocks."
  value       = module.state_backend.bucket_id
}

output "backend_config" {
  description = "Backend block to paste into other configurations."
  value       = module.state_backend.backend_config
}

output "state_access_policy_arn" {
  description = "ARN of the managed policy to attach to roles that run Terraform."
  value       = aws_iam_policy.terraform_state.arn
}
