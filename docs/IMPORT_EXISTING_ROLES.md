# Import Existing EKS IAM Roles into Terraform

This guide explains how to import existing EKS IAM roles into Terraform state if you want Terraform to manage roles that were created outside of Terraform.

## When to Import

You typically **don't need to import** roles if:
- You're using `use_eks_permitted_roles = true` (Terraform creates them)
- You're using `use_eks_permitted_roles = false` with existing role ARNs (Terraform just uses them)

**Import is only needed if:**
- Roles were created manually or via scripts
- You want Terraform to manage them going forward
- You want to use `use_eks_permitted_roles = true` but roles already exist

## Prerequisites

Before importing, ensure:
1. Roles exist in AWS with correct names: `eksClusterRole` and `AmazonEKSNodeRole`
2. Roles have correct trust policies and attached policies
3. You have permission to read IAM roles

## Import Process

### Step 1: Configure Terraform to Use Permitted Roles

In `terraform.tfvars`:

```hcl
# Enable EKS
eks_cluster_name = "myekscluster"

# Use permitted roles (Terraform will manage them after import)
use_eks_permitted_roles = true

# Leave these empty
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

### Step 2: Import Cluster Role

```bash
# Import the cluster role
terraform import aws_iam_role.eks_cluster[0] eksClusterRole

# Import the cluster role policy attachment
terraform import aws_iam_role_policy_attachment.eks_cluster_policy[0] eksClusterRole/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
```

### Step 3: Import Node Group Role

```bash
# Import the node group role
terraform import aws_iam_role.eks_node_group[0] AmazonEKSNodeRole

# Import node group policy attachments
terraform import aws_iam_role_policy_attachment.eks_node_worker_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
terraform import aws_iam_role_policy_attachment.eks_node_cni_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
terraform import aws_iam_role_policy_attachment.eks_node_registry_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

### Step 4: Verify Import

After importing, verify the resources are in state:

```bash
terraform state list | grep eks
```

You should see:
- `aws_iam_role.eks_cluster[0]`
- `aws_iam_role_policy_attachment.eks_cluster_policy[0]`
- `aws_iam_role.eks_node_group[0]`
- `aws_iam_role_policy_attachment.eks_node_worker_policy[0]`
- `aws_iam_role_policy_attachment.eks_node_cni_policy[0]`
- `aws_iam_role_policy_attachment.eks_node_registry_policy[0]`

### Step 5: Plan and Apply

```bash
# Review the plan (should show no changes if roles match)
terraform plan

# Apply to ensure state matches reality
terraform apply
```

## Alternative: Use Existing Roles Without Import

If you don't want Terraform to manage the roles, you can simply use them:

```hcl
# In terraform.tfvars
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/AmazonEKSNodeRole"
```

This approach:
- ✅ No import needed
- ✅ Terraform just uses the roles
- ✅ Roles managed outside Terraform
- ✅ Simpler workflow

See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for details.

## Alternative: Let Terraform Create New Roles

If you prefer, you can delete existing roles and let Terraform create them:

```bash
# Delete existing roles (be careful - ensure no resources are using them!)
aws iam detach-role-policy --role-name eksClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name eksClusterRole

aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam delete-role --role-name AmazonEKSNodeRole
```

Then configure:

```hcl
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""
```

And run `terraform apply` - Terraform will create the roles.

## Troubleshooting

### Error: "Resource already managed by Terraform"

**Cause**: The resource is already in Terraform state.

**Solution**: 
- Check state: `terraform state list | grep eks`
- If already imported, skip the import step
- If conflict, remove from state first: `terraform state rm RESOURCE_ADDRESS`

### Error: "Resource not found"

**Cause**: The role doesn't exist or name is incorrect.

**Solution**:
- Verify role exists: `aws iam get-role --role-name eksClusterRole`
- Check the role name matches exactly
- Ensure you're in the correct AWS account/region

### Error: "Invalid resource address"

**Cause**: The resource address format is incorrect.

**Solution**:
- Ensure `eks_cluster_name` is set (not empty)
- Ensure `use_eks_permitted_roles = true`
- Check the resource address matches the actual resource in `main.tf`

### Import Succeeds But Plan Shows Changes

**Cause**: The imported resource configuration doesn't match the actual resource.

**Solution**:
1. Review the plan to see what differs
2. Update Terraform configuration to match the actual resource
3. Or update the AWS resource to match Terraform configuration
4. Re-run `terraform apply` to sync

## Best Practices

1. **Prefer Using Existing Roles**: If you don't need Terraform to manage roles, use `use_eks_permitted_roles = false` with ARNs
2. **Import Before Major Changes**: Import roles before making significant infrastructure changes
3. **Verify After Import**: Always run `terraform plan` after import to verify state matches reality
4. **Document Role Sources**: Keep track of where roles were created (Terraform, scripts, console, etc.)
5. **Test in Development**: Test import process in a development environment first

## Quick Reference

| Scenario | Approach | Import Needed? |
|----------|----------|----------------|
| Roles created by Terraform | `use_eks_permitted_roles = true` | No |
| Roles exist, want Terraform to manage | `use_eks_permitted_roles = true` + import | Yes |
| Roles exist, don't need Terraform to manage | `use_eks_permitted_roles = false` + ARNs | No |
| No roles exist | `use_eks_permitted_roles = true` | No (Terraform creates) |

## Additional Resources

- [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) - IAM role setup guide
- [EKS_SETUP_GUIDE.md](./EKS_SETUP_GUIDE.md) - Complete EKS setup
- [Terraform Import Documentation](https://www.terraform.io/docs/cli/import/index.html)

---

**Last Updated**: 2025-12-28
