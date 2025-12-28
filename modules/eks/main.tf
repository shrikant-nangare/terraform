# IAM Role for EKS Cluster (only create if existing role not provided)
resource "aws_iam_role" "cluster" {
  count = var.cluster_role_arn == "" ? 1 : 0
  name  = "${var.project_name}-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-cluster-role"
    }
  )
}

# Attach AWS managed policy for EKS cluster
resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  count      = var.cluster_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster[0].name
}

# Local values for role ARNs (either existing or created)
locals {
  cluster_role_arn = var.cluster_role_arn != "" ? var.cluster_role_arn : aws_iam_role.cluster[0].arn
  node_group_role_arn = var.node_group_role_arn != "" ? var.node_group_role_arn : aws_iam_role.node_group[0].arn
}

# IAM Role for EKS Node Group (only create if existing role not provided)
resource "aws_iam_role" "node_group" {
  count = var.node_group_role_arn == "" ? 1 : 0
  name  = "${var.project_name}-eks-node-group-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.tags,
    {
      Name = "${var.project_name}-eks-node-group-role"
    }
  )
}

# Attach AWS managed policies for EKS node group
resource "aws_iam_role_policy_attachment" "node_group_AmazonEKSWorkerNodePolicy" {
  count      = var.node_group_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEKS_CNI_Policy" {
  count      = var.node_group_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_group[0].name
}

resource "aws_iam_role_policy_attachment" "node_group_AmazonEC2ContainerRegistryReadOnly" {
  count      = var.node_group_role_arn == "" ? 1 : 0
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_group[0].name
}


# Security Group for EKS Cluster
resource "aws_security_group" "cluster" {
  name        = "${var.project_name}-eks-cluster-sg"
  description = "Security group for EKS cluster"
  vpc_id      = var.vpc_id

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
      Name = "${var.project_name}-eks-cluster-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}


# Security Group for EKS Private Node Group
resource "aws_security_group" "node_group" {
  name        = "${var.project_name}-eks-private-node-group-sg"
  description = "Security group for EKS private node group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow cluster to communicate with nodes"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
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
      Name = "${var.project_name}-eks-private-node-group-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

# Security Group for EKS Public Node Group
resource "aws_security_group" "public_node_group" {
  count       = length(var.public_subnet_ids) > 0 ? 1 : 0
  name        = "${var.project_name}-eks-public-node-group-sg"
  description = "Security group for EKS public node group"
  vpc_id      = var.vpc_id

  ingress {
    description     = "Allow cluster to communicate with nodes"
    from_port       = 1025
    to_port         = 65535
    protocol        = "tcp"
    security_groups = [aws_security_group.cluster.id]
  }

  ingress {
    description = "Allow nodes to communicate with each other"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  ingress {
    description     = "Allow private nodes to communicate with public nodes"
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.node_group.id]
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
      Name = "${var.project_name}-eks-public-node-group-sg"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )
}

# Security Group Rules: Allow nodes to communicate with cluster
resource "aws_security_group_rule" "cluster_ingress_private_nodes" {
  description              = "Allow private nodes to communicate with cluster"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.node_group.id
  to_port                  = 443
  type                     = "ingress"
}

resource "aws_security_group_rule" "cluster_ingress_public_nodes" {
  count                    = length(var.public_subnet_ids) > 0 ? 1 : 0
  description              = "Allow public nodes to communicate with cluster"
  from_port                = 443
  protocol                 = "tcp"
  security_group_id        = aws_security_group.cluster.id
  source_security_group_id = aws_security_group.public_node_group[0].id
  to_port                  = 443
  type                     = "ingress"
}

# EKS Cluster
resource "aws_eks_cluster" "main" {
  name     = var.cluster_name
  role_arn = local.cluster_role_arn
  version  = var.kubernetes_version

  vpc_config {
    subnet_ids              = concat(var.private_subnet_ids, var.public_subnet_ids)
    endpoint_private_access = true
    endpoint_public_access  = var.endpoint_public_access
    public_access_cidrs    = var.endpoint_public_access_cidrs
    security_group_ids      = [aws_security_group.cluster.id]
  }

  enabled_cluster_log_types = var.enabled_cluster_log_types

  # Dependencies are handled implicitly through role_arn reference in local.cluster_role_arn
  # If creating role, the role and its policies will be ready before cluster creation

  tags = merge(
    var.tags,
    {
      Name = var.cluster_name
    }
  )
}

# Note: CloudWatch Log Group is automatically created by EKS when enabled_cluster_log_types is set
# We don't manage it via Terraform to avoid permission issues (logs:PutRetentionPolicy, logs:DeleteLogGroup)
# The log group will be created at: /aws/eks/${var.cluster_name}/cluster
# If you need to manage retention, do it via AWS Console or CLI after the cluster is created

# EKS Private Node Group (1 node in private subnet)
resource "aws_eks_node_group" "private" {
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-private-node-group"
  node_role_arn   = local.node_group_role_arn
  subnet_ids      = [var.private_subnet_ids[0]]  # Use first private subnet
  instance_types  = [var.node_instance_type]
  disk_size       = 6

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  remote_access {
    ec2_ssh_key               = var.key_pair_name != "" ? var.key_pair_name : null
    source_security_group_ids = var.enable_remote_access ? [aws_security_group.node_group.id] : []
  }

  labels = merge(
    var.node_labels,
    {
      "subnet-type" = "private"
    }
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-private-node-group"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # Dependencies are handled implicitly through role_arn reference in local.node_group_role_arn
  # If creating role, the role and its policies will be ready before node group creation
}

# EKS Public Node Group (1 node in public subnet)
resource "aws_eks_node_group" "public" {
  count           = length(var.public_subnet_ids) > 0 ? 1 : 0
  cluster_name    = aws_eks_cluster.main.name
  node_group_name = "${var.cluster_name}-public-node-group"
  node_role_arn   = local.node_group_role_arn
  subnet_ids      = [var.public_subnet_ids[0]]  # Use first public subnet
  instance_types  = [var.node_instance_type]
  disk_size       = 6

  scaling_config {
    desired_size = var.node_desired_size
    max_size     = var.node_max_size
    min_size     = var.node_min_size
  }

  update_config {
    max_unavailable = 1
  }

  remote_access {
    ec2_ssh_key               = var.key_pair_name != "" ? var.key_pair_name : null
    source_security_group_ids = var.enable_remote_access && length(aws_security_group.public_node_group) > 0 ? [aws_security_group.public_node_group[0].id] : []
  }

  labels = merge(
    var.node_labels,
    {
      "subnet-type" = "public"
    }
  )

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_name}-public-node-group"
      "kubernetes.io/cluster/${var.cluster_name}" = "owned"
    }
  )

  # Dependencies are handled implicitly through role_arn reference in local.node_group_role_arn
  # If creating role, the role and its policies will be ready before node group creation
}

