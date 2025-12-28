# Fix Terraform AWS Permissions

## Problem

Your Terraform execution user `kk_labs_user_461965` is missing multiple AWS service permissions needed to manage the infrastructure. You're seeing errors for:

1. **Auto Scaling**: `autoscaling:UpdateAutoScalingGroup`
2. **EKS**: `eks:CreateCluster`, `eks:UpdateClusterVersion`
3. **EC2/NAT Gateway**: `ec2:CreateNatGateway`

## Quick Fix: Attach Required AWS Managed Policies

The fastest solution is to attach AWS managed policies to your IAM user. Run these commands:

```bash
# Identify your user
USER_NAME="kk_labs_user_461965"

# Attach EC2 full access (covers VPC, NAT Gateway, etc.)
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Attach Auto Scaling full access
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/AutoScalingFullAccess

# Attach EKS full access
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess

# Attach IAM permissions (for creating roles)
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Attach CloudWatch permissions (for ASG alarms)
aws iam attach-user-policy \
  --user-name $USER_NAME \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
```

**Note**: These policies provide full access to each service. For production, consider creating custom policies with only required permissions (see below).

## Required Permissions by Service

### 1. EC2 & VPC Permissions

Your infrastructure needs these EC2 permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ec2:CreateVpc",
        "ec2:DeleteVpc",
        "ec2:DescribeVpcs",
        "ec2:ModifyVpcAttribute",
        "ec2:CreateSubnet",
        "ec2:DeleteSubnet",
        "ec2:DescribeSubnets",
        "ec2:ModifySubnetAttribute",
        "ec2:CreateInternetGateway",
        "ec2:DeleteInternetGateway",
        "ec2:DescribeInternetGateways",
        "ec2:AttachInternetGateway",
        "ec2:DetachInternetGateway",
        "ec2:CreateNatGateway",
        "ec2:DeleteNatGateway",
        "ec2:DescribeNatGateways",
        "ec2:AllocateAddress",
        "ec2:ReleaseAddress",
        "ec2:DescribeAddresses",
        "ec2:AssociateAddress",
        "ec2:DisassociateAddress",
        "ec2:CreateRouteTable",
        "ec2:DeleteRouteTable",
        "ec2:DescribeRouteTables",
        "ec2:CreateRoute",
        "ec2:DeleteRoute",
        "ec2:ReplaceRoute",
        "ec2:AssociateRouteTable",
        "ec2:DisassociateRouteTable",
        "ec2:CreateSecurityGroup",
        "ec2:DeleteSecurityGroup",
        "ec2:DescribeSecurityGroups",
        "ec2:AuthorizeSecurityGroupIngress",
        "ec2:AuthorizeSecurityGroupEgress",
        "ec2:RevokeSecurityGroupIngress",
        "ec2:RevokeSecurityGroupEgress",
        "ec2:CreateTags",
        "ec2:DeleteTags",
        "ec2:DescribeTags",
        "ec2:DescribeAvailabilityZones",
        "ec2:DescribeImages",
        "ec2:RunInstances",
        "ec2:TerminateInstances",
        "ec2:DescribeInstances",
        "ec2:ModifyInstanceAttribute",
        "ec2:DescribeInstanceAttribute",
        "ec2:DescribeInstanceStatus",
        "ec2:DescribeKeyPairs",
        "ec2:CreateKeyPair",
        "ec2:DeleteKeyPair"
      ],
      "Resource": "*"
    }
  ]
}
```

**AWS Managed Policy**: `AmazonEC2FullAccess`

### 2. Auto Scaling Permissions

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "autoscaling:CreateAutoScalingGroup",
        "autoscaling:UpdateAutoScalingGroup",
        "autoscaling:DeleteAutoScalingGroup",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:CreateLaunchTemplate",
        "autoscaling:DeleteLaunchTemplate",
        "autoscaling:DescribeLaunchTemplates",
        "autoscaling:CreateScalingPolicy",
        "autoscaling:DeleteScalingPolicy",
        "autoscaling:DescribeScalingPolicies",
        "autoscaling:PutScalingPolicy",
        "autoscaling:DescribeScheduledActions",
        "autoscaling:PutScheduledUpdateGroupAction",
        "autoscaling:DeleteScheduledAction",
        "autoscaling:SetDesiredCapacity",
        "autoscaling:TerminateInstanceInAutoScalingGroup",
        "autoscaling:DescribeTags",
        "autoscaling:CreateOrUpdateTags",
        "autoscaling:DeleteTags"
      ],
      "Resource": "*"
    }
  ]
}
```

**AWS Managed Policy**: `AutoScalingFullAccess`

