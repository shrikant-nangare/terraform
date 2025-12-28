output "vpc_id" {
  description = "ID of the VPC"
  value       = module.vpc.vpc_id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.vpc.vpc_cidr_block
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.vpc.public_subnet_ids
}

output "private_subnet_ids" {
  description = "IDs of the private subnets"
  value       = module.vpc.private_subnet_ids
}

output "public_subnet_cidrs" {
  description = "CIDR blocks of the public subnets"
  value       = module.vpc.public_subnet_cidrs
}

output "private_subnet_cidrs" {
  description = "CIDR blocks of the private subnets"
  value       = module.vpc.private_subnet_cidrs
}

output "internet_gateway_id" {
  description = "ID of the Internet Gateway"
  value       = module.vpc.internet_gateway_id
}

output "nat_gateway_ids" {
  description = "IDs of the NAT Gateways"
  value       = module.vpc.nat_gateway_ids
}

output "public_route_table_id" {
  description = "ID of the public route table"
  value       = module.vpc.public_route_table_id
}

output "private_route_table_ids" {
  description = "IDs of the private route tables"
  value       = module.vpc.private_route_table_ids
}

output "public_instance_id" {
  description = "ID of the EC2 instance in public subnet"
  value       = module.ec2.public_instance_id
}

output "private_instance_id" {
  description = "ID of the EC2 instance in private subnet"
  value       = module.ec2.private_instance_id
}

output "public_instance_private_ip" {
  description = "Private IP address of the EC2 instance in public subnet"
  value       = module.ec2.public_instance_private_ip
}

output "private_instance_private_ip" {
  description = "Private IP address of the EC2 instance in private subnet"
  value       = module.ec2.private_instance_private_ip
}

output "public_instance_public_ip" {
  description = "Public IP address of the EC2 instance in public subnet"
  value       = module.ec2.public_instance_public_ip
}

# ASG Outputs
output "public_asg_id" {
  description = "ID of the public Auto Scaling Group"
  value       = module.asg.public_asg_id
}

output "public_asg_name" {
  description = "Name of the public Auto Scaling Group"
  value       = module.asg.public_asg_name
}

output "private_asg_id" {
  description = "ID of the private Auto Scaling Group"
  value       = module.asg.private_asg_id
}

output "private_asg_name" {
  description = "Name of the private Auto Scaling Group"
  value       = module.asg.private_asg_name
}

output "public_security_group_id" {
  description = "ID of the security group for public instances"
  value       = module.ec2.public_security_group_id
}

output "private_security_group_id" {
  description = "ID of the security group for private instances"
  value       = module.ec2.private_security_group_id
}

# EKS Outputs (only output if EKS module is created)
output "eks_cluster_id" {
  description = "ID of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_id : null
}

output "eks_cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_arn : null
}

output "eks_cluster_name" {
  description = "Name of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_name : null
}

output "eks_cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_endpoint : null
}

output "eks_cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = length(module.eks) > 0 ? module.eks[0].cluster_version : null
}

output "eks_private_node_group_id" {
  description = "ID of the EKS private node group"
  value       = length(module.eks) > 0 ? module.eks[0].private_node_group_id : null
}

output "eks_public_node_group_id" {
  description = "ID of the EKS public node group"
  value       = length(module.eks) > 0 ? module.eks[0].public_node_group_id : null
}

# EKS IAM Role Outputs
output "eks_cluster_role_arn" {
  description = "ARN of the EKS cluster IAM role"
  value       = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? (length(aws_iam_role.eks_cluster) > 0 ? aws_iam_role.eks_cluster[0].arn : null) : local.eks_cluster_role_arn
}

output "eks_node_group_role_arn" {
  description = "ARN of the EKS node group IAM role"
  value       = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? (length(aws_iam_role.eks_node_group) > 0 ? aws_iam_role.eks_node_group[0].arn : null) : local.eks_node_group_role_arn
}
