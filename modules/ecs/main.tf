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
