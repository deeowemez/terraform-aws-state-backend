/**
 * examples/simple/outputs.tf
 */

output "bucket_id" {
  description = "Name of the state bucket, for backend blocks."
  value       = module.state_backend.bucket_id
}

output "backend_config" {
  description = "Backend block to paste into other configurations."
  value       = module.state_backend.backend_config
}
