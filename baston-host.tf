resource "aws_security_group" "baston-host-alb-security-group" {
  name        = "Public Baston Host Security Group"
  description = "Enable ssh to the Baston Host"
  vpc_id      = aws_vpc.vpc_project.id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Baston host Security group"
  }
}

resource "aws_instance" "bastion-host" {
  ami                         = var.amis
  associate_public_ip_address = true
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.baston_host_keypair.key_name
  security_groups             = [aws_security_group.baston-host-alb-security-group.id]
  subnet_id                   = aws_subnet.public-subnet-bastion-host.id

  tags = {
    Name = "Bastion Host"
  }
}
