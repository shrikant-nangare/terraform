# Destroy and Recreate Infrastructure

This guide walks you through destroying all infrastructure and recreating it from scratch.

## Prerequisites

Before destroying, ensure you have:

1. **Fixed AWS Permissions** - Run the permission fix script:
   ```bash
   ./fix-terraform-permissions.sh
   ```
   Or see [FIX_TERRAFORM_PERMISSIONS.md](./FIX_TERRAFORM_PERMISSIONS.md)

2. **Backup Important Data** - If you have any data in EC2 instances, EKS clusters, or other resources that you need to keep, back it up first.

3. **Verified Configuration** - Review your `terraform.tfvars` to ensure it's configured correctly.

## Step 1: Review Current State

Check what will be destroyed:

```bash
# Review current resources
terraform state list

# See what Terraform plans to destroy
terraform plan -destroy
```

## Step 2: Destroy Infrastructure

Destroy all resources:

```bash
# Destroy all infrastructure
terraform destroy

# If prompted, type 'yes' to confirm
```

**Note**: This will destroy:
- EKS cluster and node groups
- Auto Scaling Groups
- EC2 instances
- VPC, subnets, NAT Gateway, Internet Gateway
- Security groups
- IAM roles (if created by Terraform)
- CloudWatch alarms

## Step 3: Verify Destruction

Verify resources are destroyed:

```bash
# Check Terraform state (should be empty or minimal)
terraform state list

# Verify EKS cluster is gone
aws eks list-clusters

# Verify VPCs are gone (or only default remains)
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-project-*"
```

## Step 4: Clean Up (Optional)

If you want to ensure a completely clean state:

```bash
# Remove Terraform state files (CAUTION: Only if you want to start completely fresh)
# rm terraform.tfstate terraform.tfstate.backup

# Or just refresh state
terraform refresh
```

## Step 5: Recreate Infrastructure

Recreate everything from scratch:

```bash
# Initialize Terraform (if needed)
terraform init

# Plan the infrastructure
terraform plan

# Review the plan carefully, then apply
terraform apply
```

## Common Issues During Recreation

### Permission Errors

If you still see permission errors:

1. **Wait for IAM propagation** (1-5 minutes after attaching policies)
2. **Verify policies are attached**:
   ```bash
   aws iam list-attached-user-policies --user-name kk_labs_user_461965
   ```
3. **Re-run the fix script**:
   ```bash
   ./fix-terraform-permissions.sh
   ```

### EKS Role Issues

If EKS creation fails due to role issues:

1. **Check if roles exist**:
   ```bash
   aws iam get-role --role-name eksClusterRole
   aws iam get-role --role-name AmazonEKSNodeRole
   ```

2. **Update terraform.tfvars** if using existing roles:
   ```hcl
   use_eks_permitted_roles = false
   eks_cluster_role_arn = "arn:aws:iam::660526765185:role/eksClusterRole"
   eks_node_group_role_arn = "arn:aws:iam::660526765185:role/AmazonEKSNodeRole"
   ```

### NAT Gateway Creation Issues

If NAT Gateway creation fails:

1. **Check Elastic IP limits** - You may have reached the limit
2. **Verify VPC creation succeeded** - NAT Gateway needs a VPC
3. **Check EC2 permissions** - Ensure `AmazonEC2FullAccess` is attached

## Quick Destroy and Recreate Script

You can use this sequence:

```bash
#!/bin/bash
set -e

echo "Step 1: Destroying infrastructure..."
terraform destroy -auto-approve

echo "Step 2: Waiting 30 seconds for AWS cleanup..."
sleep 30

echo "Step 3: Recreating infrastructure..."
terraform apply -auto-approve

echo "Done!"
```

**Warning**: The `-auto-approve` flag skips confirmation prompts. Use with caution.

## Best Practices

1. **Use Terraform Workspaces** - Consider using workspaces for different environments:
   ```bash
   terraform workspace new dev
   terraform workspace select dev
   ```

2. **Remote State** - Use remote state (S3 + DynamoDB) for team collaboration:
   ```hcl
   terraform {
     backend "s3" {
       bucket = "your-terraform-state-bucket"
       key    = "terraform.tfstate"
       region = "us-east-1"
     }
   }
   ```

3. **State Locking** - Enable DynamoDB for state locking to prevent conflicts

4. **Backup State** - Before destroying, backup your state:
   ```bash
   cp terraform.tfstate terraform.tfstate.backup.$(date +%Y%m%d_%H%M%S)
   ```

## Verification After Recreation

After recreating, verify everything works:

```bash
# Check VPC
aws ec2 describe-vpcs --filters "Name=tag:Name,Values=my-project-*"

# Check EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=my-project-*"

# Check Auto Scaling Groups
aws autoscaling describe-auto-scaling-groups

# Check EKS cluster (if enabled)
aws eks describe-cluster --name myekscluster

# Check Terraform outputs
terraform output
```

## Troubleshooting

### Destroy Hangs or Fails

If destroy hangs or fails on a specific resource:

1. **Check AWS Console** - See if the resource is stuck
2. **Force remove from state** (last resort):
   ```bash
   terraform state rm <resource_address>
   ```
3. **Manually delete in AWS Console** if needed

### Resources Not Destroying

Some resources may have dependencies:

1. **EKS Cluster** - Must delete node groups first
2. **NAT Gateway** - Must delete route table associations first
3. **VPC** - Must delete all subnets, gateways, and route tables first

Terraform should handle dependencies automatically, but if stuck:

```bash
# Try targeted destroy
terraform destroy -target=module.eks
terraform destroy -target=module.asg
terraform destroy -target=module.ec2
terraform destroy -target=module.vpc
```

### State Inconsistencies

If state becomes inconsistent:

```bash
# Refresh state from AWS
terraform refresh

# Or import existing resources
terraform import <resource_address> <aws_resource_id>
```

## Summary

**Quick Destroy and Recreate:**

```bash
# 1. Fix permissions (if not done)
./fix-terraform-permissions.sh

# 2. Wait for IAM propagation
sleep 60

# 3. Destroy
terraform destroy

# 4. Recreate
terraform apply
```

---

**Last Updated**: 2025-12-28

