resource "aws_lb" "public-application-load-balancer" { 
  name                       = "external-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public-alb-security-group.id]
  subnets                    = [aws_subnet.public-subnet-nat-gateway.id, aws_subnet.public-subnet-bastion-host.id]
  enable_deletion_protection = true

  access_logs {
    enabled = true
    # IMPORTANT: Replace 'your-alb-logs-bucket-name' with the actual S3 bucket name
    bucket  = "your-alb-logs-bucket-name" 
    # Optional: Add a prefix to organize logs within the bucket
    prefix  = "internal-alb-access" 
  }

  drop_invalid_header_fields = true

  tags = {
    Name = "Entry App Load Balancer"
  }
}
# Assuming you have an existing WAF Web ACL named 'aws_wafv2_web_acl.web_acl'
resource "aws_wafv2_web_acl_association" "public_alb_waf_association" {
  resource_arn = aws_lb.public-application-load-balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn # Replace with your WAF ACL resource reference
}
