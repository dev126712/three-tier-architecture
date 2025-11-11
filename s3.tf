resource "aws_s3_bucket" "vpc_flow_logs_bucket" {
  bucket = "tf-project-vpc-flow-logs-unique-name-12345"
  
  tags = {
    Name = "VPC Flow Logs Destination"
  }
}

resource "aws_flow_log" "vpc_project_flow_log" {
  traffic_type    = "ALL" 
  vpc_id          = aws_vpc.vpc_project.id
  log_destination = aws_s3_bucket.vpc_flow_logs_bucket.arn 
  log_destination_type = "s3" 
  max_aggregation_interval = 60 
}
