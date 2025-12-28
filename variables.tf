variable "aws_region" {
  description = "AWS region for resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
  default     = "my-project"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (allows outbound internet access)"
  type        = bool
  default     = true
}

variable "vpc_subnet_count" {
  description = "Number of public and private subnets to create (one per availability zone)"
  type        = number
  default     = 3
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for EC2 instances"
  type        = string
  default     = ""
}

variable "ssh_allowed_cidr" {
  description = "CIDR block allowed to SSH to public instances"
  type        = string
  default     = "0.0.0.0/0"
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

# ASG Variables
variable "asg_instance_type" {
  description = "EC2 instance type for ASG instances"
  type        = string
  default     = "t3.micro"
}

variable "asg_min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 5
}

variable "asg_desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "asg_cpu_target" {
  description = "Target CPU utilization percentage for auto scaling (default: 60%)"
  type        = number
  default     = 60
}

# EKS IAM Role Variables (for restricted environments)
variable "use_eks_permitted_roles" {
  description = "If true, Terraform will create EKS roles with permitted names (eksClusterRole, AmazonEKSNodeRole). If false, use existing roles via eks_cluster_role_arn and eks_node_group_role_arn."
  type        = bool
  default     = true
}

variable "eks_cluster_role_arn" {
  description = "ARN or name of existing IAM role for EKS cluster. Used only if use_eks_permitted_roles is false. Can be full ARN (arn:aws:iam::ACCOUNT:role/NAME) or just role name (Terraform will auto-detect account ID). Leave empty to let Terraform create roles with permitted names."
  type        = string
  default     = ""
}

variable "eks_node_group_role_arn" {
  description = "ARN or name of existing IAM role for EKS node group. Used only if use_eks_permitted_roles is false. Can be full ARN (arn:aws:iam::ACCOUNT:role/NAME) or just role name (Terraform will auto-detect account ID). Leave empty to let Terraform create roles with permitted names."
  type        = string
  default     = ""
}

# EKS Variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "myekscluster"
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the EKS cluster. AWS EKS standard support: 1.32, 1.33, 1.34. Extended support: 1.29, 1.30, 1.31"
  type        = string
  default     = "1.32"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS node groups (1 node in private subnet, 1 node in public subnet)"
  type        = string
  default     = "t3.small"
}

variable "eks_node_desired_size" {
  description = "Desired number of nodes in each EKS node group"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of nodes in each EKS node group"
  type        = number
  default     = 1
}

variable "eks_node_max_size" {
  description = "Maximum number of nodes in each EKS node group"
  type        = number
  default     = 3
}
