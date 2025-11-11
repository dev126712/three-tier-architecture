resource "aws_vpc" "vpc_project" {
  cidr_block           = var.vpc_cidr
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-project"
  }
}

resource "aws_default_security_group" "default_sg_restrict" {
  vpc_id  = aws_vpc.vpc_project.id
  ingress = []
  egress  = []

  tags = {
    Name = "Default Security Group - Restricted"
  }
}
