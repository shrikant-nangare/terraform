# Import Existing EKS IAM Roles into Terraform

If you already created the EKS IAM roles using the script (`create-permitted-eks-roles.sh`), you need to import them into Terraform state so Terraform can manage them.

## Import Commands

Run these commands to import the existing roles:

```bash
# Import cluster role
terraform import aws_iam_role.eks_cluster[0] eksClusterRole

# Import cluster role policy attachment
terraform import aws_iam_role_policy_attachment.eks_cluster_policy[0] eksClusterRole/arn:aws:iam::aws:policy/AmazonEKSClusterPolicy

# Import node group role
terraform import aws_iam_role.eks_node_group[0] AmazonEKSNodeRole

# Import node group policy attachments
terraform import aws_iam_role_policy_attachment.eks_node_worker_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
terraform import aws_iam_role_policy_attachment.eks_node_cni_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
terraform import aws_iam_role_policy_attachment.eks_node_registry_policy[0] AmazonEKSNodeRole/arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
```

## Verify Import

After importing, verify with:

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

## Alternative: Let Terraform Create New Roles

If you prefer, you can delete the existing roles and let Terraform create them:

```bash
# Delete existing roles (be careful!)
aws iam detach-role-policy --role-name eksClusterRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
aws iam delete-role --role-name eksClusterRole

aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
aws iam detach-role-policy --role-name AmazonEKSNodeRole --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
aws iam delete-role --role-name AmazonEKSNodeRole
```

Then run `terraform apply` and Terraform will create them.

