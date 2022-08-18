terraform {
  backend "s3" {
    bucket         = "terraform-app-state"
    key            = "terraform.tfstate"
    region         = "us-west-2"
    encrypt        = true
    dynamodb_table = "terraform-app-state-locks"
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region = var.region
}

module "terraform_state" {
  source = "./modules/terraform_state"
}

module "vpc" {
  source = "./modules/vpc"

  cidr_block = var.main_vpc_cidr_block
}

module "load_balancer" {
  source = "./modules/load_balancer"

  vpc_id  = module.vpc.vpc_id
  subnets = module.vpc.subnets
}

module "ecs" {
  source = "./modules/ecs"

  region                            = var.region
  service_name                      = "app"
  public_load_balancer              = module.load_balancer.public_load_balancer
  public_load_balancer_target_group = module.load_balancer.public_load_balancer_target_group
}
