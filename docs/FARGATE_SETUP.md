# EKS Fargate Profile Setup

## Overview

The Terraform configuration now supports **EKS Fargate profiles** as an alternative to managed node groups. Fargate is recommended for resource-constrained environments.

## Why Use Fargate?

Fargate is ideal when you have:
- ✅ Strict resource limits (256m CPU, 512Mi memory per pod)
- ✅ Variable workloads with unpredictable scaling
- ✅ Want to avoid managing EC2 instances
- ✅ Need automatic compliance with resource limits
- ✅ Account-level resource caps (6000 millicores CPU, 12288 MiB memory)

## Configuration

### Enable Fargate in terraform.tfvars

```hcl
# Enable Fargate (disables managed node groups)
eks_enable_fargate = true

# Namespaces to run on Fargate
eks_fargate_profile_namespaces = ["default", "kube-system"]

# Optional: Provide existing Fargate pod execution role ARN
# Leave empty to let Terraform create it
eks_fargate_pod_execution_role_arn = ""
```

### Use Managed Node Groups (Default)

```hcl
# Keep using managed node groups
eks_enable_fargate = false

# Configure node groups as usual
eks_node_instance_type = "t3.micro"
eks_node_desired_size = 1
eks_node_min_size = 1
eks_node_max_size = 2
```

## What Gets Created

### When Fargate is Enabled

1. **EKS Cluster** - Created as usual
2. **Fargate Profile** - Created with specified namespaces
3. **Fargate Pod Execution Role** - Created automatically (or use existing)
4. **Node Groups** - NOT created (disabled)

### When Fargate is Disabled (Default)

1. **EKS Cluster** - Created as usual
2. **Managed Node Groups** - Private and public node groups created
3. **Node Group IAM Roles** - Created or use existing
4. **Fargate Profile** - NOT created

## IAM Roles

### Fargate Pod Execution Role

When `eks_enable_fargate = true` and `eks_fargate_pod_execution_role_arn` is empty:
- Terraform creates: `${project_name}-eks-fargate-pod-execution-role`
- Attaches: `AmazonEKSFargatePodExecutionRolePolicy`

To use an existing role:
```hcl
eks_fargate_pod_execution_role_arn = "arn:aws:iam::ACCOUNT_ID:role/EXISTING_ROLE"
```

## Pod Requirements

**Important**: Pods running on Fargate MUST have resource requests and limits defined:

```yaml
apiVersion: v1
kind: Pod
metadata:
  name: my-pod
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: "128m"      # Required
        memory: "256Mi"   # Required
      limits:
        cpu: "256m"      # Required (max 256m per your limits)
        memory: "512Mi"  # Required (max 512Mi per your limits)
```

## Limitations

Fargate does NOT support:
- ❌ DaemonSets
- ❌ Privileged containers
- ❌ Host networking
- ❌ Some storage types
- ❌ Pods without resource requests/limits

## Migration from Node Groups

If you have an existing cluster with node groups and want to switch to Fargate:

1. **Update terraform.tfvars**:
   ```hcl
   eks_enable_fargate = true
   ```

2. **Plan the changes**:
   ```bash
   terraform plan
   ```

3. **Apply** (this will destroy node groups and create Fargate profile):
   ```bash
   terraform apply
   ```

**Note**: This will destroy existing node groups. Ensure your workloads can run on Fargate before migrating.

## Example Configuration

### Complete Fargate Setup

```hcl
# terraform.tfvars
eks_cluster_name = "myekscluster"
eks_kubernetes_version = "1.32"

# Enable Fargate
eks_enable_fargate = true
eks_fargate_profile_namespaces = ["default", "kube-system", "production"]

# IAM Roles (using permitted names)
use_eks_permitted_roles = true
eks_cluster_role_arn = ""
eks_node_group_role_arn = ""  # Not used with Fargate, but required
```

## Troubleshooting

### Error: "Pods must have resource requests"

**Solution**: Ensure all pods have resource requests and limits defined in their manifests.

### Error: "DaemonSet not supported on Fargate"

**Solution**: DaemonSets cannot run on Fargate. Use managed node groups for DaemonSets.

### Error: "Fargate profile creation failed"

**Solution**: 
- Verify you have `eks:CreateFargateProfile` permission
- Check that subnets have proper tags
- Ensure cluster is in ACTIVE state

## Comparison: Fargate vs Node Groups

| Feature | Fargate | Managed Node Groups |
|---------|---------|-------------------|
| Resource Limits | Automatic compliance | Manual management |
| Scaling | Automatic | Manual/ASG |
| Cost | Pay per pod | Pay per node |
| DaemonSets | ❌ Not supported | ✅ Supported |
| Privileged containers | ❌ Not supported | ✅ Supported |
| Resource requests | ✅ Required | Optional |
| Node management | None | Full control |

## Additional Resources

- [EKS Resource Limits](./EKS_RESOURCE_LIMITS.md) - Detailed resource limit information
- [AWS EKS Fargate Documentation](https://docs.aws.amazon.com/eks/latest/userguide/fargate.html)

