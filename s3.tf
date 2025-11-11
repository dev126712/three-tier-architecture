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
resource "aws_s3_bucket_server_side_encryption_configuration" "vpc_flow_logs_bucket_encryption" {
  # Link to the main S3 bucket resource
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id 

  # --- New dedicated resource block ---
  rule {
    apply_server_side_encryption_by_default {
      # Setting AES256 for Flow Logs (which don't support KMS)
      sse_algorithm = "AES256" 
    }
  }
  # ------------------------------------
}
resource "aws_flow_log" "vpc_project_flow_log" {
  traffic_type    = "ALL" 
  vpc_id          = aws_vpc.vpc_project.id
  log_destination = aws_s3_bucket.vpc_flow_logs_bucket.arn 
  log_destination_type = "s3" 
  max_aggregation_interval = 60 
}
resource "aws_kms_key" "s3_bucket_key" {
  description             = "KMS Key for S3 Flow Logs Encryption"
  deletion_window_in_days = 10
}

resource "aws_sqs_queue" "s3_events_queue" {
  name                      = "vpc-flow-log-events-queue"
  delay_seconds             = 0
  max_message_size          = 262144
  message_retention_seconds = 345600
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
  # Policy must allow Get, List, and Replicate actions
  # ... (Policy definition goes here) ...
}
# Attach policy to role
resource "aws_iam_role_policy_attachment" "replication_attach" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_bucket" "vpc_flow_logs_dest_bucket" {
  bucket = "tf-project-vpc-flow-logs-dest-12345"
  # This bucket must be in a DIFFERENT region, often configured via a provider alias.
  # provider = aws.dr
  versioning { enabled = true }
}
resource "aws_s3_bucket_versioning" "vpc_flow_logs_bucket_versioning" {
  bucket = aws_s3_bucket.vpc_flow_logs_bucket.id 
  versioning_configuration {
    status = "Enabled"
  }
}
