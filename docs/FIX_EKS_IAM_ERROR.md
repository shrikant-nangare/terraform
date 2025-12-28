# Fix EKS IAM Permission Error

## Problem

You're getting this error:
```
Error: User is not authorized to perform: iam:PassRole on resource: arn:aws:iam::ACCOUNT_ID:role/my-project-eks-cluster-role
```

This happens because:
1. Terraform tried to create or use an IAM role for EKS
2. You don't have `iam:PassRole` permission to use that role
3. You need to use **existing IAM roles** that you have permission to pass, OR use permitted role names

## Solutions

The infrastructure now supports two approaches to resolve this:

### Solution 1: Use Permitted Role Names (Recommended if allowed)

If your AWS environment allows creating IAM roles with specific names (`eksClusterRole` and `AmazonEKSNodeRole`), use this approach:

**Update `terraform.tfvars`:**

```hcl
# Enable EKS
eks_cluster_name = "myekscluster"

# Use permitted role names (Terraform will create them)
use_eks_permitted_roles = true

# Leave these empty - Terraform will create the roles
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

**What this does:**
- Terraform creates `eksClusterRole` and `AmazonEKSNodeRole` with permitted names
- These roles are automatically configured with correct policies
- If you have permission to create roles, this is the simplest solution

**Requirements:**
- Permission to create IAM roles
- Permission to attach IAM policies
- Permission to pass the created roles to EKS service

### Solution 2: Use Existing IAM Roles

If you don't have permission to create roles or need to use existing roles:

#### Step 1: Find Existing EKS Roles

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

#### Step 2: Verify Role Permissions

The roles must have:
- **Cluster Role**: Trust policy for `eks.amazonaws.com` + `AmazonEKSClusterPolicy`
- **Node Role**: Trust policy for `ec2.amazonaws.com` + `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`

#### Step 3: Update terraform.tfvars

Update your `terraform.tfvars` file with the role ARNs:

```hcl
# EKS Cluster Configuration
eks_cluster_name = "myekscluster"
eks_kubernetes_version = "1.32"  # Updated version
eks_node_instance_type = "t3.small"

# Use existing roles
use_eks_permitted_roles = false

# EKS IAM Roles (REQUIRED - use existing roles)
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-EXISTING-CLUSTER-ROLE"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-EXISTING-NODE-ROLE"
```

Replace `ACCOUNT_ID`, `YOUR-EXISTING-CLUSTER-ROLE`, and `YOUR-EXISTING-NODE-ROLE` with actual values.

#### Step 4: Clean Up and Re-apply

If Terraform previously tried to create roles, you may need to clean up:

```bash
# Remove any created roles from state (if they exist)
terraform state rm 'aws_iam_role.eks_cluster[0]' 2>/dev/null
terraform state rm 'aws_iam_role.eks_node_group[0]' 2>/dev/null
terraform state rm 'aws_iam_role_policy_attachment.eks_cluster_policy[0]' 2>/dev/null
terraform state rm 'aws_iam_role_policy_attachment.eks_node_worker_policy[0]' 2>/dev/null
terraform state rm 'aws_iam_role_policy_attachment.eks_node_cni_policy[0]' 2>/dev/null
terraform state rm 'aws_iam_role_policy_attachment.eks_node_registry_policy[0]' 2>/dev/null

# Then apply with existing roles
terraform plan
terraform apply
```

## Alternative: Disable EKS

If you don't need EKS right now, you can disable it:

```hcl
# In terraform.tfvars
eks_cluster_name = ""  # Empty string disables EKS
```

When `eks_cluster_name` is empty, the EKS module is not created.

## If No Existing Roles Exist

If no EKS roles exist in your account, you have several options:

### Option 1: Use Permitted Names

If your environment allows it, use `use_eks_permitted_roles = true` (Solution 1 above).

### Option 2: Create Roles Manually

Create the roles via AWS Console or CLI:

**Cluster Role:**
```bash
aws iam create-role \
  --role-name eksClusterRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "eks.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name eksClusterRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

**Node Role:**
```bash
aws iam create-role \
  --role-name AmazonEKSNodeRole \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Effect": "Allow",
      "Principal": {"Service": "ec2.amazonaws.com"},
      "Action": "sts:AssumeRole"
    }]
  }'

aws iam attach-role-policy \
  --role-name AmazonEKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy

aws iam attach-role-policy \
  --role-name AmazonEKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy

aws iam attach-role-policy \
  --role-name AmazonEKSNodeRole \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

Then use Solution 2 with the created role ARNs.

### Option 3: Ask Your AWS Administrator

Request them to:
1. Create the EKS roles with proper permissions
2. Grant you `iam:PassRole` permission for those roles
3. Provide you with the role ARNs

### Option 4: Use Provided Scripts

If scripts are available in the repository:

```bash
# Create roles with permitted names
./scripts/create-permitted-eks-roles.sh

# Then use Solution 1 (permitted roles) or Solution 2 (with the created ARNs)
```

## Quick Fix Template

Here's a minimal `terraform.tfvars` configuration to get you started:

### Using Permitted Roles (Solution 1):
```hcl
eks_cluster_name = "myekscluster"
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

### Using Existing Roles (Solution 2):
```hcl
eks_cluster_name = "myekscluster"
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-CLUSTER-ROLE-NAME"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/YOUR-NODE-ROLE-NAME"
```

## Troubleshooting

### Error: "InvalidParameterException: Role is not authorized"

**Cause**: The role doesn't have the correct trust policy or required policies.

**Solution**:
- Verify the cluster role has trust policy for `eks.amazonaws.com`
- Verify the node role has trust policy for `ec2.amazonaws.com`
- Ensure all required AWS managed policies are attached
- See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for required permissions

### Error: "ResourceNotFoundException: Role not found"

**Cause**: The role ARN is incorrect or the role doesn't exist.

**Solution**:
- Verify the role exists: `aws iam get-role --role-name ROLE_NAME`
- Check the account ID in the ARN matches your AWS account
- Ensure the role name is spelled correctly

### Error persists after configuration change

**Cause**: Terraform state may still reference old resources.

**Solution**:
1. Review Terraform state: `terraform state list | grep eks`
2. Remove any problematic resources from state
3. Re-run `terraform plan` and `terraform apply`

## Additional Resources

- [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) - Detailed IAM role setup guide
- [EKS_SETUP_GUIDE.md](./EKS_SETUP_GUIDE.md) - Complete EKS setup guide
- [ENABLE_EKS_STEPS.md](./ENABLE_EKS_STEPS.md) - Step-by-step enablement

---

**Last Updated**: 2025-12-28
