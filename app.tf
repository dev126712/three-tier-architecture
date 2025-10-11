resource "aws_security_group" "apptier-sg" {
  name        = "Apptier-SG"
  description = "Allow inbound traffic from apptier ALB"
  vpc_id      = aws_vpc.vpc_project.id

  ingress {
    description     = "Allow traffic from apptier alb"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.public-alb-security-group.id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Apptier-SG"
  }
}

# Create apptier launch template
resource "aws_launch_template" "Apptier-launch-template" {
  name          = "Apptier-launch-template"
  description   = "Launch Template for App Tier"
  image_id      = var.amis
  instance_type = var.instance_type

  vpc_security_group_ids = [aws_security_group.apptier-sg.id]
  key_name               = aws_key_pair.baston_host_keypair.key_name

  monitoring {
    enabled = true
  }

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name = "Apptier template"
    }
  }
}

# Create Apptier application load balancer target group
resource "aws_lb_target_group" "apptier-alb-tg" {
  name     = "Apptier-ALB-TG"
  port     = 80
  protocol = "HTTP"
  vpc_id   = aws_vpc.vpc_project.id
}

# Create Apptier application load balancer listener
resource "aws_lb_listener" "apptier-alb" {
  load_balancer_arn = aws_lb.private-internal-application-load-balancer.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.apptier-alb-tg.arn
  }
}
# Create Apptier autoscaling group
resource "aws_autoscaling_group" "Apptier-ASG" {
  name                      = "App-tier-ASG"
  max_size                  = 3
  min_size                  = 1
  health_check_grace_period = 300
  health_check_type         = "ELB"
  desired_capacity          = 2
  force_delete              = false
  target_group_arns         = [aws_lb_target_group.apptier-alb-tg.arn]
  vpc_zone_identifier       = [for subnet in aws_subnet.private-app-subnet : subnet.id]
  launch_template {
    id      = aws_launch_template.Apptier-launch-template.id
    version = "$Latest"
  }
  lifecycle {
    create_before_destroy = true
  }
  tag {
    key                 = "Name"
    value               = "Apptier-ASG"
    propagate_at_launch = true
  }

}

