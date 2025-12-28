# Steps to Enable EKS Cluster

This guide provides step-by-step instructions to enable and configure an EKS cluster in your Terraform infrastructure.

## Prerequisites

- Terraform initialized and configured
- AWS credentials configured
- Appropriate IAM permissions

## Step 1: Enable EKS in terraform.tfvars

Edit `terraform.tfvars` and set the cluster name:

```hcl
# Enable EKS cluster
eks_cluster_name = "myekscluster"
```

**Note**: Leave this empty (`""`) to disable EKS entirely.

## Step 2: Configure IAM Roles

You have two options for IAM roles:

### Option A: Use Permitted Role Names (Recommended)

If your environment allows creating IAM roles with specific names, Terraform can create them automatically:

```hcl
# Let Terraform create roles with permitted names
use_eks_permitted_roles = true

# Leave these empty - Terraform will create the roles
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

**What this does:**
- Terraform creates `eksClusterRole` for the cluster
- Terraform creates `AmazonEKSNodeRole` for node groups
- All required policies are automatically attached

**Requirements:**
- Permission to create IAM roles
- Permission to attach IAM policies
- Permission to pass roles to EKS service

### Option B: Use Existing Roles

If you need to use existing roles or don't have permission to create roles:

#### Step 2.1: Find Existing EKS Roles

Run this command to find existing EKS roles:

```bash
# Using the provided script (if available)
./scripts/find-eks-roles.sh

# Or manually
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table
```

#### Step 2.2: Check Common Role Names

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

#### Step 2.3: Configure terraform.tfvars

Once you have the role ARNs, update `terraform.tfvars`:

```hcl
# Use existing roles
use_eks_permitted_roles = false

# Provide existing role ARNs
eks_cluster_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-CLUSTER-ROLE"
eks_node_group_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-NODE-ROLE"
```

Replace `YOUR-ACCOUNT-ID` and role names with actual values.

## Step 3: Configure Node Settings (Optional)

Customize node group configuration:

```hcl
# Kubernetes version (AWS EKS standard support: 1.32, 1.33, 1.34)
eks_kubernetes_version = "1.32"

# Node instance type
eks_node_instance_type = "t3.small"

# Node scaling configuration
eks_node_desired_size = 2  # Desired nodes per group
eks_node_min_size = 1      # Minimum nodes per group
eks_node_max_size = 3      # Maximum nodes per group
```

## Step 4: Verify Configuration

Review your `terraform.tfvars` file. It should look something like this:

```hcl
# EKS Configuration
eks_cluster_name = "myekscluster"
eks_kubernetes_version = "1.32"
eks_node_instance_type = "t3.small"
eks_node_desired_size = 2
eks_node_min_size = 1
eks_node_max_size = 3

# IAM Roles (Option A: Permitted names)
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""

# OR (Option B: Existing roles)
# use_eks_permitted_roles = false
# eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/eksClusterRole"
# eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/AmazonEKSNodeRole"
```

## Step 5: Plan and Apply

Run Terraform to create the EKS cluster:

```bash
# Review the plan
terraform plan

# Apply the configuration
terraform apply
```

This will create:
- EKS cluster control plane
- IAM roles (if using permitted names)
- Security groups for cluster and nodes
- Node groups in public and private subnets

## Step 6: Configure kubectl

After the cluster is created, configure kubectl to access it:

```bash
# Update kubeconfig
aws eks update-kubeconfig --region us-east-1 --name myekscluster

