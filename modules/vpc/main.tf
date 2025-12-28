# VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-vpc"
    }
  )
}

# Internet Gateway
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-igw"
    }
  )
}

# Local value to calculate subnet bits needed
locals {
  # Calculate number of bits needed for subnet_count * 2 subnets (public + private)
  # Formula: ceil(log2(subnet_count * 2))
  # Terraform log function: log(num, base)
  subnet_bits = ceil(log(var.subnet_count * 2, 2))
}

# Public Subnets
resource "aws_subnet" "public" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, local.subnet_bits, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-subnet-${count.index + 1}"
      Type = "public"
    }
  )
}

# Private Subnets
resource "aws_subnet" "private" {
  count                   = var.subnet_count
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpc_cidr, local.subnet_bits, count.index + var.subnet_count)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = false

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-subnet-${count.index + 1}"
      Type = "private"
    }
  )
}

# Elastic IPs for NAT Gateways
resource "aws_eip" "nat" {
  count  = var.enable_nat_gateway ? var.subnet_count : 0
  domain = "vpc"

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-eip-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# NAT Gateways (one per public subnet)
resource "aws_nat_gateway" "main" {
  count         = var.enable_nat_gateway ? var.subnet_count : 0
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-nat-gateway-${count.index + 1}"
    }
  )

  depends_on = [aws_internet_gateway.main]
}

# Route Table for Public Subnets
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-public-rt"
    }
  )
}

# Route Table Associations for Public Subnets
resource "aws_route_table_association" "public" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Route Tables for Private Subnets
resource "aws_route_table" "private" {
  count  = var.subnet_count
  vpc_id = aws_vpc.main.id

  dynamic "route" {
    for_each = var.enable_nat_gateway ? [1] : []
    content {
      cidr_block     = "0.0.0.0/0"
      nat_gateway_id = aws_nat_gateway.main[count.index].id
    }
  }

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-private-rt-${count.index + 1}"
    }
  )
}

# Route Table Associations for Private Subnets
resource "aws_route_table_association" "private" {
  count          = var.subnet_count
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}

