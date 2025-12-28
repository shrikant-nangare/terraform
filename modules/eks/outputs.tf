output "cluster_id" {
  description = "ID of the EKS cluster"
  value       = aws_eks_cluster.main.id
}

output "cluster_arn" {
  description = "ARN of the EKS cluster"
  value       = aws_eks_cluster.main.arn
}

output "cluster_name" {
  description = "Name of the EKS cluster"
  value       = aws_eks_cluster.main.name
}

output "cluster_endpoint" {
  description = "Endpoint for EKS control plane"
  value       = aws_eks_cluster.main.endpoint
}

output "cluster_version" {
  description = "Kubernetes version of the EKS cluster"
  value       = aws_eks_cluster.main.version
}

output "cluster_security_group_id" {
  description = "Security group ID attached to the EKS cluster"
  value       = aws_security_group.cluster.id
}

output "private_node_group_id" {
  description = "ID of the EKS private node group"
  value       = aws_eks_node_group.private.id
}

output "private_node_group_arn" {
  description = "ARN of the EKS private node group"
  value       = aws_eks_node_group.private.arn
}

output "private_node_group_status" {
  description = "Status of the EKS private node group"
  value       = aws_eks_node_group.private.status
}

output "public_node_group_id" {
  description = "ID of the EKS public node group"
  value       = length(aws_eks_node_group.public) > 0 ? aws_eks_node_group.public[0].id : null
}

output "public_node_group_arn" {
  description = "ARN of the EKS public node group"
  value       = length(aws_eks_node_group.public) > 0 ? aws_eks_node_group.public[0].arn : null
}

output "public_node_group_status" {
  description = "Status of the EKS public node group"
  value       = length(aws_eks_node_group.public) > 0 ? aws_eks_node_group.public[0].status : null
}

output "node_group_security_group_id" {
  description = "Security group ID attached to the EKS node group"
  value       = aws_security_group.node_group.id
}

output "cluster_iam_role_arn" {
  description = "IAM role ARN of the EKS cluster"
  value       = aws_iam_role.cluster.arn
}

output "node_group_iam_role_arn" {
  description = "IAM role ARN of the EKS node group"
  value       = aws_iam_role.node_group.arn
}

output "cluster_certificate_authority_data" {
  description = "Base64 encoded certificate data required to communicate with the cluster"
  value       = aws_eks_cluster.main.certificate_authority[0].data
}

