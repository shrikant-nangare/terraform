output "public_asg_id" {
  description = "ID of the public Auto Scaling Group"
  value       = aws_autoscaling_group.public.id
}

output "public_asg_name" {
  description = "Name of the public Auto Scaling Group"
  value       = aws_autoscaling_group.public.name
}

output "public_asg_arn" {
  description = "ARN of the public Auto Scaling Group"
  value       = aws_autoscaling_group.public.arn
}

output "private_asg_id" {
  description = "ID of the private Auto Scaling Group"
  value       = aws_autoscaling_group.private.id
}

output "private_asg_name" {
  description = "Name of the private Auto Scaling Group"
  value       = aws_autoscaling_group.private.name
}

output "private_asg_arn" {
  description = "ARN of the private Auto Scaling Group"
  value       = aws_autoscaling_group.private.arn
}

output "public_launch_template_id" {
  description = "ID of the public launch template"
  value       = aws_launch_template.public.id
}

output "private_launch_template_id" {
  description = "ID of the private launch template"
  value       = aws_launch_template.private.id
}

output "asg_iam_role_arn" {
  description = "ARN of the IAM role for ASG instances"
  value       = aws_iam_role.asg.arn
}

