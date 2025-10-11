resource "aws_lb" "application-load-balancer" {
  name                       = "web-external-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.alb-security-group.id]
  subnets                    = [aws_subnet.public-subnet-nat-gateway.id, aws_subnet.public-subnet-bastion-host.id]
  enable_deletion_protection = false

  tags = {
    Name = "Entry App Load Balancer"
  }
}