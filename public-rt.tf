resource "aws_route_table" "public-route-table" {
  vpc_id = aws_vpc.vpc_project.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "Public Route Table"
  }
}


resource "aws_route_table_association" "public-nat-gateway-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-nat-gateway.id
  route_table_id = aws_route_table.public-route-table.id
}

resource "aws_route_table_association" "public-bastion-host-route-table-association" {
  subnet_id      = aws_subnet.public-subnet-bastion-host.id
  route_table_id = aws_route_table.public-route-table.id
}