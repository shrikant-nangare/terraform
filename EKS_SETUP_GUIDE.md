# EKS Setup Guide for Restricted Environments

## Problem
If you're getting this error:
```
Error: User is not authorized to perform: iam:PassRole on resource: arn:aws:iam::ACCOUNT_ID:role/my-project-eks-cluster-role
```

This means you don't have permission to pass IAM roles to AWS services. You need to use **existing IAM roles** that you have permission to pass.

## Solution: Use Existing IAM Roles

### Step 1: Find Existing EKS Roles

Ask your AWS administrator for existing EKS IAM roles, or check if these standard roles exist:

**For EKS Cluster:**
- Look for roles with `AmazonEKSClusterPolicy` attached
- Common names: `eksClusterRole`, `EKS-Cluster-Role`, or similar

**For EKS Node Group:**
- Look for roles with `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, and `AmazonEC2ContainerRegistryReadOnly` attached
- Common names: `AmazonEKSNodeRole`, `EKS-Node-Role`, or similar

### Step 2: Get Role ARNs

You can find role ARNs using:

```bash
# List all IAM roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table

# Or check specific role
aws iam get-role --role-name eksClusterRole --query 'Role.Arn' --output text
aws iam get-role --role-name AmazonEKSNodeRole --query 'Role.Arn' --output text
```

### Step 3: Configure terraform.tfvars

Add the role ARNs to your `terraform.tfvars` file:

```hcl
# EKS Cluster Configuration
eks_cluster_name = "my-eks-cluster"
eks_kubernetes_version = "1.28"
eks_node_instance_type = "t3.small"

# EKS IAM Roles (REQUIRED if you don't have iam:PassRole permission)
eks_cluster_role_arn = "arn:aws:iam::660526765185:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::660526765185:role/AmazonEKSNodeRole"
```

### Step 4: Verify Role Permissions

The roles must have the correct trust policies and policies attached:

**Cluster Role Requirements:**
- Trust policy allowing `eks.amazonaws.com` to assume the role
- `AmazonEKSClusterPolicy` attached

**Node Group Role Requirements:**
- Trust policy allowing `ec2.amazonaws.com` to assume the role
- `AmazonEKSWorkerNodePolicy` attached
- `AmazonEKS_CNI_Policy` attached
- `AmazonEC2ContainerRegistryReadOnly` attached

## Alternative: Disable EKS

If you don't need EKS or can't get the required roles, you can disable it:

```hcl
# In terraform.tfvars
eks_cluster_name = ""  # Empty string disables EKS
```

Or simply don't provide the role ARNs - the EKS module will be skipped automatically.

## Troubleshooting

### Error: "InvalidParameterException: Role is not authorized"
- The role doesn't have the correct trust policy
- The role doesn't have the required policies attached
- Contact your AWS administrator to fix the role

### Error: "AccessDeniedException: User is not authorized to perform: iam:PassRole"
- You don't have permission to pass the role
- Use a different role that you have permission to pass
- Or ask your administrator to grant you `iam:PassRole` permission for the role

### Error: "ResourceNotFoundException: Role not found"
- The role ARN is incorrect
- Verify the role exists and the ARN is correct
- Check the account ID in the ARN matches your AWS account

## Required IAM Permissions

If you want to create new roles (requires additional permissions):
- `iam:CreateRole`
- `iam:AttachRolePolicy`
- `iam:PassRole` (for the roles you create)

Most restricted environments don't grant these permissions, which is why using existing roles is recommended.

