variable "vpc_id" {
  type = string
}

variable "subnets" {
  type = map
}

resource "aws_security_group" "public_security_group" {
  name        = "public_access_sg"
  description = "Allow public inbound traffic"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
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
    Name = "App VPC - Public traffic SG"
  }
}
