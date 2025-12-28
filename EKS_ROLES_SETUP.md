# EKS IAM Roles Setup Guide

This guide explains how to configure IAM roles for EKS cluster and node groups in this Terraform infrastructure.

## Overview

The infrastructure supports two approaches for EKS IAM roles:

1. **Create roles with permitted names** (if you have permission)
2. **Use existing roles** (if you don't have `iam:PassRole` permission for custom roles)

## Option 1: Create Roles with Permitted Names (Recommended)

If your AWS environment allows creating IAM roles with specific names (`eksClusterRole` and `AmazonEKSNodeRole`), Terraform can create them automatically.

### Configuration

In `terraform.tfvars`:

```hcl
# Enable EKS
eks_cluster_name = "myekscluster"

# Let Terraform create roles with permitted names
use_eks_permitted_roles = true

# Leave these empty - Terraform will create the roles
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

### What Terraform Creates

When `use_eks_permitted_roles = true`, Terraform creates:

1. **Cluster Role**: `eksClusterRole`
   - Trust policy: `eks.amazonaws.com`
   - Attached policy: `AmazonEKSClusterPolicy`

2. **Node Group Role**: `AmazonEKSNodeRole`
   - Trust policy: `ec2.amazonaws.com`
   - Attached policies:
     - `AmazonEKSWorkerNodePolicy`
     - `AmazonEKS_CNI_Policy`
     - `AmazonEC2ContainerRegistryReadOnly`

### Requirements

- Permission to create IAM roles
- Permission to attach IAM policies
- Permission to pass the created roles to EKS service (`iam:PassRole`)

### Usage

```bash
terraform init
terraform plan
terraform apply
```

Terraform will automatically create the roles and use them for the EKS cluster.

---

## Option 2: Use Existing Roles

If you don't have permission to create IAM roles or need to use roles that already exist, you can provide their ARNs.

### Configuration

In `terraform.tfvars`:

```hcl
# Enable EKS
eks_cluster_name = "myekscluster"

# Use existing roles
use_eks_permitted_roles = false

# Provide existing role ARNs
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/AmazonEKSNodeRole"
```

### Finding Existing Roles

If you need to find existing EKS roles in your account:

```bash
# List all IAM roles with "eks" in the name
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table

# Check specific role names
aws iam get-role --role-name eksClusterRole --query 'Role.Arn' --output text
aws iam get-role --role-name AmazonEKSNodeRole --query 'Role.Arn' --output text
```

### Required Role Permissions

The existing roles must have:

**Cluster Role:**
- Trust policy allowing `eks.amazonaws.com` to assume the role
- `AmazonEKSClusterPolicy` attached

**Node Group Role:**
- Trust policy allowing `ec2.amazonaws.com` to assume the role
- `AmazonEKSWorkerNodePolicy` attached
- `AmazonEKS_CNI_Policy` attached
- `AmazonEC2ContainerRegistryReadOnly` attached

### Creating Roles Manually (if needed)

If no roles exist, you can create them using the provided scripts:

```bash
# Create roles with permitted names
./create-permitted-eks-roles.sh

# Or use the find script to check what exists
./find-eks-roles.sh
```

Then use Option 2 configuration with the created role ARNs.

---

## How It Works

The infrastructure uses conditional logic in `main.tf`:

```hcl
# If use_eks_permitted_roles is true, create roles in root module
resource "aws_iam_role" "eks_cluster" {
  count = var.eks_cluster_name != "" && var.use_eks_permitted_roles ? 1 : 0
  name  = "eksClusterRole"
  # ... role configuration
}

# Local values determine which role ARN to use
locals {
  eks_cluster_role_arn = var.use_eks_permitted_roles && var.eks_cluster_name != "" ? (
    try(aws_iam_role.eks_cluster[0].arn, var.eks_cluster_role_arn)
  ) : var.eks_cluster_role_arn
  
  eks_node_group_role_arn = var.use_eks_permitted_roles && var.eks_cluster_name != "" ? (
    try(aws_iam_role.eks_node_group[0].arn, var.eks_node_group_role_arn)
  ) : var.eks_node_group_role_arn
}
```

The EKS module receives the appropriate role ARN via the `cluster_role_arn` and `node_group_role_arn` variables.

---

## Troubleshooting

### Error: "User is not authorized to perform: iam:PassRole"

**Cause**: You don't have permission to pass the role to EKS service.

**Solution**: 
- Use existing roles that you have permission to pass (Option 2)
- Or ask your AWS administrator to grant `iam:PassRole` permission for the roles

### Error: "InvalidParameterException: Role is not authorized"

**Cause**: The role doesn't have the correct trust policy or required policies.

**Solution**:
- Verify the role has the correct trust relationship
- Ensure all required policies are attached
- See the "Required Role Permissions" section above

### Error: "ResourceNotFoundException: Role not found"

**Cause**: The role ARN is incorrect or the role doesn't exist.

**Solution**:
- Verify the role exists: `aws iam get-role --role-name ROLE_NAME`
- Check the account ID in the ARN matches your AWS account
- Ensure the role name is correct

### Roles Created But Not Used

**Cause**: `use_eks_permitted_roles` is set incorrectly or role ARNs are conflicting.

**Solution**:
- If using permitted roles: Set `use_eks_permitted_roles = true` and leave ARNs empty
- If using existing roles: Set `use_eks_permitted_roles = false` and provide ARNs

---

## Best Practices

1. **Use Permitted Names When Possible**: If your environment allows it, use `use_eks_permitted_roles = true` for simpler management
2. **Document Role ARNs**: Keep role ARNs documented for team members
3. **Verify Permissions**: Always verify roles have correct trust policies and attached policies
4. **Test in Development**: Test role configuration in a development environment first
5. **Use Least Privilege**: Ensure roles only have the minimum required permissions

---

## Quick Reference

| Variable | Description | Default |
|----------|-------------|---------|
| `use_eks_permitted_roles` | Create roles with permitted names | `true` |
| `eks_cluster_role_arn` | ARN of existing cluster role | `""` |
| `eks_node_group_role_arn` | ARN of existing node group role | `""` |

**When `use_eks_permitted_roles = true`:**
- Terraform creates: `eksClusterRole` and `AmazonEKSNodeRole`
- Leave ARN variables empty

**When `use_eks_permitted_roles = false`:**
- Terraform uses provided ARNs
- Roles must already exist
- You must have permission to pass them

---

**Last Updated**: 2025-12-28
