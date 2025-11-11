resource "aws_security_group" "webtier-sg" {
  name        = "Webtier-SG"
  description = "Allow inbound traffic from public ALB"
  vpc_id      = aws_vpc.vpc_project.id

  ingress {
    description     = "Allow traffic from Web tier ALB"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public-alb-security-group.id]
  }
  ingress {
    description = "ssh for stress test "
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["9.78.7.30/32"]
  }

  egress {
    description = "allows egress from everywhere"
    from_port   = 0
    to_port     = 0
    protocol    = "443"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Webtier-SG"
  }
}

resource "aws_launch_template" "Web-launch-template" {
  name          = "Web-launch-template"
  description   = "Launch Template for Web Tier"
  image_id      = var.amis
  instance_type = var.instance_type

  network_interfaces {
    associate_public_ip_address = false
    security_groups             = [aws_security_group.webtier-sg.id]
  }



  key_name = aws_key_pair.baston_host_keypair.key_name

  metadata_options {
    http_endpoint          = "enabled"
    http_tokens            = "required" # Forces IMDSv2
    instance_metadata_tags = "enabled"  # Recommended to fully comply with best practices
    # ------------------------
  }
  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Webtier template"
    }
  }
}


resource "aws_lb_target_group" "webtier-alb-tg" {
  name     = "Webtier-ALB-TG"
  port     = 443
  protocol = "HTTPS"
  vpc_id   = aws_vpc.vpc_project.id

  health_check {
    path                = "/"            # The path to check (usually the application root)
    protocol            = "HTTPS"        # Must match the target group protocol or HTTP for simplicity
    port                = "traffic-port" # Use the port defined for the target group (443)
    healthy_threshold   = 3              # Number of consecutive successful checks
    unhealthy_threshold = 3              # Number of consecutive failed checks
    timeout             = 5              # Time (in seconds) to wait for a response
    interval            = 30             # Time (in seconds) between health checks
    matcher             = "200-399"      # Expected HTTP response codes (allows redirects and success)
  }
}

resource "aws_lb_listener" "webtier-alb" {
  load_balancer_arn = aws_lb.public-application-load-balancer.arn
  port              = "443"
  protocol          = "HTTPS"
  certificate_arn   = var.web_tier_certificate_arn
  ssl_policy        = "ELBSecurityPolicy-TLS13-1-2-2021-06"


  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtier-alb-tg.arn
  }
}
resource "aws_autoscaling_group" "Webtier-ASG" {
  name                      = "Web-tier-ASG"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = false
  target_group_arns         = [aws_lb_target_group.webtier-alb-tg.arn]
  vpc_zone_identifier       = [for subnet in aws_subnet.private-web-subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.Web-launch-template.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "webtier-ASG"
    propagate_at_launch = true
  }

}

resource "aws_autoscaling_policy" "webtier-autoscaling-policy-up" {
  name                   = "webtier-autoscaling-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Webtier-ASG.name
}
