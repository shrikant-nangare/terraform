# EKS Setup Guide

This guide explains how to set up an Amazon EKS (Elastic Kubernetes Service) cluster using this Terraform infrastructure.

## Overview

The infrastructure supports creating an EKS cluster with:
- Managed Kubernetes control plane
- Node groups in public and private subnets
- Configurable node scaling
- Support for existing IAM roles or automatic role creation

## Prerequisites

- AWS account with appropriate permissions
- Terraform >= 1.0
- AWS CLI configured
- kubectl installed (for cluster access)

## Quick Start

### Step 1: Configure EKS in terraform.tfvars

```hcl
# Enable EKS cluster
eks_cluster_name = "myekscluster"

# Kubernetes version (AWS EKS standard support: 1.32, 1.33, 1.34)
eks_kubernetes_version = "1.32"

# Node configuration
eks_node_instance_type = "t3.small"
eks_node_desired_size = 2
eks_node_min_size = 1
eks_node_max_size = 3
```

### Step 2: Configure IAM Roles

Choose one of two approaches:

#### Option A: Let Terraform Create Roles (Recommended if permitted)

```hcl
# Create roles with permitted names
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

#### Option B: Use Existing Roles

```hcl
# Use existing roles
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/AmazonEKSNodeRole"
```

See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for detailed IAM role configuration.

### Step 3: Deploy

```bash
terraform init
terraform plan
terraform apply
```

### Step 4: Configure kubectl

After deployment, configure kubectl to access your cluster:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name myekscluster

# Verify access
kubectl get nodes
```

## Configuration Options

### EKS Cluster Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `eks_cluster_name` | Name of the EKS cluster (empty to disable) | `""` |
| `eks_kubernetes_version` | Kubernetes version | `"1.32"` |
| `use_eks_permitted_roles` | Create roles with permitted names | `true` |
| `eks_cluster_role_arn` | ARN of existing cluster role | `""` |
| `eks_node_group_role_arn` | ARN of existing node group role | `""` |

### Node Group Configuration

| Variable | Description | Default |
|----------|-------------|---------|
| `eks_node_instance_type` | EC2 instance type for nodes | `"t3.small"` |
| `eks_node_desired_size` | Desired number of nodes per group | `2` |
| `eks_node_min_size` | Minimum number of nodes per group | `1` |
| `eks_node_max_size` | Maximum number of nodes per group | `3` |

### Kubernetes Version Support

AWS EKS supports the following Kubernetes versions:

**Standard Support:**
- 1.32
- 1.33
- 1.34

**Extended Support:**
- 1.29
- 1.30
- 1.31

Use the latest standard support version for new clusters.

## IAM Roles Setup

The infrastructure supports two approaches for IAM roles:

### Approach 1: Permitted Role Names (Default)

If your environment allows creating IAM roles with specific names (`eksClusterRole` and `AmazonEKSNodeRole`):

```hcl
use_eks_permitted_roles = true
```

Terraform will automatically create:
- **Cluster Role**: `eksClusterRole` with `AmazonEKSClusterPolicy`
- **Node Role**: `AmazonEKSNodeRole` with required worker policies

### Approach 2: Existing Roles

If you need to use existing roles or don't have permission to create roles:

```hcl
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-CLUSTER-ROLE"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-NODE-ROLE"
```

**Finding Existing Roles:**

```bash
# List EKS-related roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table

# Check specific roles
aws iam get-role --role-name eksClusterRole --query 'Role.Arn' --output text
aws iam get-role --role-name AmazonEKSNodeRole --query 'Role.Arn' --output text
```

For detailed IAM role setup, see [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md).

## Node Groups

The infrastructure creates two node groups:

1. **Private Node Group**: Nodes in private subnets
   - No direct internet access
   - Outbound access via NAT Gateway
   - Label: `subnet-type=private`

2. **Public Node Group**: Nodes in public subnets
   - Direct internet access
   - Public IP addresses
   - Label: `subnet-type=public`

Both node groups:
- Use the same instance type and scaling configuration
- Support SSH access (if key pair is configured)
- Have proper security group rules for cluster communication

## Security Configuration

### Endpoint Access

