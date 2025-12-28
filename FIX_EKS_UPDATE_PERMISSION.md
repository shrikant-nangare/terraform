# Fix EKS Cluster Update Permission Error

## Problem

You're getting this error:
```
Error: updating EKS Cluster (myekscluster) version: operation error EKS: UpdateClusterVersion, 
https response error StatusCode: 403, RequestID: ..., 
api error AccessDeniedException: User is not authorized to perform this action
```

This happens because:
1. Terraform is trying to update the EKS cluster version
2. The **IAM user/role that Terraform is using** doesn't have permission to call `eks:UpdateClusterVersion`
3. This is different from the EKS service roles - this is about **your Terraform execution permissions**

## Understanding the Difference

There are two types of IAM roles involved with EKS:

1. **EKS Service Roles** (for the cluster and nodes):
   - `eksClusterRole` - Used by the EKS service itself
   - `AmazonEKSNodeRole` - Used by EC2 instances in node groups
   - These are configured in `terraform.tfvars` and are working fine

2. **Terraform Execution Role/User** (what you're using to run Terraform):
   - This is the IAM user/role you're authenticated as when running `terraform apply`
   - This needs EKS management permissions to create/update/delete clusters

## Solution: Grant EKS Management Permissions

The Terraform execution identity needs the following EKS permissions:

### Required Permissions

The Terraform user/role needs these EKS API permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DescribeCluster",
        "eks:UpdateCluster",
        "eks:UpdateClusterVersion",
        "eks:DeleteCluster",
        "eks:ListClusters",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:CreateNodegroup",
        "eks:DescribeNodegroup",
        "eks:UpdateNodegroupVersion",
        "eks:UpdateNodegroupConfig",
        "eks:DeleteNodegroup",
        "eks:ListNodegroups",
        "eks:AssociateIdentityProviderConfig",
        "eks:DisassociateIdentityProviderConfig",
        "eks:ListIdentityProviderConfigs",
        "eks:DescribeUpdate",
        "eks:ListUpdates"
      ],
      "Resource": "*"
    }
  ]
}
```

### Option 1: Use AWS Managed Policy (Recommended)

The easiest solution is to attach the AWS managed policy `AmazonEKSFullAccess` to your Terraform execution role/user:

```bash
# If using an IAM user
aws iam attach-user-policy \
  --user-name YOUR_TERRAFORM_USER \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess

# If using an IAM role
aws iam attach-role-policy \
  --role-name YOUR_TERRAFORM_ROLE \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess
```

**Note**: `AmazonEKSFullAccess` provides full EKS permissions. If you need more restrictive permissions, use Option 2.

### Option 2: Create Custom Policy (More Restrictive)

If you want to limit permissions to only what's needed:

```bash
# Create a custom policy
cat > eks-terraform-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DescribeCluster",
        "eks:UpdateCluster",
        "eks:UpdateClusterVersion",
        "eks:DeleteCluster",
        "eks:ListClusters",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:CreateNodegroup",
        "eks:DescribeNodegroup",
        "eks:UpdateNodegroupVersion",
        "eks:UpdateNodegroupConfig",
        "eks:DeleteNodegroup",
        "eks:ListNodegroups",
        "eks:DescribeUpdate",
        "eks:ListUpdates"
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "iam:PassRole"
      ],
      "Resource": [
        "arn:aws:iam::*:role/eksClusterRole",
        "arn:aws:iam::*:role/AmazonEKSNodeRole"
      ]
    }
  ]
}
EOF

# Create the policy
aws iam create-policy \
  --policy-name EKSTerraformManagement \
  --policy-document file://eks-terraform-policy.json

# Attach to your user/role
# Replace ACCOUNT_ID and YOUR_USER_OR_ROLE_NAME
aws iam attach-user-policy \
  --user-name YOUR_USER_OR_ROLE_NAME \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/EKSTerraformManagement

# OR for a role:
aws iam attach-role-policy \
  --role-name YOUR_ROLE_NAME \
  --policy-arn arn:aws:iam::ACCOUNT_ID:policy/EKSTerraformManagement
