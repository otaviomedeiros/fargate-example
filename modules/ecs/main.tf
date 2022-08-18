variable "public_load_balancer" {
  
}

variable "public_load_balancer_target_group" {
  
}

resource "aws_ecr_repository" "repository" {
  name                 = "app-repository"
  image_tag_mutability = "MUTABLE"
}

resource "aws_ecs_cluster" "ecs-cluster" {
  name               = "app-ecs-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_ecs_cluster_capacity_providers" "ecs-cluster-capacity-provider" {
  cluster_name = aws_ecs_cluster.ecs-cluster.name

  capacity_providers = ["FARGATE"]

  default_capacity_provider_strategy {
    base              = 1
    weight            = 100
    capacity_provider = "FARGATE"
  }
}

data "aws_iam_policy_document" "app-task-definition-assume-role-policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "app-task-definition-role" {
  name = "app-task-definition-role"
  assume_role_policy = data.aws_iam_policy_document.app-task-definition-assume-role-policy.json
}

resource "aws_iam_role_policy_attachment" "app-tast-definition-policy" {
  role       = aws_iam_role.app-task-definition-role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_ecs_task_definition" "app-task-definition" {
  family = "app-task-definition"
  requires_compatibilities = [
    "FARGATE",
  ]

  execution_role_arn = aws_iam_role.app-task-definition-role.arn

  network_mode       = "awsvpc"
  cpu                = 256
  memory             = 512
  container_definitions = jsonencode([
    {
      name      = "app-task-definition"
      image     = "${aws_ecr_repository.repository.repository_url}:latest"
      essential = true
      cpu       = 256
      memory    = 512
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_security_group" "app_service_security_group" {
  name        = "app_service_sg"
  description = "Allow private inbound traffic"
  vpc_id      = var.public_load_balancer.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    security_groups = var.public_load_balancer.security_groups
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "App VPC - Private traffic from load balancer"
  }
}

resource "aws_ecs_service" "app-service" {
  name            = "app"
  cluster         = aws_ecs_cluster.ecs-cluster.id
  task_definition = aws_ecs_task_definition.app-task-definition.arn
  desired_count   = 1
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200

  deployment_circuit_breaker {
    enable = true
    rollback = true
  }
  network_configuration {
    security_groups = [aws_security_group.app_service_security_group.id]
    subnets          = var.public_load_balancer.subnets
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn =  var.public_load_balancer_target_group.arn
    container_name   = "app-task-definition"
    container_port   = 80
  }

  capacity_provider_strategy {
    base              = 0
    capacity_provider = "FARGATE"
    weight            = 100
  }
}