The EKS cluster endpoint is configured with:
- **Private endpoint**: Always enabled
- **Public endpoint**: Enabled by default (configurable in module)

To restrict public endpoint access, modify the EKS module variables:

```hcl
# In modules/eks/variables.tf (or via module override)
endpoint_public_access = false
# OR
endpoint_public_access_cidrs = ["YOUR_IP/32"]
```

### Security Groups

The infrastructure automatically configures security groups for:
- Cluster-to-node communication (port 443)
- Node-to-node communication (ports 1025-65535)
- Node-to-cluster communication

### SSH Access

To enable SSH access to nodes:

```hcl
key_pair_name = "your-key-pair-name"
```

SSH access is configured via the node group's `remote_access` setting.

## Monitoring and Logging

### CloudWatch Logging

EKS cluster logging is enabled by default for:
- API server
- Audit logs
- Authenticator
- Controller manager
- Scheduler

Logs are sent to CloudWatch Log Group: `/aws/eks/{cluster-name}/cluster`

### Viewing Logs

```bash
# List log streams
aws logs describe-log-streams --log-group-name /aws/eks/myekscluster/cluster

# View logs
aws logs tail /aws/eks/myekscluster/cluster --follow
```

## Troubleshooting

### Error: "User is not authorized to perform: iam:PassRole"

**Cause**: You don't have permission to pass IAM roles to EKS.

**Solution**: 
- Use existing roles that you have permission to pass
- Set `use_eks_permitted_roles = false` and provide role ARNs
- See [FIX_EKS_IAM_ERROR.md](./FIX_EKS_IAM_ERROR.md) for details

### Error: "InvalidParameterException: Role is not authorized"

**Cause**: The IAM role doesn't have correct trust policy or policies.

**Solution**:
- Verify the role has trust policy for `eks.amazonaws.com` (cluster) or `ec2.amazonaws.com` (nodes)
- Ensure required AWS managed policies are attached
- See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for required permissions

### Nodes Not Joining Cluster

**Cause**: Common issues with node registration.

**Solutions**:
1. **Check IAM permissions**: Nodes need proper IAM role with worker policies
2. **Verify security groups**: Ensure cluster and node security groups allow communication
3. **Check subnet tags**: EKS requires specific subnet tags (automatically handled)
4. **Review node logs**: SSH to node and check `/var/log/messages` or `journalctl -u kubelet`

### Cluster Endpoint Not Accessible

**Cause**: Network or security group configuration.

**Solutions**:
1. **Check security groups**: Ensure your IP is allowed (if public endpoint)
2. **Verify VPC configuration**: Ensure subnets are properly configured
3. **Check endpoint settings**: Verify `endpoint_public_access` and `endpoint_public_access_cidrs`

### kubectl Access Issues

**Cause**: kubeconfig not configured or expired credentials.

**Solutions**:
```bash
# Update kubeconfig
aws eks update-kubeconfig --region REGION --name CLUSTER_NAME

# Verify AWS credentials
aws sts get-caller-identity

# Test cluster access
kubectl get nodes
```

## Disabling EKS

To disable EKS and avoid creating the cluster:

```hcl
# In terraform.tfvars
eks_cluster_name = ""  # Empty string disables EKS
```

When `eks_cluster_name` is empty, the EKS module is not created.

## Post-Deployment Tasks

After deploying the EKS cluster:

1. **Configure kubectl**: `aws eks update-kubeconfig --region REGION --name CLUSTER_NAME`
2. **Verify nodes**: `kubectl get nodes`
3. **Deploy applications**: Use standard Kubernetes manifests or Helm charts
4. **Set up monitoring**: Consider CloudWatch Container Insights or Prometheus
5. **Configure ingress**: Set up ALB Ingress Controller or similar
6. **Review security**: Audit security groups and IAM roles

## Additional Resources

- [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) - Detailed IAM role configuration
- [ENABLE_EKS_STEPS.md](./ENABLE_EKS_STEPS.md) - Step-by-step enablement guide
- [FIX_EKS_IAM_ERROR.md](./FIX_EKS_IAM_ERROR.md) - Troubleshooting IAM errors
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Last Updated**: 2025-12-28
