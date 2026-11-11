resource "aws_eip" "nat_Drago_ro" {
  domain = "vpc"
}


resource "aws_nat_gateway" "nat_Drago_ro" {
  allocation_id = aws_eip.nat_Drago_ro.id
  subnet_id     = aws_subnet.subnet_public_1.id
  depends_on     = [aws_internet_gateway.gw_Drago_ro]
}

resource "aws_route_table" "prive1_rt_Draco_ro" {
  vpc_id = aws_vpc.Drago_ro.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_Drago_ro.id
  }
}

resource "aws_route_table_association" "rt_prive_ass1" {
  subnet_id      = aws_subnet.subnet_prive_1.id
  route_table_id = aws_route_table.prive1_rt_Draco_ro.id
}

