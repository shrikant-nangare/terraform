output "public_instance_id" {
  description = "ID of the EC2 instance in public subnet"
  value       = aws_instance.public.id
}

output "private_instance_id" {
  description = "ID of the EC2 instance in private subnet"
  value       = aws_instance.private.id
}

output "public_instance_private_ip" {
  description = "Private IP address of the EC2 instance in public subnet"
  value       = aws_instance.public.private_ip
}

output "private_instance_private_ip" {
  description = "Private IP address of the EC2 instance in private subnet"
  value       = aws_instance.private.private_ip
}

output "public_instance_public_ip" {
  description = "Public IP address of the EC2 instance in public subnet"
  value       = aws_instance.public.public_ip
}

output "public_security_group_id" {
  description = "ID of the security group for public instances"
  value       = aws_security_group.public_instances.id
}

output "private_security_group_id" {
  description = "ID of the security group for private instances"
  value       = aws_security_group.private_instances.id
}

