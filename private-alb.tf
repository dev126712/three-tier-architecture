resource "aws_lb" "private-internal-application-load-balancer" {
  name                       = "load-balancer-1-internal"
  internal                   = true
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.internal-1-alb-security-group.id]
  subnets                    = [for subnet in aws_subnet.private-web-subnet : subnet.id]
  enable_deletion_protection = false

  tags = {
    Name = "Entry App Load Balancer"
  }
}

