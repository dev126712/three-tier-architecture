resource "aws_eip" "eip_nat_gateway" {
  tags = {
    Name = "elastic ip nat gateway"
  }
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.eip_nat_gateway.id
  subnet_id     = aws_subnet.public-subnet-nat-gateway.id

  tags = {
    "Name" = "Nat Gateway"
  }
}
