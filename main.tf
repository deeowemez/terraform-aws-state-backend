/**
 * Creates the S3 bucket that holds Terraform state for an AWS account: versioned,
 * encrypted, private, TLS-only, with S3-native state locking (`use_lockfile`) in mind.
 *
 * The configuration that calls this module cannot keep its own state in the bucket it
 * creates. Call it from a small bootstrap configuration with local state, apply it once,
 * and point every other configuration's `backend "s3"` block at the `bucket_id` output.
 */

resource "aws_s3_bucket" "this" {
  bucket = var.bucket_name
  tags   = var.tags

  # Destroying this bucket would destroy the state describing every other stack. There is
  # no legitimate reason to do it as part of a routine apply, so it is not a variable: see
  # the README for the deliberate teardown path.
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_s3_bucket_ownership_controls" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "this" {
  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# State files are small and overwritten on every apply. Versioning is the only thing that
# makes a corrupted or truncated state recoverable, so it is not optional here.
resource "aws_s3_bucket_versioning" "this" {
  bucket = aws_s3_bucket.this.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "aws:kms"
      # null selects the AWS-managed aws/s3 key.
      kms_master_key_id = var.kms_key_arn
    }

    # State is written on every apply of every stack. S3 Bucket Keys cut the KMS request
    # charges that would otherwise accrue per write.
    bucket_key_enabled = true
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "this" {
  bucket = aws_s3_bucket.this.id

  rule {
    id     = "state-housekeeping"
    status = "Enabled"

    filter {}

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }

    # Every apply leaves a noncurrent state version, and every lock leaves a deleted
    # .tflock version behind. Without expiry both accumulate forever.
    dynamic "noncurrent_version_expiration" {
      for_each = var.noncurrent_version_expiration_days != null ? [1] : []

      content {
        noncurrent_days = var.noncurrent_version_expiration_days
      }
    }

    # Once a .tflock's noncurrent versions have expired, its delete marker is all that is
    # left. This removes it.
    dynamic "expiration" {
      for_each = var.noncurrent_version_expiration_days != null ? [1] : []

      content {
        expired_object_delete_marker = true
      }
    }
  }

  depends_on = [aws_s3_bucket_versioning.this]
}

resource "aws_s3_bucket_logging" "this" {
  count = var.access_logging != null ? 1 : 0

  bucket        = aws_s3_bucket.this.id
  target_bucket = var.access_logging.target_bucket
  target_prefix = var.access_logging.target_prefix
}

# State in transit is as sensitive as state at rest — it contains every attribute of every
# resource, including anything marked sensitive. An explicit Deny beats any Allow.
resource "aws_s3_bucket_policy" "this" {
  bucket = aws_s3_bucket.this.id
  policy = data.aws_iam_policy_document.bucket.json

  depends_on = [aws_s3_bucket_public_access_block.this]
}

data "aws_iam_policy_document" "bucket" {
  statement {
    sid       = "DenyInsecureTransport"
    effect    = "Deny"
    actions   = ["s3:*"]
    resources = [aws_s3_bucket.this.arn, "${aws_s3_bucket.this.arn}/*"]

    principals {
      type        = "*"
      identifiers = ["*"]
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

# Not attached to anything. Emitted as the state_access_policy_json output for callers to
# attach to whichever roles run Terraform, so it cannot drift from the bucket it describes.
data "aws_iam_policy_document" "access" {
  statement {
    sid       = "ListStateBucket"
    actions   = ["s3:ListBucket"]
    resources = [aws_s3_bucket.this.arn]
  }

  # DeleteObject is what releases a use_lockfile lock. Without it, every run leaves the
  # state locked.
  statement {
    sid       = "ReadWriteStateAndLocks"
    actions   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
    resources = ["${aws_s3_bucket.this.arn}/*"]
  }

  # The AWS-managed aws/s3 key grants itself to callers via its key policy, so KMS
  # permissions are only needed for a customer-managed key.
  dynamic "statement" {
    for_each = var.kms_key_arn != null ? [1] : []

    content {
      sid       = "UseStateKey"
      actions   = ["kms:Decrypt", "kms:Encrypt", "kms:GenerateDataKey"]
      resources = [var.kms_key_arn]
    }
  }
}
