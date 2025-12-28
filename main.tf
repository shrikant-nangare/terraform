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

# EC2 Module (1 instance in public, 1 in private)
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

# Auto Scaling Group Module (CPU-based auto scaling)
module "asg" {
  source = "./modules/asg"

  project_name            = var.project_name
  public_subnet_id        = module.vpc.public_subnet_ids[0]
  private_subnet_id       = module.vpc.private_subnet_ids[0]
  public_security_group_id  = module.ec2.public_security_group_id
  private_security_group_id = module.ec2.private_security_group_id
  instance_type           = var.asg_instance_type
  key_pair_name           = var.key_pair_name
  min_size                = var.asg_min_size
  max_size                = var.asg_max_size
  desired_capacity        = var.asg_desired_capacity
  cpu_target              = var.asg_cpu_target
  user_data               = var.user_data
  tags                    = var.tags
}

# EKS Module (only create if cluster_name is provided and role ARNs are provided)
# Note: EKS requires iam:PassRole permission. If you don't have this, you must provide existing role ARNs.
module "eks" {
  source = "./modules/eks"
  count  = var.eks_cluster_name != "" && var.eks_cluster_role_arn != "" && var.eks_node_group_role_arn != "" ? 1 : 0

  project_name        = var.project_name
  cluster_name        = var.eks_cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  kubernetes_version  = var.eks_kubernetes_version
  node_instance_type  = var.eks_node_instance_type
  key_pair_name       = var.key_pair_name
  cluster_role_arn    = var.eks_cluster_role_arn
  node_group_role_arn = var.eks_node_group_role_arn
  tags                = var.tags
}
