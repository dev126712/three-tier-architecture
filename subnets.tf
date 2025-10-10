resource "aws_subnet" "public-subnet-bastion-host" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.public-subnet-bastion-host-cidr-block
  availability_zone       = var.availability-zone-1
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet - Bastion Host"
  }
}



resource "aws_subnet" "public-subnet-nat-gateway" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.public-subnet-nat-gateway-cidr-block
  availability_zone       = var.availability-zone-2
  map_public_ip_on_launch = true

  tags = {
    Name = "Public Subnet - Nat Gateways"
  }
}

resource "aws_subnet" "private-web-subnet-1" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-web-subnet-1-cidr_block
  availability_zone       = var.availability-zone-1
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1 - Web Tier"
  }
}

resource "aws_subnet" "private-web-subnet-2" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-web-subnet-2-cidr_block
  availability_zone       = var.availability-zone-2
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2 - Web Tier"
  }
}

resource "aws_subnet" "private-app-subnet-1" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-app-subnet-1-cidr_block
  availability_zone       = var.availability-zone-1
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1 - App Tier"
  }
}

resource "aws_subnet" "private-app-subnet-2" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-app-subnet-2-cidr_block
  availability_zone       = var.availability-zone-2
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2 - App Tier"
  }
}

resource "aws_subnet" "private-db-subnet-1" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-db-subnet-1-cidr_block
  availability_zone       = var.availability-zone-1
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 1 - Database Tier"
  }
}

resource "aws_subnet" "private-db-subnet-2" {
  vpc_id                  = aws_vpc.vpc_project.id
  cidr_block              = var.private-db-subnet-2-cidr_block
  availability_zone       = var.availability-zone-2
  map_public_ip_on_launch = false

  tags = {
    Name = "Private Subnet 2 - Database Tier"
  }
}