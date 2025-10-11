resource "aws_lb" "public-application-load-balancer" {
  name                       = "external-load-balancer"
  internal                   = false
  load_balancer_type         = "application"
  security_groups            = [aws_security_group.public-alb-security-group.id]
  subnets                    = [aws_subnet.public-subnet-nat-gateway.id, aws_subnet.public-subnet-bastion-host.id]
  enable_deletion_protection = false

  tags = {
    Name = "Entry App Load Balancer"
  }
}
