# Changelog

All notable changes to this module are documented here. The format follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this project adheres to
[Semantic Versioning](https://semver.org/spec/v2.0.0.html).

While the module is at `0.x`, minor releases may contain breaking changes to the variable
interface. Pin with `~> 0.1.0` (patch-only) until `1.0.0`.

## [Unreleased]

## [0.1.0]

Initial release.

### Added

- S3 state bucket with `prevent_destroy`, `BucketOwnerEnforced` ownership, all four public
  access blocks on, and versioning always enabled.
- SSE-KMS with S3 Bucket Keys, using the AWS-managed `aws/s3` key or a caller-supplied
  customer-managed key (`kms_key_arn`).
- Lifecycle rule expiring noncurrent state versions and leftover `.tflock` delete markers
  after `noncurrent_version_expiration_days` (default 90), and aborting incomplete
  multipart uploads after 7 days.
- TLS-only bucket policy.
- Optional server access logging (`access_logging`).
- `state_access_policy_json` output: least-privilege IAM for reading and writing state and
  taking `use_lockfile` locks, including KMS when a customer-managed key is used.
- `backend_config` output: a ready-to-paste `backend "s3"` block.
