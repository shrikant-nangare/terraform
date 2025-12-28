# Data source for latest Amazon Linux 2 AMI
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Security Group for Public Instances
resource "aws_security_group" "public_instances" {
  name        = "${var.project_name}-public-instances-sg"
  description = "Security group for instances in public subnets"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.ssh_allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-instances-sg"
    }
  )
}

# Security Group for Private Instances
resource "aws_security_group" "private_instances" {
  name        = "${var.project_name}-private-instances-sg"
  description = "Security group for instances in private subnets"
  vpc_id      = var.vpc_id

  ingress {
    description     = "SSH from public subnets"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_instances.id]
  }

  ingress {
    description = "All traffic from VPC"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-instances-sg"
    }
  )
}

# EC2 Instances in Public Subnets
resource "aws_instance" "public" {
  count                  = length(var.public_subnet_ids)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.public_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.public_instances.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  user_data              = var.user_data != "" ? var.user_data : null

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-instance-${count.index + 1}"
      Type = "public"
    }
  )
}

# EC2 Instances in Private Subnets
resource "aws_instance" "private" {
  count                  = length(var.private_subnet_ids)
  ami                    = data.aws_ami.amazon_linux.id
  instance_type          = var.instance_type
  subnet_id              = var.private_subnet_ids[count.index]
  vpc_security_group_ids = [aws_security_group.private_instances.id]
  key_name               = var.key_pair_name != "" ? var.key_pair_name : null
  user_data              = var.user_data != "" ? var.user_data : null

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-instance-${count.index + 1}"
      Type = "private"
    }
  )
}

