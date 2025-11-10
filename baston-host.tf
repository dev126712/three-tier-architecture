resource "aws_security_group" "baston-host-alb-security-group" {
  name        = "Public Baston Host Security Group"
  description = "Enable ssh to the Baston Host"
  vpc_id      = aws_vpc.vpc_project.id

  ingress {
    description = "ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["78.67.5.54/32"]
  }

  egress {
    description = "allows egress to everywhere using https"
    from_port   = 0
    to_port     = 0
    protocol    = "443"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Baston host Security group"
  }
}

resource "aws_instance" "bastion-host" {
  ami                         = var.amis
  associate_public_ip_address = false
  instance_type               = var.instance_type
  key_name                    = aws_key_pair.baston_host_keypair.key_name
  security_groups             = [aws_security_group.baston-host-alb-security-group.id]
  subnet_id                   = aws_subnet.public-subnet-bastion-host.id

metadata_options {
  http_tokens              = "required" # Forces IMDSv2
  http_endpoint            = "enabled"
  instance_metadata_tags   = "enabled"
}

ebs_optimized = true

monitoring {
enabled = true
}

  tags = {
    Name = "Bastion Host"
  }
}
