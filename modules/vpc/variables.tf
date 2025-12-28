variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway for private subnets (allows outbound internet access)"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to assign to the resource"
  type        = map(string)
  default     = {}
}

variable "subnet_count" {
  description = "Number of public and private subnets to create (one per availability zone)"
  type        = number
  default     = 3
  validation {
    condition     = var.subnet_count >= 1 && var.subnet_count <= 6
    error_message = "Subnet count must be between 1 and 6 (AWS typically has 3-6 availability zones per region)."
  }
}

