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
  iam_instance_profile        = aws_iam_instance_profile.bastion_host_profile.name

metadata_options {
  http_tokens              = "required" # Forces IMDSv2
  http_endpoint            = "enabled"
  instance_metadata_tags   = "enabled"
}

root_block_device {
  encrypted = true
}


ebs_optimized = true

monitoring = true


  tags = {
    Name = "Bastion Host"
  }
}

resource "aws_iam_role" "bastion_host_role" {
  name = "bastion-host-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      },
    ]
  })
}


resource "aws_iam_instance_profile" "bastion_host_profile" {
  name = "bastion-host-profile"
  role = aws_iam_role.bastion_host_role.name
}
