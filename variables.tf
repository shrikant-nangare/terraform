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
variable "eks_cluster_role_arn" {
  description = "ARN of existing IAM role for EKS cluster. Leave empty to create new role. Required if you don't have iam:PassRole permission."
  type        = string
  default     = ""
}

variable "eks_node_group_role_arn" {
  description = "ARN of existing IAM role for EKS node group. Leave empty to create new role. Required if you don't have iam:PassRole permission."
  type        = string
  default     = ""
}

# EKS Variables
variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = ""
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.28"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS node groups (1 node in private subnet, 1 node in public subnet)"
  type        = string
  default     = "t3.small"
}
