# Terraform AWS Infrastructure

This Terraform configuration creates a comprehensive AWS infrastructure including VPC, EC2 instances, Auto Scaling Groups (ASG), and an optional Amazon EKS (Elastic Kubernetes Service) cluster.

## Overview

This infrastructure provides:
- **VPC**: Custom VPC with configurable public and private subnets across multiple availability zones
- **EC2 Instances**: Standalone instances in public and private subnets
- **Auto Scaling Groups**: CPU-based auto-scaling for EC2 workloads
- **EKS Cluster**: Optional managed Kubernetes cluster with node groups

## Architecture

The infrastructure is organized into modular Terraform modules:

```
.
├── main.tf                    # Root module orchestrating all modules
├── variables.tf               # Root-level variables
├── outputs.tf                # Root-level outputs
├── terraform.tfvars.example  # Example configuration
└── modules/
    ├── vpc/                  # VPC, subnets, gateways, route tables
    ├── ec2/                  # EC2 instances and security groups
    ├── asg/                  # Auto Scaling Groups with CloudWatch
    └── eks/                  # EKS cluster and node groups
```

## Features

### VPC Module
- Custom VPC with configurable CIDR block
- Public and private subnets across multiple availability zones (configurable count)
- Internet Gateway for public subnet access
- Single NAT Gateway (cost-optimized) for private subnet outbound access
- Route tables for proper traffic routing

### EC2 Module
- One instance in public subnet (direct internet access)
- One instance in private subnet (outbound via NAT Gateway)
- Security groups with configurable SSH access
- Support for user data scripts

### Auto Scaling Group Module
- Separate ASGs for public and private subnets
- CPU-based auto-scaling (configurable threshold)
- CloudWatch alarms for scale-up and scale-down
- Launch templates with CloudWatch agent integration
- IAM roles for CloudWatch metrics

### EKS Module (Optional)
- Managed Kubernetes cluster (configurable version)
- Node groups in both public and private subnets
- Configurable node scaling (min/max/desired)
- Support for existing IAM roles (for restricted environments)
- CloudWatch logging enabled
- Security groups for cluster and node communication

## Prerequisites

- Terraform >= 1.0
- AWS CLI configured with appropriate credentials
- AWS account with necessary permissions
- SSH key pair in AWS (for EC2/EKS access)

## AWS Credentials Configuration

There are several ways to configure AWS credentials for Terraform. Choose the method that best fits your environment:

### 1. AWS Credentials File (Recommended for Local Development)

