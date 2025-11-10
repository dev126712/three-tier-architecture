resource "aws_route_table" "private-route-table" {
  vpc_id = aws_vpc.vpc_project.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = {
    Name = "Private Route Table"
  }
}


resource "aws_route_table_association" "private-web-subnet-1-route-table-association" {
  for_each       = toset(var.private-web-subnet-cidr_block)
  subnet_id      = aws_subnet.private-web-subnet[index(var.private-web-subnet-cidr_block, each.key)].id
  route_table_id = aws_route_table.public-route-table.id
}



resource "aws_route_table_association" "private-app-subnet-1-route-table-association" {
  for_each      = toset(var.private-app-subnet-cidr_block)
  subnet_id      = aws_subnet.private-app-subnet[index(var.private-app-subnet-cidr_block, each.key)].id
  route_table_id = aws_route_table.public-route-table.id
}


resource "aws_route_table_association" "private-db-subnet-1-route-table-association" {
  for_each      = toset(var.private-db-subnet-cidr_block)
  subnet_id      = aws_subnet.private-db-subnet[index(var.private-db-subnet-cidr_block, each.key)].id
  route_table_id = aws_route_table.public-route-table.id
}