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

resource "aws_s3_bucket_notification" "vpc_flow_logs_source_notification" { # Renamed from bucket_notification
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  queue {
    queue_arn = aws_sqs_queue.s3_events_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_s3_bucket.vpc_flow_logs_bucket]
}

resource "aws_s3_bucket_logging" "vpc_flow_logs_source_logging" { # Renamed from source_bucket_logging to avoid conflict
  bucket        = aws_s3_bucket.vpc_flow_logs_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "s3-access-logs-source/"
}

# --- Server Side Encryption Configuration (CKV_AWS_145) ---
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
    }
  }
}

# --- Lifecycle Configuration (CKV2_AWS_61) ---
# FIX CKV2_AWS_61: Lifecycle Configuration for VPC Flow Logs Source Bucket (Missing in your code)
resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_source_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  rule {
    id     = "FlowLogRetentionPolicy"
    status = "Enabled"
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# --- Versioning Configuration (Needed for Replication) ---
resource "aws_s3_bucket_versioning" "vpc_flow_logs_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_bucket_pab" {
  bucket                  = aws_s3_bucket.vpc_flow_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_flow_log" "vpc_project_flow_log" {
  traffic_type             = "ALL"
  vpc_id                   = aws_vpc.vpc_project.id
  log_destination          = aws_s3_bucket.vpc_flow_logs_bucket.arn
  log_destination_type     = "s3"
  max_aggregation_interval = 60
}






# -----------------------------------------access_logs_replica_bucket---------------------------------------------------
resource "aws_s3_bucket" "access_logs_replica_bucket" {
  # Change the bucket name to be globally unique
  bucket = "tf-project-access-logs-replica-12345"

  # versioning {
  #  enabled = true
  #}

}

# FIX CKV2_AWS_62: Event Notifications for Replica Bucket (Missing in your code)
resource "aws_s3_bucket_notification" "access_logs_replica_notification" {
  bucket = aws_s3_bucket.access_logs_replica_bucket.id
  queue {
    queue_arn = aws_sqs_queue.s3_events_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# FIX CKV_AWS_18: Access Logging for Replica Bucket (Missing in your code)
resource "aws_s3_bucket_logging" "access_logs_replica_logging" {
  bucket        = aws_s3_bucket.access_logs_replica_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "replica-access-logs/"
}

# FIX CKV_AWS_145: KMS Encryption for Replica Bucket (Missing in your code)
resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_replica_encryption" {
  bucket = aws_s3_bucket.access_logs_replica_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
    }
  }
}

# FIX CKV2_AWS_61: Lifecycle Configuration for Replica Bucket (Missing in your code)
resource "aws_s3_bucket_lifecycle_configuration" "access_logs_replica_lifecycle" {
  bucket = aws_s3_bucket.access_logs_replica_bucket.id
  rule {
    id     = "ReplicaLogRetention"
    status = "Enabled"
    expiration {
      days = 365 # Keep logs for one year
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

# FIX CKV2_AWS_6: Public Access Block for Replica Bucket (Missing in your code)
resource "aws_s3_bucket_public_access_block" "access_logs_replica_pab" {
  bucket                  = aws_s3_bucket.access_logs_replica_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}







# -----------------------------------------------vpc_flow_logs_dest_bucket--------------------------------------------------
resource "aws_s3_bucket" "vpc_flow_logs_dest_bucket" {
  bucket = "tf-project-vpc-flow-logs-dest-12345"
}

resource "aws_s3_bucket_notification" "vpc_flow_logs_dest_notification" { # Renamed from vpc_flow_log_notification
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  queue {
    queue_arn = aws_sqs_queue.s3_events_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
  depends_on = [aws_s3_bucket.vpc_flow_logs_dest_bucket]
}

resource "aws_s3_bucket_logging" "vpc_flow_logs_dest_logging" { # Renamed from source_bucket_logging to avoid conflict
  bucket        = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  target_bucket = aws_s3_bucket.access_logs_bucket.id
  target_prefix = "s3-access-logs-dest/"
}

resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_dest_bucket_encryption" {
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "vpc_flow_logs_dest_bucket_lifecycle" {
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  rule {
    id     = "DeleteOldReplicaLogs"
    status = "Enabled"
    transition {
      days          = 60
      storage_class = "GLACIER"
    }
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_public_access_block" "vpc_flow_logs_dest_bucket_pab" {
  bucket                  = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "vpc_flow_logs_dest_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_dest_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}








# ----------------------------------access_logs_bucket----------------------------------------------------
resource "aws_s3_bucket" "access_logs_bucket" {
  bucket = "tf-project-vpc-flow-logs-dest-12385756465445"
}

resource "aws_s3_bucket_public_access_block" "access_logs_bucket_pab" {
  bucket                  = aws_s3_bucket.access_logs_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "access_logs_bucket_versioning" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "access_logs_bucket_lifecycle" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  rule {
    id     = "LogRetentionPolicy"
    status = "Enabled"
    # Transition to Glacier after 90 days
    transition {
      days          = 90
      storage_class = "GLACIER"
    }
    # Delete logs after 365 days
    expiration {
      days = 365
    }
    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "access_logs_bucket_kms_encryption" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3_bucket_key.arn
    }
  }
}

# --- Logging Configuration (CKV_AWS_18) ---
# --- Replication Configuration ---
resource "aws_s3_bucket_replication_configuration" "access_logs_replication" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  role   = aws_iam_role.replication_role.arn

  rule {
    id     = "replicate-all-access-logs"
    status = "Enabled"

    filter {
      prefix = ""
    }

    destination {
      bucket        = aws_s3_bucket.access_logs_replica_bucket.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.access_logs_bucket_versioning,
  ]
}

# FIX CKV2_AWS_62: Event Notifications for Access Logs Bucket (Missing in your code)
resource "aws_s3_bucket_notification" "access_logs_bucket_notification" {
  bucket = aws_s3_bucket.access_logs_bucket.id
  queue {
    queue_arn = aws_sqs_queue.s3_events_queue.arn
    events    = ["s3:ObjectCreated:*"]
  }
}

# ------------------------------KMS and IAM Resources-------------------------------------
# --- KMS and IAM Resources ---

resource "aws_kms_key" "s3_bucket_key" {
  description             = "KMS Key for S3 Flow Logs Encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true # FIX: CKV_AWS_7

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
      {
        Sid    = "Allow S3 to Encrypt/Decrypt for SQS"
        Effect = "Allow"
        Principal = {
          Service = "s3.amazonaws.com"
        },
        Action = [
          "kms:GenerateDataKey",
          "kms:Decrypt"
        ],
        Resource = "*"
      }
    ]
  })
}

resource "aws_kms_alias" "s3_kms_alias" {
  name          = "alias/s3-bucket-key"
  target_key_id = aws_kms_key.s3_bucket_key.key_id
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
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
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
        Resource = [
          "${aws_s3_bucket.vpc_flow_logs_dest_bucket.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "replication_attach" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

# --- SQS Queue and Flow Log ---
resource "aws_sqs_queue" "s3_events_queue" {
  name                      = "vpc-flow-log-events-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
  kms_master_key_id         = aws_kms_key.s3_bucket_key.arn
}