# EKS Resource Limits and Configuration

## Account Limits

Based on your AWS account restrictions:

### Service Roles (Permitted)
- ✅ **Cluster Service Role**: `eksClusterRole` (correctly configured)
- ✅ **Node Service Role**: `AmazonEKSNodeRole` (correctly configured)

### Resource Limits

#### Pod Resource Limits
- **Maximum CPU per Pod**: 256 millicores (0.256 cores)
- **Maximum Memory per Pod**: 512 MiB
- **Maximum Pods per Namespace**: 3 pods

#### Cluster Resource Caps
- **Cumulative CPU Cap per Cluster**: 2000 millicores (2 cores)
- **Cumulative Memory Cap per Cluster**: 4096 MiB (4 GiB)

#### Account-Level Resource Caps
- **Maximum Account-Wide CPU Cap**: 6000 millicores (6 CPUs)
- **Maximum Account-Wide Memory Cap**: 12288 MiB (12 GiB)

#### Fargate Profiles
- **Maximum Fargate Profiles per Cluster**: 3 profiles

## Current Configuration Analysis

### Your Current Setup
- **Node Instance Type**: `t3.small`
  - CPU: 2 vCPUs = 2000 millicores per node
  - Memory: 2 GiB = 2048 MiB per node
- **Node Groups**: 2 (private + public)
- **Desired Size**: 2 nodes per group
- **Total Nodes**: 2 groups × 2 nodes = **4 nodes**

### Resource Calculation
- **Total CPU**: 4 nodes × 2000 millicores = **8000 millicores** ⚠️
  - **Exceeds account-wide limit of 6000 millicores**
- **Total Memory**: 4 nodes × 2048 MiB = **8192 MiB** ✅
  - **Within account-wide limit of 12288 MiB**

## Recommended Configuration Adjustments

### Option 1: Use Fargate Profiles (Recommended for Resource-Constrained Environments)

**Fargate is ideal for your use case** because:
- ✅ No EC2 instances to manage (avoids node group resource limits)
- ✅ Automatic scaling based on pod requests
- ✅ Pay only for running pods
- ✅ Pods automatically comply with your resource limits (256m CPU, 512Mi memory)
- ✅ Up to 3 Fargate profiles allowed per cluster

**Note**: Your current Terraform configuration uses managed node groups. To use Fargate, you would need to:
1. Remove or disable the node group resources
2. Add Fargate profile resources instead
3. Ensure pods have resource requests/limits defined

**Fargate Profile Example** (would need to be added to Terraform):
```hcl
resource "aws_eks_fargate_profile" "default" {
  cluster_name           = aws_eks_cluster.main.name
  fargate_profile_name   = "default"
  pod_execution_role_arn = aws_iam_role.fargate_pod_execution.arn
  subnet_ids             = var.private_subnet_ids

  selector {
    namespace = "default"
  }

  selector {
    namespace = "kube-system"
  }
}
```

**Considerations**:
- Pods must have resource requests/limits
- Some workloads not supported (DaemonSets, privileged containers)
- Typically more expensive than EC2 for steady workloads
- Better for variable/spiky workloads

### Option 2: Reduce Node Count (Alternative)
Reduce the number of nodes to stay within CPU limits:

```hcl
# In terraform.tfvars
eks_node_desired_size = 1  # 1 node per group (was 2)
eks_node_min_size     = 1
eks_node_max_size     = 2  # Max 2 to stay within limits

# Total: 2 groups × 1 node = 2 nodes
# Total CPU: 2 nodes × 2000 millicores = 4000 millicores ✅ (within 6000 limit)
# Total Memory: 2 nodes × 2048 MiB = 4096 MiB ✅ (within 12288 limit)
```

### Option 3: Use Smaller Instance Type
Switch to `t3.micro` to reduce per-node resources:

```hcl
# In terraform.tfvars
eks_node_instance_type = "t3.micro"  # 1 vCPU = 1000 millicores, 1 GiB = 1024 MiB
eks_node_desired_size = 2  # Can keep 2 nodes per group

# Total: 2 groups × 2 nodes = 4 nodes
# Total CPU: 4 nodes × 1000 millicores = 4000 millicores ✅
# Total Memory: 4 nodes × 1024 MiB = 4096 MiB ✅
```