Create or edit `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

And optionally set the region in `~/.aws/config`:

```ini
[default]
region = us-east-1
```

### 2. Environment Variables

Set these environment variables in your shell:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. AWS SSO (Recommended for Organizations)

If your organization uses AWS SSO:

```bash
aws sso login --profile your-profile-name
export AWS_PROFILE=your-profile-name
```

### 4. IAM Roles (For EC2/ECS/Lambda)

If running Terraform on AWS infrastructure, use IAM roles. No credentials needed - Terraform will automatically use the instance profile.

**⚠️ Warning:** Never commit credentials to version control!

## Quick Start

1. **Clone the repository** (if applicable) or navigate to the Terraform directory

2. **Configure AWS credentials** using one of the methods above

3. **Create a key pair in AWS** (if you don't have one):
   ```bash
   aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
   chmod 400 my-key-pair.pem
   ```

4. **Copy the example variables file**:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

5. **Edit `terraform.tfvars`** with your values:
   ```hcl
   project_name = "my-project"
   key_pair_name = "my-key-pair"
   aws_region = "us-east-1"
   
   # To enable EKS, set:
   eks_cluster_name = "myekscluster"
   # And configure IAM roles (see EKS Setup section below)
   ```

6. **Initialize Terraform**:
   ```bash
   terraform init
   ```

7. **Review the execution plan**:
   ```bash
   terraform plan
   ```

8. **Apply the configuration**:
   ```bash
   terraform apply
   ```

## Configuration

### Key Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `aws_region` | AWS region for resources | `us-east-1` |
| `project_name` | Project name used for resource naming | `my-project` |
| `vpc_cidr` | CIDR block for VPC | `10.0.0.0/16` |
| `vpc_subnet_count` | Number of public/private subnets (one per AZ) | `3` |
| `enable_nat_gateway` | Enable NAT Gateway for private subnets | `true` |
| `instance_type` | EC2 instance type | `t3.micro` |
| `key_pair_name` | AWS key pair name for SSH access | `""` (required) |
| `ssh_allowed_cidr` | CIDR block allowed to SSH | `0.0.0.0/0` |
| `asg_min_size` | Minimum ASG instances | `1` |
| `asg_max_size` | Maximum ASG instances | `5` |
| `asg_cpu_target` | CPU target for auto-scaling (%) | `60` |
| `eks_cluster_name` | EKS cluster name (empty to disable) | `""` |
| `eks_kubernetes_version` | Kubernetes version | `1.32` |
| `eks_node_instance_type` | EKS node instance type | `t3.small` |
| `eks_node_desired_size` | Desired EKS nodes per group | `2` |
| `eks_node_min_size` | Minimum EKS nodes per group | `1` |
| `eks_node_max_size` | Maximum EKS nodes per group | `3` |

### EKS IAM Roles Configuration

The infrastructure supports two approaches for EKS IAM roles:

#### Option 1: Use Permitted Role Names (Default)
If you have permission to create IAM roles with specific names, Terraform can create them:

```hcl
use_eks_permitted_roles = true
# Terraform will create: eksClusterRole and AmazonEKSNodeRole
```

#### Option 2: Use Existing Roles
If you don't have `iam:PassRole` permission, use existing roles:

```hcl
use_eks_permitted_roles = false
eks_cluster_role_arn = "arn:aws:iam::ACCOUNT_ID:role/eksClusterRole"
eks_node_group_role_arn = "arn:aws:iam::ACCOUNT_ID:role/AmazonEKSNodeRole"
```

See [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) for detailed instructions.

## Outputs

The configuration provides comprehensive outputs:

### VPC Outputs
- `vpc_id` - VPC ID
- `public_subnet_ids` - List of public subnet IDs
- `private_subnet_ids` - List of private subnet IDs
- `nat_gateway_ids` - NAT Gateway IDs

### EC2 Outputs
- `public_instance_id` - Public EC2 instance ID
- `private_instance_id` - Private EC2 instance ID
- `public_instance_public_ip` - Public instance public IP

### ASG Outputs
- `public_asg_id` - Public ASG ID
- `private_asg_id` - Private ASG ID

### EKS Outputs (if enabled)
- `eks_cluster_id` - EKS cluster ID
- `eks_cluster_endpoint` - Kubernetes API endpoint
- `eks_cluster_version` - Kubernetes version
- `eks_private_node_group_id` - Private node group ID
- `eks_public_node_group_id` - Public node group ID

View all outputs:
```bash
terraform output
```

## Module Details

### VPC Module (`modules/vpc`)
Creates the foundational networking infrastructure:
- VPC with DNS support
- Public and private subnets (configurable count)
- Internet Gateway
- NAT Gateway (single, cost-optimized)
- Route tables and associations

### EC2 Module (`modules/ec2`)
Deploys standalone EC2 instances:
- Public instance (direct internet access)
- Private instance (outbound via NAT Gateway)
- Security groups for network access control

### ASG Module (`modules/asg`)
Provides auto-scaling capabilities:
- Separate ASGs for public and private subnets
- CPU-based scaling policies
- CloudWatch alarms and metrics
- Launch templates with CloudWatch agent

### EKS Module (`modules/eks`)
Deploys managed Kubernetes cluster:
- EKS control plane
- Node groups in public and private subnets
- IAM roles (create or use existing)
- Security groups for cluster communication
- CloudWatch logging

## EKS Setup

To enable EKS, you need to configure IAM roles. See the following guides:
- [EKS_ROLES_SETUP.md](./EKS_ROLES_SETUP.md) - IAM roles setup
- [EKS_SETUP_GUIDE.md](./EKS_SETUP_GUIDE.md) - Complete setup guide
- [ENABLE_EKS_STEPS.md](./ENABLE_EKS_STEPS.md) - Step-by-step enablement

## Cost Considerations

Estimated monthly costs (us-east-1, approximate):
- **NAT Gateway**: ~$32/month (single gateway)
- **EC2 Instances**: ~$7.50/month each (t3.micro)
- **ASG Instances**: ~$7.50/month each (t3.micro, at desired capacity)
- **EKS Control Plane**: ~$72/month (if enabled)
- **EKS Nodes**: ~$15/month each (t3.small)

**Total (without EKS)**: ~$55/month  
**Total (with EKS)**: ~$157/month

*Costs vary by region, instance types, and usage.*

## Security Best Practices

1. **Restrict SSH Access**: Set `ssh_allowed_cidr` to your IP range instead of `0.0.0.0/0`
2. **Use Key Pairs**: Always configure `key_pair_name` for secure access
3. **Security Groups**: Review and adjust security group rules as needed
4. **IAM Roles**: Use least privilege principles for IAM roles
5. **EKS Endpoint**: Consider restricting EKS public endpoint access
6. **Tags**: Use tags for cost allocation and resource management

## Troubleshooting

### Common Issues

**AWS Permission Errors (403 AccessDenied)**
- **Quick Fix**: Run `./fix-terraform-permissions.sh` to attach required policies
- **Detailed Guide**: See [FIX_TERRAFORM_PERMISSIONS.md](./FIX_TERRAFORM_PERMISSIONS.md)
- Common errors: `autoscaling:UpdateAutoScalingGroup`, `eks:CreateCluster`, `ec2:CreateNatGateway`
- Required policies: EC2, Auto Scaling, EKS, IAM, CloudWatch

**EKS IAM Permission Errors**
- See [FIX_EKS_IAM_ERROR.md](./FIX_EKS_IAM_ERROR.md)
- See [FIX_EKS_UPDATE_PERMISSION.md](./FIX_EKS_UPDATE_PERMISSION.md) for cluster update permissions
- Ensure you have existing roles or permission to create roles

**NAT Gateway Not Accessible**
- Check route table associations
- Verify NAT Gateway is in public subnet
- Check security group rules

**ASG Not Scaling**
- Verify CloudWatch alarms are created
- Check IAM permissions for CloudWatch
- Review ASG limits and configuration

**Terraform State Conflicts**
- Use remote state backend (S3 + DynamoDB)
- Enable state locking
- Coordinate with team members

## Additional Documentation

- [ARCHITECTURE_DIAGRAMS.md](./ARCHITECTURE_DIAGRAMS.md) - Architecture diagrams
- [HLD_ARCHITECTURE_PLAN.md](./HLD_ARCHITECTURE_PLAN.md) - High-level design
- [BEST_PRACTICES_ANALYSIS.md](./BEST_PRACTICES_ANALYSIS.md) - Best practices review
- [MODULARIZATION_REVIEW.md](./MODULARIZATION_REVIEW.md) - Module structure review
- [VERSION_HISTORY.md](./VERSION_HISTORY.md) - Change history

## Contributing

When making changes:
1. Update relevant documentation
2. Test changes in a development environment
3. Update `VERSION_HISTORY.md` with changes
4. Follow Terraform best practices

## License

See LICENSE file for details.

---

**Last Updated**: 2025-12-28  
**Terraform Version**: >= 1.0  
**AWS Provider Version**: ~> 5.0