### 3. EKS Permissions

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
        "eks:DescribeUpdate",
        "eks:ListUpdates"
      ],
      "Resource": "*"
    }
  ]
}
```

**AWS Managed Policy**: `AmazonEKSFullAccess`

### 4. IAM Permissions (for creating roles)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRoleTags"
      ],
      "Resource": "*"
    }
  ]
}
```

**AWS Managed Policy**: `IAMFullAccess` (or more restrictive custom policy)

### 5. CloudWatch Permissions (for ASG alarms)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
```

**AWS Managed Policy**: `CloudWatchFullAccess`

## Custom Policy: All Required Permissions

If you want a single custom policy with all required permissions:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2AndVPCPermissions",
      "Effect": "Allow",
      "Action": [
        "ec2:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingPermissions",
      "Effect": "Allow",
      "Action": [
        "autoscaling:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "EKSPermissions",
      "Effect": "Allow",
      "Action": [
        "eks:*"
      ],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRoleTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
```

To create and attach this policy:

```bash
# Create the policy file
cat > terraform-infrastructure-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EC2AndVPCPermissions",
      "Effect": "Allow",
      "Action": ["ec2:*"],
      "Resource": "*"
    },
    {
      "Sid": "AutoScalingPermissions",
      "Effect": "Allow",
      "Action": ["autoscaling:*"],
      "Resource": "*"
    },
    {
      "Sid": "EKSPermissions",
      "Effect": "Allow",
      "Action": ["eks:*"],
      "Resource": "*"
    },
    {
      "Sid": "IAMPermissions",
      "Effect": "Allow",
      "Action": [
        "iam:CreateRole",
        "iam:DeleteRole",
        "iam:GetRole",
        "iam:ListRoles",
        "iam:AttachRolePolicy",
        "iam:DetachRolePolicy",
        "iam:ListAttachedRolePolicies",
        "iam:CreateInstanceProfile",
        "iam:DeleteInstanceProfile",
        "iam:GetInstanceProfile",
        "iam:AddRoleToInstanceProfile",
        "iam:RemoveRoleFromInstanceProfile",
        "iam:PassRole",
        "iam:TagRole",
        "iam:UntagRole",
        "iam:ListRoleTags"
      ],
      "Resource": "*"
    },
    {
      "Sid": "CloudWatchPermissions",
      "Effect": "Allow",
      "Action": [
        "cloudwatch:PutMetricAlarm",
        "cloudwatch:DeleteAlarms",
        "cloudwatch:DescribeAlarms",
        "cloudwatch:ListMetrics",
        "cloudwatch:GetMetricStatistics",
        "cloudwatch:TagResource"
      ],
      "Resource": "*"
    }
  ]
}
EOF

# Get your account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create the policy
aws iam create-policy \
  --policy-name TerraformInfrastructureManagement \
  --policy-document file://terraform-infrastructure-policy.json

# Attach to your user
aws iam attach-user-policy \
  --user-name kk_labs_user_461965 \
  --policy-arn arn:aws:iam::${ACCOUNT_ID}:policy/TerraformInfrastructureManagement
```

## Verify Current Permissions

Check what policies are currently attached to your user:

```bash
# List attached policies
aws iam list-attached-user-policies --user-name kk_labs_user_461965

# List inline policies
aws iam list-user-policies --user-name kk_labs_user_461965

# Get user details
aws iam get-user --user-name kk_labs_user_461965
```

## After Granting Permissions

1. **Wait 1-2 minutes** for IAM permissions to propagate
2. **Re-run Terraform**:
   ```bash
   terraform plan
   terraform apply
   ```

## Troubleshooting

### Permissions still not working

1. **Check for conflicting policies**: Look for deny policies that might override allows
2. **Verify policy attachment**: Ensure policies are actually attached
3. **Check resource-level restrictions**: Some policies may restrict by resource ARN
4. **Wait longer**: IAM changes can take up to 5 minutes to propagate

### Using AWS SSO or Temporary Credentials

If you're using AWS SSO or temporary credentials:
- Ensure the SSO permission set includes all required permissions
- Check that your session hasn't expired
- Re-authenticate if needed

### Permission Denied on Specific Resources

If you get permission denied on specific resources, you may need to:
- Add resource-specific permissions
- Check for service control policies (SCPs) that might restrict access
- Verify the resource ARN matches your policy

## Summary

**Quickest Solution:**
```bash
USER_NAME="kk_labs_user_461965"
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AutoScalingFullAccess
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/IAMFullAccess
aws iam attach-user-policy --user-name $USER_NAME --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess
```

**Then wait 1-2 minutes and re-run `terraform apply`.**

---

**Last Updated**: 2025-12-28

