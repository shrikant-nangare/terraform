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

# EKS IAM Roles (created with permitted names for restricted environments)
# These roles are created if they don't exist and use_eks_permitted_roles is true
resource "aws_iam_role" "eks_cluster" {
  count = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  name  = "eksClusterRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "eksClusterRole"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  count      = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  role       = aws_iam_role.eks_cluster[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "eks_node_group" {
  count = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  name  = "AmazonEKSNodeRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "AmazonEKSNodeRole"
    }
  )
}

resource "aws_iam_role_policy_attachment" "eks_node_worker_policy" {
  count      = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "eks_node_cni_policy" {
  count      = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "eks_node_registry_policy" {
  count      = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  role       = aws_iam_role.eks_node_group[0].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

# Local values for EKS role ARNs
# If use_eks_permitted_roles is true, use the roles created in root module
# Otherwise, use the provided ARNs (or empty string to let EKS module create them)
locals {
  # When use_eks_permitted_roles is true, use the root module's roles
  # When false, use the provided ARNs from variables
  eks_cluster_role_arn = var.use_eks_permitted_roles && var.eks_cluster_name != "" ? (
    try(aws_iam_role.eks_cluster[0].arn, var.eks_cluster_role_arn)
  ) : var.eks_cluster_role_arn
  
  eks_node_group_role_arn = var.use_eks_permitted_roles && var.eks_cluster_name != "" ? (
    try(aws_iam_role.eks_node_group[0].arn, var.eks_node_group_role_arn)
  ) : var.eks_node_group_role_arn
}

# VPC Module
module "vpc" {
  source = "./modules/vpc"

  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr
  enable_nat_gateway = var.enable_nat_gateway
  subnet_count       = var.vpc_subnet_count
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

# EKS Module (only create if cluster_name is provided)
# Note: If you don't have iam:PassRole permission, you must provide existing role ARNs.
# Otherwise, the module will create IAM roles automatically.
module "eks" {
  source = "./modules/eks"
  count  = var.eks_cluster_name != "" ? 1 : 0

  project_name        = var.project_name
  cluster_name        = var.eks_cluster_name
  vpc_id              = module.vpc.vpc_id
  private_subnet_ids  = module.vpc.private_subnet_ids
  public_subnet_ids   = module.vpc.public_subnet_ids
  kubernetes_version  = var.eks_kubernetes_version
  node_instance_type  = var.eks_node_instance_type
  key_pair_name       = var.key_pair_name
  cluster_role_arn    = local.eks_cluster_role_arn
  node_group_role_arn = local.eks_node_group_role_arn
  tags                = var.tags
}
