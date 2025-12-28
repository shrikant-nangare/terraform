# Terraform Commands to Launch EKS Cluster Only

This guide shows how to use Terraform to create only the EKS cluster and related resources, without creating EC2 instances or ASG.

## Prerequisites

Before launching EKS, ensure:
1. **VPC exists** - EKS requires a VPC with subnets
2. **IAM Roles exist** - EKS needs cluster and node group roles
3. **EKS is enabled** - `eks_cluster_name` is set in `terraform.tfvars`

## Option 1: Target EKS Module (Recommended)

Target the entire EKS module, which will create all EKS resources:

```bash
# Plan what will be created
terraform plan -target=module.eks[0]

# Apply to create EKS cluster
terraform apply -target=module.eks[0]
```

This will create:
- EKS cluster
- EKS node groups (private and public)
- Security groups for EKS
- IAM roles (if `use_eks_permitted_roles = true`)

## Option 2: Target Specific EKS Resources

If you need more granular control, target specific resources:

```bash
# First, ensure VPC exists (if not already created)
terraform apply -target=module.vpc

# Create EKS IAM roles (if using permitted roles)
terraform apply -target=aws_iam_role.eks_cluster[0] -target=aws_iam_role.eks_node_group[0]
terraform apply -target=aws_iam_role_policy_attachment.eks_cluster_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_worker_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_cni_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_registry_policy[0]

# Create EKS cluster
terraform apply -target=module.eks[0].aws_eks_cluster.main

# Create EKS node groups
terraform apply -target=module.eks[0].aws_eks_node_group.private \
  -target=module.eks[0].aws_eks_node_group.public
```

## Option 3: Complete Sequence (VPC + EKS)

If VPC doesn't exist yet, create it first, then EKS:

```bash
# Step 1: Create VPC and networking (required for EKS)
terraform apply -target=module.vpc

# Step 2: Create EKS IAM roles (if needed)
terraform apply -target=aws_iam_role.eks_cluster[0] -target=aws_iam_role.eks_node_group[0]

# Step 3: Create EKS cluster and node groups
terraform apply -target=module.eks[0]
```

## Verify EKS Resources

After applying, verify the cluster:

```bash
# Check Terraform state
terraform state list | grep eks

# Verify cluster via AWS CLI
aws eks describe-cluster --name myekscluster

# List node groups
aws eks list-nodegroups --cluster-name myekscluster
```

## Important Notes

### Dependencies

EKS has dependencies on:
- **VPC Module** (`module.vpc`) - Must exist first
- **IAM Roles** - Must exist before cluster creation
- **Security Groups** - Created automatically by EKS module

### IAM Roles

If `use_eks_permitted_roles = true` in `terraform.tfvars`:
- Terraform will create `eksClusterRole` and `AmazonEKSNodeRole`
- These must be created before the EKS cluster

If `use_eks_permitted_roles = false`:
- You must provide existing role ARNs in `terraform.tfvars`
- Roles must already exist in AWS

### Resource Addresses

The EKS module uses `count`, so resources are addressed as:
- `module.eks[0]` - The module itself
- `module.eks[0].aws_eks_cluster.main` - The cluster
- `module.eks[0].aws_eks_node_group.private` - Private node group
- `module.eks[0].aws_eks_node_group.public` - Public node group

## Example: Full EKS-Only Deployment

```bash
# 1. Initialize Terraform (if not done)
terraform init

# 2. Plan EKS resources
terraform plan -target=module.eks[0]

# 3. Create VPC first (if needed)
terraform apply -target=module.vpc

# 4. Create EKS IAM roles (if using permitted roles)
terraform apply \
  -target=aws_iam_role.eks_cluster[0] \
  -target=aws_iam_role.eks_node_group[0] \
  -target=aws_iam_role_policy_attachment.eks_cluster_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_worker_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_cni_policy[0] \
  -target=aws_iam_role_policy_attachment.eks_node_registry_policy[0]

# 5. Create EKS cluster and node groups
terraform apply -target=module.eks[0]

# 6. Verify
aws eks describe-cluster --name myekscluster
```

## Troubleshooting

### Error: VPC not found
**Solution**: Create VPC first:
```bash
terraform apply -target=module.vpc
```

### Error: IAM role not found
**Solution**: Create IAM roles first or provide existing role ARNs in `terraform.tfvars`

### Error: Subnet not found
**Solution**: Ensure VPC module is applied and subnets exist

### Check what will be created
```bash
# See plan for EKS only
terraform plan -target=module.eks[0]

# See all resources
terraform state list
```

## Quick Reference

| Command | Purpose |
|---------|---------|
| `terraform plan -target=module.eks[0]` | Preview EKS resources |
| `terraform apply -target=module.eks[0]` | Create EKS cluster and nodes |
| `terraform destroy -target=module.eks[0]` | Destroy only EKS resources |
| `terraform state list \| grep eks` | List EKS resources in state |

---

**Last Updated**: 2025-12-28

