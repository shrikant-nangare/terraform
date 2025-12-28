variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "public_subnet_id" {
  description = "ID of the public subnet for ASG"
  type        = string
}

variable "private_subnet_id" {
  description = "ID of the private subnet for ASG"
  type        = string
}

variable "public_security_group_id" {
  description = "Security group ID for public ASG instances"
  type        = string
}

variable "private_security_group_id" {
  description = "Security group ID for private ASG instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for ASG instances"
  type        = string
  default     = "t3.micro"
}

variable "key_pair_name" {
  description = "Name of the AWS key pair to use for ASG instances"
  type        = string
  default     = ""
}

variable "min_size" {
  description = "Minimum number of instances in ASG"
  type        = number
  default     = 1
}

variable "max_size" {
  description = "Maximum number of instances in ASG"
  type        = number
  default     = 5
}

variable "desired_capacity" {
  description = "Desired number of instances in ASG"
  type        = number
  default     = 1
}

variable "cpu_target" {
  description = "Target CPU utilization percentage for auto scaling"
  type        = number
  default     = 60
}

variable "user_data" {
  description = "User data script to run on instance launch"
  type        = string
  default     = ""
}

variable "tags" {
  description = "A map of tags to assign to all resources"
  type        = map(string)
  default     = {}
}