### Option 4: Single Node Group
Use only one node group to reduce total nodes:

```hcl
# In terraform.tfvars
eks_node_desired_size = 2
eks_node_min_size     = 1
eks_node_max_size     = 2

# Then modify modules/eks/main.tf to create only private node group
# Total: 1 group × 2 nodes = 2 nodes
# Total CPU: 2 nodes × 2000 millicores = 4000 millicores ✅
```

## Pod Configuration Recommendations

When deploying pods, ensure they comply with limits:

### Resource Requests/Limits Example
```yaml
apiVersion: v1
kind: Pod
metadata:
  name: example-pod
spec:
  containers:
  - name: app
    resources:
      requests:
        cpu: "128m"      # 128 millicores (within 256m limit)
        memory: "256Mi"   # 256 MiB (within 512Mi limit)
      limits:
        cpu: "256m"      # Maximum allowed: 256 millicores
        memory: "512Mi"  # Maximum allowed: 512 MiB
```

### Namespace Pod Limit
- Maximum 3 pods per namespace
- Plan your deployments accordingly
- Consider using multiple namespaces if needed

## Cluster-Level Considerations

### Cluster CPU Cap
- Your cluster has a **2000 millicores (2 cores) cap**
- With `t3.small` nodes (2000 millicores each), you can only have **1 node** to stay within cluster limit
- Consider using smaller instances or reducing node count

### Recommended Configuration for Cluster Limits
```hcl
# To stay within cluster CPU cap of 2000 millicores
eks_node_instance_type = "t3.small"  # 2000 millicores per node
eks_node_desired_size = 1            # Only 1 node per group
eks_node_min_size     = 1
eks_node_max_size     = 1            # Fixed at 1 node

# Total: 2 groups × 1 node = 2 nodes
# But cluster cap is 2000 millicores, so this still exceeds!
# Better: Use t3.micro or reduce to 1 node group
```

## Best Practice Configuration

### For Managed Node Groups

Given your limits, here's the recommended setup if using managed node groups:

```hcl
# terraform.tfvars
eks_node_instance_type = "t3.micro"  # 1000 millicores, 1024 MiB
eks_node_desired_size = 1            # 1 node per group
eks_node_min_size     = 1
eks_node_max_size     = 1            # Fixed size

# This gives you:
# - 2 node groups × 1 node = 2 nodes total
# - Total CPU: 2 × 1000 = 2000 millicores ✅ (matches cluster cap)
# - Total Memory: 2 × 1024 = 2048 MiB ✅ (within cluster cap of 4096 MiB)
# - Account CPU: 2000 millicores ✅ (well within 6000 limit)
# - Account Memory: 2048 MiB ✅ (well within 12288 limit)
```

## Summary

1. ✅ **Service Roles**: Correctly using `eksClusterRole` and `AmazonEKSNodeRole`
2. ⚠️ **Current CPU**: 8000 millicores exceeds account limit of 6000
3. ✅ **Current Memory**: 8192 MiB is within account limit
4. ⚠️ **Cluster CPU Cap**: 2000 millicores means you need smaller instances or fewer nodes

## Fargate vs Managed Node Groups

### When to Use Fargate
- ✅ **Your use case**: Strict resource limits (256m CPU, 512Mi per pod)
- ✅ Variable workloads with unpredictable scaling
- ✅ Want to avoid managing EC2 instances
- ✅ Need automatic compliance with resource limits
- ✅ Short-lived or batch workloads

### When to Use Managed Node Groups
- ✅ Steady, predictable workloads
- ✅ Need DaemonSets or privileged containers
- ✅ Cost optimization for long-running workloads
- ✅ Need more control over node configuration

## Recommendation

**For your resource-constrained environment, Fargate profiles are the better choice** because:
1. No need to worry about node group CPU/memory limits
2. Pods automatically scale within your account limits
3. Simpler resource management
4. Better suited for your pod-level limits (256m CPU, 512Mi memory)

**Action Required**: 
- **Option A (Recommended)**: Consider switching to Fargate profiles instead of managed node groups
- **Option B**: If using managed node groups, adjust your node configuration to stay within limits before applying Terraform

