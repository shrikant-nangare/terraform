variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC"
  type        = string
}

variable "private_subnet_ids" {
  description = "List of private subnet IDs for EKS cluster and node group"
  type        = list(string)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs for EKS node group"
  type        = list(string)
  default     = []
}

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster. AWS EKS standard support: 1.32, 1.33, 1.34. Extended support: 1.29, 1.30, 1.31"
  type        = string
  default     = "1.32"
}

variable "node_instance_type" {
  description = "EC2 instance type for EKS node group"
  type        = string
  default     = "t3.small"
}

variable "node_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 3
}

variable "endpoint_public_access" {
  description = "Whether the Amazon EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "endpoint_public_access_cidrs" {
  description = "List of CIDR blocks which can access the Amazon EKS public API server endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "enabled_cluster_log_types" {
  description = "List of the desired control plane logging to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

variable "log_retention_in_days" {
  description = "Number of days to retain log events in CloudWatch. Set to 0 to disable retention policy (avoids permission issues)"
  type        = number
  default     = 0
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for SSH access to nodes"
  type        = string
  default     = ""
}

variable "enable_remote_access" {
  description = "Enable remote access to nodes via SSH"
  type        = bool
  default     = false
}

variable "node_labels" {
  description = "Key-value map of Kubernetes labels to apply to nodes"
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

variable "cluster_role_arn" {
  description = "ARN of existing IAM role for EKS cluster. If provided, this role will be used instead of creating a new one. Required if you don't have iam:PassRole permission for custom roles."
  type        = string
  default     = ""
}

variable "node_group_role_arn" {
  description = "ARN of existing IAM role for EKS node group. If provided, this role will be used instead of creating a new one. Required if you don't have iam:PassRole permission for custom roles."
  type        = string
  default     = ""
}

# Fargate Configuration
variable "enable_fargate" {
  description = "Enable Fargate profiles instead of managed node groups. Recommended for resource-constrained environments."
  type        = bool
  default     = false
}

variable "fargate_profile_namespaces" {
  description = "List of Kubernetes namespaces to run on Fargate. Default includes 'default' and 'kube-system'."
  type        = list(string)
  default     = ["default", "kube-system"]
}

variable "fargate_pod_execution_role_arn" {
  description = "ARN of existing IAM role for Fargate pod execution. If empty and enable_fargate is true, a role will be created."
  type        = string
  default     = ""
}

