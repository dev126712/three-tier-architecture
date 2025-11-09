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
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
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
    associate_public_ip_address = true
    security_groups             = [aws_security_group.public-alb-security-group.id]
  }

  key_name = aws_key_pair.baston_host_keypair.key_name

  metadata_options {
    http_endpoint = "enabled"
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


# Create Webtier application load balancer target group
resource "aws_lb_target_group" "webtier-alb-tg" {
  name     = "Webtier-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_project.id
}

# Create Webtier application load balancer listener
resource "aws_lb_listener" "webtier-alb" {
  load_balancer_arn = aws_lb.public-application-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.webtier-alb-tg.arn
  }
}
# Create Webtier autoscaling group
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

# Creating the AWS Cloudwatch Alarm that will scale up when CPU utilization increase.
resource "aws_autoscaling_policy" "webtier-autoscaling-policy-up" {
  name                   = "webtier-autoscaling-policy-up"
  scaling_adjustment     = 1
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.Webtier-ASG.name
}