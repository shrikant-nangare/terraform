# Fix EKS IAM Permission Error

## Problem
You're getting this error:
```
Error: User is not authorized to perform: iam:PassRole on resource: arn:aws:iam::660526765185:role/my-project-eks-cluster-role
```

This happens because:
1. The EKS module created an IAM role (`my-project-eks-cluster-role`)
2. But you don't have `iam:PassRole` permission to use it
3. You need to use **existing IAM roles** that you have permission to pass

## Solution: Use Existing IAM Roles

### Step 1: Find Existing EKS Roles

Run these commands to find existing EKS roles in your AWS account:

```bash
# List all IAM roles with "eks" or "EKS" in the name
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table

# Or check for common EKS role names
aws iam get-role --role-name eksClusterRole --query 'Role.Arn' --output text 2>/dev/null
aws iam get-role --role-name AmazonEKSNodeRole --query 'Role.Arn' --output text 2>/dev/null
aws iam get-role --role-name EKS-Cluster-Role --query 'Role.Arn' --output text 2>/dev/null
aws iam get-role --role-name EKS-Node-Role --query 'Role.Arn' --output text 2>/dev/null
```

### Step 2: Verify Role Permissions

The roles must have:
- **Cluster Role**: Trust policy for `eks.amazonaws.com` + `AmazonEKSClusterPolicy`
- **Node Role**: Trust policy for `ec2.amazonaws.com` + `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

### Step 3: Create or Update terraform.tfvars

Create a `terraform.tfvars` file (or update existing one) with the role ARNs:

```hcl
# EKS Cluster Configuration
eks_cluster_name = "myekscluster"
eks_kubernetes_version = "1.28"
eks_node_instance_type = "t3.small"

# EKS IAM Roles (REQUIRED - use existing roles)
eks_cluster_role_arn = "arn:aws:iam::660526765185:role/YOUR-EXISTING-CLUSTER-ROLE"
eks_node_group_role_arn = "arn:aws:iam::660526765185:role/YOUR-EXISTING-NODE-ROLE"
```

Replace `YOUR-EXISTING-CLUSTER-ROLE` and `YOUR-EXISTING-NODE-ROLE` with the actual role ARNs you found.

### Step 4: Clean Up and Re-apply

Since the role was already created, you may need to destroy it first:

```bash
# Remove the created role from state (if it exists)
terraform state rm 'module.eks[0].aws_iam_role.cluster[0]' 2>/dev/null
terraform state rm 'module.eks[0].aws_iam_role.node_group[0]' 2>/dev/null

# Or destroy and recreate
terraform destroy -target=module.eks[0].aws_iam_role.cluster[0]
terraform destroy -target=module.eks[0].aws_iam_role.node_group[0]

# Then apply with existing roles
terraform apply
```

## Alternative: Disable EKS

If you don't need EKS right now, you can disable it:

```hcl
# In terraform.tfvars
eks_cluster_name = ""  # Empty string disables EKS
```

## If No Existing Roles Exist

If no EKS roles exist in your account, you have two options:

1. **Ask your AWS administrator** to:
   - Create the EKS roles with proper permissions
   - Grant you `iam:PassRole` permission for those roles

2. **Use AWS Console** to create the roles manually, then use their ARNs

## Quick Fix Template

Here's a minimal `terraform.tfvars` to get you started:

```hcl
# Copy terraform.tfvars.example to terraform.tfvars first
# Then add these lines (replace with your actual role ARNs):

eks_cluster_name = "myekscluster"
eks_cluster_role_arn = "arn:aws:iam::660526765185:role/YOUR-CLUSTER-ROLE-NAME"
eks_node_group_role_arn = "arn:aws:iam::660526765185:role/YOUR-NODE-ROLE-NAME"
```

