resource "aws_lb" "public-application-load-balancer" {
  name                       = "external-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public-alb-security-group.id]
  subnets                    = [aws_subnet.public-subnet-nat-gateway.id, aws_subnet.public-subnet-bastion-host.id]
  enable_deletion_protection = true

  access_logs {
    enabled = true
    bucket  = "tf-project-vpc-flow-logs-unique-name-12345"
    prefix  = "internal-alb-access"
  }


  drop_invalid_header_fields = true

  tags = {
    Name = "Entry App Load Balancer"
  }
}

resource "aws_wafv2_web_acl" "web_acl" {
  name  = "web-acl"
  scope = "REGIONAL"
  default_action {
    allow {}
  }

  visibility_config {
    cloudwatch_metrics_enabled = true
    metric_name                = "public-web-acl-metric"
    sampled_requests_enabled   = true
  }

  rule {
    name     = "AWSManagedRulesLog4jRuleSet"
    priority = 1
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesLog4jRuleSet"
      }
    }
    action {
      block {} # Recommended action for this rule set
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLog4jRuleSet-Metric-Correct"
      sampled_requests_enabled   = true
    }
  }

  rule {
    name     = "AWS-AWSManagedRulesKnownBadInputsRuleSet"
    priority = 2
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesKnownBadInputsRuleSet"
      }
    }
    action {
      count {}
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesCommonRuleSet-Metric"
      sampled_requests_enabled   = true
    }
  }




  rule {
    name     = "AWSManagedRulesCommonRuleSet"
    priority = 3
    statement {
      managed_rule_group_statement {
        vendor_name = "AWS"
        name        = "AWSManagedRulesCommonRuleSet"
      }
    }
    action {
      block {} # Recommended action is block
    }
    visibility_config {
      cloudwatch_metrics_enabled = true
      metric_name                = "AWSManagedRulesLog4jRuleSet-Metric"
      sampled_requests_enabled   = true
    }
  }
}

resource "aws_wafv2_web_acl_association" "public_alb_waf_association" {
  resource_arn = aws_lb.public-application-load-balancer.arn
  web_acl_arn  = aws_wafv2_web_acl.web_acl.arn
}

# --- WAF Logging Configuration ---
resource "aws_wafv2_web_acl_logging_configuration" "public_alb_waf_logging" {
  resource_arn = aws_wafv2_web_acl.web_acl.arn

  log_destination_configs = [aws_s3_bucket.access_logs_replica_bucket.arn]

  redacted_fields {
    single_header {
      name = "authorization"
    }
  }

  # Ensure the bucket policy grants WAF permissions before logging is configured
  # depends_on = [aws_s3_bucket_policy.waf_logs_policy]
}