```

### Option 3: Resource-Specific Permissions (Most Restrictive)

If you want to limit permissions to specific clusters:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "eks:CreateCluster",
        "eks:DescribeCluster",
        "eks:UpdateCluster",
        "eks:UpdateClusterVersion",
        "eks:DeleteCluster",
        "eks:TagResource",
        "eks:UntagResource",
        "eks:CreateNodegroup",
        "eks:DescribeNodegroup",
        "eks:UpdateNodegroupVersion",
        "eks:UpdateNodegroupConfig",
        "eks:DeleteNodegroup",
        "eks:DescribeUpdate",
        "eks:ListUpdates"
      ],
      "Resource": "arn:aws:eks:*:*:cluster/myekscluster"
    },
    {
      "Effect": "Allow",
      "Action": [
        "eks:ListClusters",
        "eks:ListNodegroups"
      ],
      "Resource": "*"
    }
  ]
}
```

## How to Identify Your Terraform Execution Identity

To find out which IAM user/role Terraform is using:

```bash
# Check current AWS identity
aws sts get-caller-identity

# Output will show:
# {
#   "UserId": "...",
#   "Account": "...",
#   "Arn": "arn:aws:iam::ACCOUNT_ID:user/YOUR_USER"
#   # OR
#   "Arn": "arn:aws:sts::ACCOUNT_ID:assumed-role/YOUR_ROLE/..."
# }
```

## Verify Permissions

After granting permissions, verify they work:

```bash
# Test EKS permissions
aws eks describe-cluster --name myekscluster

# If this works, try updating the cluster version
aws eks update-cluster-version \
  --name myekscluster \
  --kubernetes-version 1.32
```

## After Fixing Permissions

Once you've granted the necessary permissions:

1. **Wait a few seconds** for IAM permissions to propagate
2. **Re-run Terraform**:
   ```bash
   terraform plan
   terraform apply
   ```

## Additional Required Permissions

In addition to EKS permissions, Terraform also needs:

- **IAM permissions** (if creating/managing roles):
  - `iam:CreateRole`
  - `iam:AttachRolePolicy`
  - `iam:PassRole`
  - `iam:GetRole`
  - `iam:ListRoles`

- **EC2 permissions** (for VPC, subnets, security groups):
  - `ec2:*` (or specific permissions for VPC resources)

- **CloudWatch Logs permissions** (if enabling cluster logging):
  - `logs:CreateLogGroup`
  - `logs:PutRetentionPolicy`

## Troubleshooting

### Error persists after granting permissions

1. **Wait for IAM propagation**: IAM changes can take 1-5 minutes to propagate
2. **Check policy attachment**: Verify the policy is actually attached:
   ```bash
   # For IAM user
   aws iam list-attached-user-policies --user-name YOUR_USER
   
   # For IAM role
   aws iam list-attached-role-policies --role-name YOUR_ROLE
   ```
3. **Check for conflicting policies**: Look for deny policies that might override allows
4. **Verify resource ARNs**: If using resource-specific permissions, ensure ARNs match

### Permission denied on other EKS operations

If you get similar errors for other operations (creating node groups, etc.), you may need additional permissions. The `AmazonEKSFullAccess` policy covers all EKS operations.

### Using AWS SSO or Temporary Credentials

If you're using AWS SSO or temporary credentials:
- Ensure the SSO permission set includes EKS permissions
- Check that your session hasn't expired
- Re-authenticate if needed

## Quick Reference

**Minimum permissions needed for Terraform to manage EKS:**
- `eks:UpdateClusterVersion` (for version updates)
- `eks:UpdateCluster` (for other cluster updates)
- `eks:DescribeCluster` (to read cluster state)
- `eks:ListClusters` (to list clusters)
- `iam:PassRole` (to pass roles to EKS service)

**Recommended approach:**
- Use `AmazonEKSFullAccess` for simplicity
- Or create a custom policy with only needed permissions for security

---

**Last Updated**: 2025-12-28

