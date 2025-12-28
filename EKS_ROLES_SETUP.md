# EKS IAM Roles Setup - Current Status

## Problem
The EKS module has a circular dependency issue when trying to import existing roles. The module's count logic depends on variables that reference root module resources.

## Solution: Use Existing Roles Directly

Since the roles already exist (created by `create-permitted-eks-roles.sh`), we have two options:

### Option 1: Use Existing Roles (Current Configuration) ✅

**Current terraform.tfvars:**
```hcl
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::660526765185:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::660526765185:role/AmazonEKSNodeRole"
```

This configuration:
- ✅ Uses existing roles (no import needed)
- ✅ Avoids circular dependency
- ✅ EKS module will use provided ARNs and won't try to create roles
- ✅ Works immediately

**To use this:**
1. Keep `use_eks_permitted_roles = false`
2. Keep the ARNs in terraform.tfvars
3. Run `terraform plan` and `terraform apply`

### Option 2: Import Roles into Terraform (For Future Management)

If you want Terraform to manage the roles going forward:

1. **First, set use_eks_permitted_roles = true in terraform.tfvars**

2. **Import the existing roles:**
```bash
terraform import aws_iam_role.eks_cluster[0] eksClusterRole
terraform import aws_iam_role_policy_attachment.eks_cluster_policy[0] eksClusterRole/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
terraform import aws_iam_role.eks_node_group[0] AmazonEKSNodeRole
terraform import aws_iam_role_policy_attachment.eks_node_worker_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
terraform import aws_iam_role_policy_attachment.eks_node_cni_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
terraform import aws_iam_role_policy_attachment.eks_node_registry_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

3. **Then update terraform.tfvars:**
```hcl
use_eks_permitted_roles = true
eks_cluster_role_arn = ""  # Empty - Terraform will use imported roles
eks_node_group_role_arn = ""  # Empty - Terraform will use imported roles
```

## Recommendation

**Use Option 1** (current configuration) because:
- ✅ No import needed
- ✅ No circular dependency issues
- ✅ Simpler and works immediately
- ✅ Roles are already created and working

The roles are managed outside Terraform (created by script), which is fine. Terraform will use them via the ARNs.

## Current Status

✅ Roles exist: `eksClusterRole` and `AmazonEKSNodeRole`
✅ Configuration set to use existing roles
✅ Ready to create EKS cluster

**Next step:** Run `terraform apply` to create the EKS cluster using the existing roles.

