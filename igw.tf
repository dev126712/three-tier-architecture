resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.vpc_project.id

  tags = {
    Name = "VPC project IGW"
  }
}