# Verify access
kubectl get nodes
```

You should see your EKS nodes listed.

## If No Roles Exist

If no EKS roles exist in your AWS account, you have several options:

### Option 1: Use Permitted Names (Easiest)

If your environment allows it, use `use_eks_permitted_roles = true` and Terraform will create them.

### Option 2: Create Roles Manually via AWS Console

1. Go to IAM Console → Roles → Create Role
2. **For Cluster Role:**
   - Trust entity: EKS service (`eks.amazonaws.com`)
   - Attach policy: `AmazonEKSClusterPolicy`
   - Name: `eksClusterRole` (or any name you prefer)
3. **For Node Role:**
   - Trust entity: EC2 service (`ec2.amazonaws.com`)
   - Attach policies:
     - `AmazonEKSWorkerNodePolicy`
     - `AmazonEKS_CNI_Policy`
     - `AmazonEC2ContainerRegistryReadOnly`
   - Name: `AmazonEKSNodeRole` (or any name you prefer)
4. Use the role ARNs in `terraform.tfvars` with `use_eks_permitted_roles = false`

### Option 3: Use Provided Scripts

If scripts are available in the repository:

```bash
# Create roles with permitted names
./scripts/create-permitted-eks-roles.sh

# Then use Option A configuration
```

### Option 4: Ask Your AWS Administrator

Request them to:
1. Create EKS cluster and node group roles with proper permissions
2. Grant you `iam:PassRole` permission for those roles
3. Provide you with the role ARNs

## Troubleshooting

### Error: "User is not authorized to perform: iam:PassRole"

**Cause**: You don't have permission to pass IAM roles to EKS.

**Solutions**:
1. Use existing roles that you have permission to pass (Option B)
2. Ask your administrator to grant `iam:PassRole` permission
3. See [FIX_EKS_IAM_ERROR.md](./FIX_EKS_IAM_ERROR.md) for detailed troubleshooting

### Error: "Role not found"

**Cause**: The role ARN is incorrect or the role doesn't exist.

**Solutions**:
1. Verify the role exists: `aws iam get-role --role-name ROLE_NAME`
2. Check the account ID in the ARN matches your AWS account
3. Ensure the role name is spelled correctly

### Error: "InvalidParameterException: Role is not authorized"

**Cause**: The role doesn't have the correct trust policy or required policies.

**Solutions**:
1. Verify the cluster role has trust policy for `eks.amazonaws.com`
2. Verify the node role has trust policy for `ec2.amazonaws.com`
3. Ensure all required AWS managed policies are attached
4. See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for required permissions

### Nodes Not Joining Cluster

**Cause**: Common issues with node registration.

**Solutions**:
1. Check IAM role permissions on nodes
2. Verify security groups allow cluster-node communication
3. Review node logs: SSH to node and check `/var/log/messages`
4. Ensure subnets have proper tags (automatically handled by Terraform)

## Quick Reference

### terraform.tfvars Configuration

```hcl
# Required: Enable EKS
eks_cluster_name = "myekscluster"

# Option A: Permitted roles (create automatically)
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""

# Option B: Existing roles (provide ARNs)
# use_eks_permitted_roles = false
# eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"
# eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/ROLE_NAME"

# Optional: Node configuration
eks_kubernetes_version = "1.32"
eks_node_instance_type = "t3.small"
eks_node_desired_size = 2
eks_node_min_size = 1
eks_node_max_size = 3
```

### Useful Commands

```bash
# Find existing roles
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`)].{Name:RoleName, Arn:Arn}'

# Check specific role
aws iam get-role --role-name eksClusterRole

# View Terraform outputs
terraform output

# Configure kubectl
aws eks update-kubeconfig --region REGION --name CLUSTER_NAME

# Verify cluster access
kubectl get nodes
```

## Next Steps

After enabling EKS:

1. **Configure kubectl**: See Step 6 above
2. **Deploy applications**: Use standard Kubernetes manifests
3. **Set up monitoring**: Consider CloudWatch Container Insights
4. **Review security**: Audit security groups and IAM roles
5. **Read documentation**: See [EKS_SETUP_GUIDE.md](./EKS_SETUP_GUIDE.md) for more details

## Additional Resources

- [EKS_SETUP_GUIDE.md](./EKS_SETUP_GUIDE.md) - Complete EKS setup guide
- [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) - Detailed IAM role configuration
- [FIX_EKS_IAM_ERROR.md](./FIX_EKS_IAM_ERROR.md) - Troubleshooting IAM errors

---

**Last Updated**: 2025-12-28
