output "public_instance_ids" {
  description = "IDs of the EC2 instances in public subnets"
  value       = aws_instance.public[*].id
}

output "private_instance_ids" {
  description = "IDs of the EC2 instances in private subnets"
  value       = aws_instance.private[*].id
}

output "public_instance_private_ips" {
  description = "Private IP addresses of the EC2 instances in public subnets"
  value       = aws_instance.public[*].private_ip
}

output "private_instance_private_ips" {
  description = "Private IP addresses of the EC2 instances in private subnets"
  value       = aws_instance.private[*].private_ip
}

output "public_instance_public_ips" {
  description = "Public IP addresses of the EC2 instances in public subnets"
  value       = aws_instance.public[*].public_ip
}

output "public_security_group_id" {
  description = "ID of the security group for public instances"
  value       = aws_security_group.public_instances.id
}

output "private_security_group_id" {
  description = "ID of the security group for private instances"
  value       = aws_security_group.private_instances.id
}

