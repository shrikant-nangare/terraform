# Steps to Enable EKS Cluster

## Current Status
✅ EKS is **ENABLED** in terraform.tfvars (`eks_cluster_name = "myekscluster"`)
❌ IAM role ARNs need to be filled in

## Step 1: Find Existing EKS IAM Roles

Run this command in your terminal:

```bash
./find-eks-roles.sh
```

Or manually:

```bash
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table
```

## Step 2: Check Common Role Names

Try these common EKS role names:

**Cluster Roles:**
```bash
aws iam get-role --role-name eksClusterRole --query 'Role.Arn' --output text
aws iam get-role --role-name EKS-Cluster-Role --query 'Role.Arn' --output text
aws iam get-role --role-name AmazonEKSClusterRole --query 'Role.Arn' --output text
```

**Node Group Roles:**
```bash
aws iam get-role --role-name AmazonEKSNodeRole --query 'Role.Arn' --output text
aws iam get-role --role-name EKS-Node-Role --query 'Role.Arn' --output text
aws iam get-role --role-name eksNodeRole --query 'Role.Arn' --output text
```

## Step 3: Update terraform.tfvars

Once you have the role ARNs, edit `terraform.tfvars` and update:

```hcl
eks_cluster_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-CLUSTER-ROLE"
eks_node_group_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-NODE-ROLE"
```

Replace `YOUR-ACCOUNT-ID` and the role names with the actual values.

## Step 4: Apply Terraform

```bash
terraform plan
terraform apply
```

## If No Roles Exist

If no EKS roles exist in your AWS account, you have two options:

### Option A: Ask Your AWS Administrator
Request them to:
1. Create EKS cluster and node group roles with proper permissions
2. Grant you `iam:PassRole` permission for those roles

### Option B: Create Roles Manually via AWS Console
1. Go to IAM Console → Roles → Create Role
2. For Cluster Role:
   - Trust: EKS service
   - Attach: `AmazonEKSClusterPolicy`
3. For Node Role:
   - Trust: EC2 service
   - Attach: `AmazonEKSWorkerNodePolicy`, `AmazonEKS_CNI_Policy`, `AmazonEC2ContainerRegistryReadOnly`
4. Use the ARNs in terraform.tfvars

## Quick Reference

**Current terraform.tfvars location:**
- Line 27: `eks_cluster_name = "myekscluster"` ✅ (enabled)
- Line 35: `eks_cluster_role_arn = ""` ❌ (needs ARN)
- Line 36: `eks_node_group_role_arn = ""` ❌ (needs ARN)

## Troubleshooting

**Error: "User is not authorized to perform: iam:PassRole"**
- You need to use existing roles that you have permission to pass
- Or get `iam:PassRole` permission from your administrator

**Error: "Role not found"**
- Verify the role ARN is correct
- Check the account ID matches your AWS account
- Ensure the role exists in the same region

