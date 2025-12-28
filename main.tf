terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.23"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  tags               = var.tags
}

# EC2 Module
module "ec2" {
  source = "./modules/ec2"

  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type
  key_pair_name      = var.key_pair_name
  ssh_allowed_cidr   = var.ssh_allowed_cidr
  user_data          = var.user_data
  tags               = var.tags
}

# EKS Module
module "eks" {
  source = "./modules/eks"

  project_name       = var.project_name
  cluster_name       = var.eks_cluster_name != "" ? var.eks_cluster_name : "${var.project_name}-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  kubernetes_version = var.eks_kubernetes_version
  node_instance_type = var.eks_node_instance_type
  key_pair_name      = var.key_pair_name
  tags               = var.tags
}
