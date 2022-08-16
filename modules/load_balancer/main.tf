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

resource "aws_lb" "public_alb" {
  name               = "public-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.public_security_group.id]
  subnets            = [for subnet in var.subnets : subnet.id]

  # access_logs {
  #   bucket  = aws_s3_bucket.lb_logs.bucket
  #   prefix  = "test-lb"
  #   enabled = true
  # }

  tags = {
    Environment = "production"
  }
}

resource "aws_lb_target_group" "public_alb_target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = var.vpc_id
  target_type = "ip"

  depends_on = [aws_lb.public_alb]
}

resource "aws_lb_listener" "front_end" {
  load_balancer_arn = aws_lb.public_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.public_alb_target_group.arn
  }
}
