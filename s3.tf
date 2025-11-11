resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "tf-project-vpc-flow-logs-unique-name-12345"
 
  replication_configuration {
    role = aws_iam_role.replication_role.arn
    rules {
      id     = "replicate-all-logs"
      status = "Enabled"

      destination {
        bucket        = aws_s3_bucket.vpc_flow_logs_dest_bucket.arn
        storage_class = "STANDARD"
      }
    }
  }

  
  tags = {
    Name = "VPC Flow Logs Destination"
  }
}
# Fix CKV_AWS_145 for Source Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # Using SSE-S3 as Flow Logs don't support KMS
    }
  }
}

# Fix CKV_AWS_145 for Destination Bucket
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_dest_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}
resource "aws_flow_log" "vpc_project_flow_log" {
  traffic_type    = "ALL" 
  vpc_id          = aws_vpc.vpc_project.id
  log_destination = aws_s3_bucket.vpc_flow_logs_bucket.arn 
  log_destination_type = "s3" 
  max_aggregation_interval = 60 
}

resource "aws_sqs_queue" "s3_events_queue" {
  name                      = "vpc-flow-log-events-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  kms_master_key_id         = "alias/aws/sqs"
}

resource "aws_s3_bucket_notification" "vpc_flow_log_notification" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id 

  queue {
    id        = "flow_log_objects"
    queue_arn = aws_sqs_queue.s3_events_queue.arn
    events    = ["s3:ObjectCreated:*"] 
  }
  
  depends_on = [aws_s3_bucket.vpc_flow_logs_bucket]
}
resource "aws_iam_role" "replication_role" {
  name = "s3-replication-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Action = "sts:AssumeRole",
      Effect = "Allow",
      Principal = {
        Service = "s3.amazonaws.com"
      }
    }]
  })
}

resource "aws_iam_policy" "replication_policy" {
  name        = "S3ReplicationPolicy-${aws_s3_bucket.vpc_flow_logs_bucket.id}"
  description = "IAM Policy for S3 Cross-Region Replication"

  # --- Required 'policy' argument with JSON document ---
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      # 1. Permissions on the Source Bucket (The Bucket itself)
      {
        Sid    = "SourceBucketPermissions"
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
          "s3:GetBucketVersioning"
        ]
        Resource = [
          aws_s3_bucket.vpc_flow_logs_bucket.arn
        ]
      },
      # 2. Permissions on the Source Bucket Objects
      {
        Sid    = "ReplicateSourceObjects"
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        # Must target objects within the bucket
        Resource = [
          "${aws_s3_bucket.vpc_flow_logs_bucket.arn}/*"
        ]
      },
      # 3. Permissions on the Destination Bucket Objects
      {
        Sid    = "ReplicateDestinationObjects"
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        # Must target objects within the destination bucket
        Resource = [
          "${aws_s3_bucket.vpc_flow_logs_dest_bucket.arn}/*"
        ]
      }
    ]
  })
}
# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication_attach" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_bucket" "vpc_flow_logs_dest_bucket" {
  bucket = "tf-project-vpc-flow-logs-dest-12345"
}
resource "aws_s3_bucket_versioning" "vpc_flow_logs_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id 
  versioning_configuration {
    status = "Enabled"
  }
}
resource "aws_s3_bucket_versioning" "vpc_flow_logs_dest_bucket_versioning" {
  # Link to the destination S3 bucket resource
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id 

  versioning_configuration {
    status = "Enabled"
  }
}

# Fix CKV2_AWS_6 for Source Bucket
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_bucket_pab" {
  bucket                  = aws_s3_bucket.vpc_flow_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Fix CKV2_AWS_6 for Destination Bucket
resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_dest_bucket_pab" {
  bucket                  = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
# Fix CKV2_AWS_61 for Source Bucket
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_bucket_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  rule {
    id     = "ArchiveOldLogs"
    status = "Enabled"
    # Transition to cheaper storage after 60 days
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    # Delete logs after 365 days
    expiration {
      days = 365
    }
  }

  abort_incomplete_multipart_upload {
      days_after_initiation = 7 # Abort failed uploads older than 7 days
    }
}

# Fix CKV2_AWS_61 for Destination Bucket
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_dest_bucket_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  rule {
    id     = "ArchiveOldLogsDest"
    status = "Enabled"
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
  }

  abort_incomplete_multipart_upload {
      days_after_initiation = 7 
    }
}
resource "aws_kms_key" "s3_bucket_key" {
  description             = "KMS Key for S3 Flow Logs Encryption"
  deletion_window_in_days = 10
  
  # --- FIX for CKV_AWS_7 ---
  enable_key_rotation     = true
  
  # --- FIX for CKV2_AWS_64 ---
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Sid    = "Enable IAM User Permissions",
        Effect = "Allow",
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root" # Requires data "aws_caller_identity" "current" {}
        },
        Action   = "kms:*",
        Resource = "*"
      },
      # (Add statements for S3 and other services that need to use the key)
    ]
  })
}
