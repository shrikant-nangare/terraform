# High-Level Design (HLD) and Architecture Plan

## Document Information
- **Project**: AWS Infrastructure as Code (Terraform)
- **Version**: 1.0
- **Date**: 2024
- **Author**: Infrastructure Team

---

## Table of Contents
1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Component Details](#component-details)
4. [Network Design](#network-design)
5. [Security Design](#security-design)
6. [Scalability and High Availability](#scalability-and-high-availability)
7. [Deployment Strategy](#deployment-strategy)
8. [Cost Considerations](#cost-considerations)
9. [Monitoring and Logging](#monitoring-and-logging)
10. [Disaster Recovery](#disaster-recovery)
11. [Appendix](#appendix)

---

## Executive Summary

This document outlines the High-Level Design (HLD) and architecture plan for a comprehensive AWS infrastructure deployment using Terraform. The infrastructure is designed to support multiple compute workloads including standalone EC2 instances, Auto Scaling Groups (ASG), and an Amazon EKS (Elastic Kubernetes Service) cluster.

### Key Objectives
- **Modularity**: Infrastructure is organized into reusable Terraform modules
- **High Availability**: Multi-AZ deployment across 3 availability zones
- **Scalability**: Auto-scaling capabilities for EC2 workloads
- **Security**: Network isolation with public/private subnet architecture
- **Container Orchestration**: EKS cluster for containerized workloads

### Infrastructure Components
- **VPC**: Custom VPC with public and private subnets across 3 AZs
- **EC2 Instances**: Standalone instances in public and private subnets
- **Auto Scaling Groups**: CPU-based auto-scaling for EC2 workloads
- **EKS Cluster**: Managed Kubernetes cluster with node groups

---

## Architecture Overview

### High-Level Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWS Cloud                                 │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                    VPC (10.0.0.0/16)                      │  │
│  │                                                             │  │
│  │  ┌─────────────────────────────────────────────────────┐  │  │
│  │  │              Internet Gateway (IGW)                  │  │  │
│  │  └─────────────────────────────────────────────────────┘  │  │
│  │                                                             │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐   │  │
│  │  │   AZ-1       │  │   AZ-2       │  │   AZ-3       │   │  │
│  │  │              │  │              │  │              │   │  │
│  │  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │   │  │
│  │  │ │ Public   │ │  │ │ Public   │ │  │ │ Public   │ │   │  │
│  │  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │   │  │
│  │  │ │ 10.0.0/19│ │  │ │ 10.0.32/19│ │  │ │ 10.0.64/19│ │   │  │
│  │  │ │          │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ ┌──────┐ │ │  │ │ ┌──────┐ │ │  │ │ ┌──────┐ │ │   │  │
│  │  │ │ │ NAT  │ │ │  │ │ │ NAT  │ │ │  │ │ │ NAT  │ │ │   │  │
│  │  │ │ │ GW   │ │ │  │ │ │ GW   │ │ │  │ │ │ GW   │ │ │   │  │
│  │  │ │ └──────┘ │ │  │ │ └──────┘ │ │  │ │ └──────┘ │ │   │  │
│  │  │ │          │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ EC2      │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ Instance │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │          │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ ASG     │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ (Public)│ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │         │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ EKS     │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ Node    │ │  │ │          │ │  │ │          │ │   │  │
│  │  │ │ (Public)│ │  │ │          │ │  │ │          │ │   │  │
│  │  │ └──────────┘ │  │ │ └──────────┘ │  │ │ └──────────┘ │   │  │
│  │  │              │  │ │              │  │ │              │   │  │
│  │  │ ┌──────────┐ │  │ │ ┌──────────┐ │  │ │ ┌──────────┐ │   │  │
│  │  │ │ Private  │ │  │ │ │ Private  │ │  │ │ │ Private  │ │   │  │
│  │  │ │ Subnet   │ │  │ │ │ Subnet   │ │  │ │ │ Subnet   │ │   │  │
│  │  │ │10.0.96/19│ │  │ │ │10.0.128/19│ │  │ │ │10.0.160/19│ │   │  │
│  │  │ │          │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ EC2      │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ Instance │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │          │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ ASG      │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │(Private) │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │          │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ EKS      │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ Node     │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │(Private) │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │          │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ EKS      │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ Control  │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ │ Plane    │ │  │ │ │          │ │  │ │ │          │ │   │  │
│  │  │ └──────────┘ │  │ │ └──────────┘ │  │ │ └──────────┘ │   │  │
│  │  └──────────────┘  └──────────────┘  └──────────────┘   │  │
│  │                                                             │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │              CloudWatch Logs & Metrics                      │  │
│  └───────────────────────────────────────────────────────────┘  │
│                                                                   │
└─────────────────────────────────────────────────────────────────┘
```

### Component Interaction Flow

```
Internet
   │
   ├─→ Internet Gateway
   │      │
   │      ├─→ Public Subnets (Direct Access)
   │      │      ├─→ EC2 Public Instance
   │      │      ├─→ ASG Public Instances
   │      │      └─→ EKS Public Node Group
   │      │
   │      └─→ NAT Gateways (One per AZ)
   │             │
   │             └─→ Private Subnets (Outbound Only)
   │                    ├─→ EC2 Private Instance
   │                    ├─→ ASG Private Instances
   │                    ├─→ EKS Private Node Group
   │                    └─→ EKS Control Plane
```

---

## Component Details

### 1. VPC Module (`modules/vpc`)

#### Purpose
Creates the foundational networking infrastructure for all other components.

#### Components
- **VPC**: Single VPC with CIDR block (default: 10.0.0.0/16)
- **Internet Gateway**: Provides internet access to public subnets
- **Public Subnets**: Configurable count (default: 3) across multiple AZs
- **Private Subnets**: Configurable count (default: 3) across multiple AZs
- **Subnet Count**: Configurable via `vpc_subnet_count` variable (1-6 subnets)
- **NAT Gateway**: Single NAT gateway (cost-optimized) in first public subnet, shared by all private subnets
- **Route Tables**: 
  - 1 public route table (routes to IGW)
  - 3 private route tables (all routes to the single NAT Gateway)

#### Key Features
- DNS hostnames and DNS support enabled
- Multi-AZ deployment for high availability
- Configurable NAT gateway (can be disabled for cost optimization)

#### Configuration
```hcl
module "vpc" {
  source = "./modules/vpc"
  
  project_name       = var.project_name
  vpc_cidr           = var.vpc_cidr              # Default: 10.0.0.0/16
  enable_nat_gateway = var.enable_nat_gateway    # Default: true
  tags               = var.tags
}
```

---

### 2. EC2 Module (`modules/ec2`)

#### Purpose
Deploys standalone EC2 instances for fixed workloads that don't require auto-scaling.

#### Components
- **Public EC2 Instance**: 1 instance in the first public subnet
  - Direct internet access
  - Public IP assigned
  - SSH access from configured CIDR
  - HTTP/HTTPS access from internet
  
- **Private EC2 Instance**: 1 instance in the first private subnet
  - No direct internet access
  - Outbound access via NAT Gateway
  - SSH access from public subnet security group
  - Accessible from within VPC

#### Security Groups
- **Public Security Group**:
  - Ingress: SSH (22), HTTP (80), HTTPS (443)
  - Egress: All traffic
  
- **Private Security Group**:
  - Ingress: SSH from public SG, All traffic from VPC CIDR
  - Egress: All traffic

#### Configuration
```hcl
module "ec2" {
  source = "./modules/ec2"
  
  project_name       = var.project_name
  vpc_id             = module.vpc.vpc_id
  vpc_cidr           = module.vpc.vpc_cidr_block
  public_subnet_ids  = module.vpc.public_subnet_ids
  private_subnet_ids = module.vpc.private_subnet_ids
  instance_type      = var.instance_type         # Default: t3.micro
  key_pair_name      = var.key_pair_name
  ssh_allowed_cidr   = var.ssh_allowed_cidr      # Default: 0.0.0.0/0
  user_data          = var.user_data
  tags               = var.tags
}
```

---

### 3. Auto Scaling Group Module (`modules/asg`)

#### Purpose
Provides auto-scaling capabilities for EC2 workloads based on CPU utilization.

#### Components
- **Public ASG**: Auto Scaling Group in public subnet
- **Private ASG**: Auto Scaling Group in private subnet
- **Launch Templates**: Separate templates for public and private instances
- **CloudWatch Alarms**: CPU utilization alarms for scale-up and scale-down
- **Auto Scaling Policies**: Policies triggered by CloudWatch alarms

#### Auto Scaling Configuration
- **Scaling Trigger**: CPU utilization (default: 60%)
- **Evaluation Periods**: 2 periods (10 minutes total)
- **Scaling Adjustment**: ±1 instance per alarm trigger
- **Cooldown Period**: 300 seconds (5 minutes)
- **Health Check**: EC2 health check type
- **Health Check Grace Period**: 300 seconds

#### Scaling Behavior
```
CPU Utilization > 60% (for 10 minutes) → Scale Up (+1 instance)
CPU Utilization < 60% (for 10 minutes) → Scale Down (-1 instance)
```

#### IAM Roles
- **ASG IAM Role**: Allows instances to send metrics to CloudWatch
- **Attached Policy**: CloudWatchAgentServerPolicy

#### Configuration
```hcl
module "asg" {
  source = "./modules/asg"
  
  project_name            = var.project_name
  public_subnet_id        = module.vpc.public_subnet_ids[0]
  private_subnet_id       = module.vpc.private_subnet_ids[0]
  public_security_group_id  = module.ec2.public_security_group_id
  private_security_group_id = module.ec2.private_security_group_id
  instance_type           = var.asg_instance_type      # Default: t3.micro
  key_pair_name           = var.key_pair_name
  min_size                = var.asg_min_size            # Default: 1
  max_size                = var.asg_max_size            # Default: 5
  desired_capacity        = var.asg_desired_capacity    # Default: 1
  cpu_target               = var.asg_cpu_target          # Default: 60
  user_data               = var.user_data
  tags                    = var.tags
}
```

---

### 4. EKS Module (`modules/eks`)

#### Purpose
Deploys a managed Kubernetes cluster for containerized workloads.

#### Components
- **EKS Cluster**: Managed Kubernetes control plane
  - Kubernetes version: 1.32 (configurable, supports 1.32, 1.33, 1.34)
  - Private endpoint access: Enabled
  - Public endpoint access: Configurable
  - CloudWatch logging: Enabled (API, audit, authenticator, controller, scheduler)
  
- **Private Node Group**: Nodes in private subnet
  - Configurable scaling: min/max/desired (default: 1/3/2)
  - Instance type: t3.small (configurable)
  - Label: subnet-type=private
  
- **Public Node Group**: Nodes in public subnet (optional)
  - Configurable scaling: min/max/desired (default: 1/3/2)
  - Instance type: t3.small (configurable)
  - Label: subnet-type=public

#### IAM Roles

The infrastructure supports two approaches for IAM roles:

**Option 1: Create Roles with Permitted Names (Default)**
- **Cluster Role**: `eksClusterRole`
  - Policy: AmazonEKSClusterPolicy
  - Trust: eks.amazonaws.com
  - Created automatically by Terraform if `use_eks_permitted_roles = true`
  
- **Node Group Role**: `AmazonEKSNodeRole`
  - Policies: 
    - AmazonEKSWorkerNodePolicy
    - AmazonEKS_CNI_Policy
    - AmazonEC2ContainerRegistryReadOnly
  - Trust: ec2.amazonaws.com
  - Created automatically by Terraform if `use_eks_permitted_roles = true`

**Option 2: Use Existing Roles**
- Provide existing role ARNs via `eks_cluster_role_arn` and `eks_node_group_role_arn`
- Set `use_eks_permitted_roles = false`
- Useful for restricted environments without `iam:PassRole` permission

#### Security Groups
- **Cluster Security Group**:
  - Egress: All traffic
  - Ingress: Port 443 from node groups
  
- **Private Node Group Security Group**:
  - Ingress: Ports 1025-65535 from cluster, all traffic from self
  - Egress: All traffic
  
- **Public Node Group Security Group**:
  - Ingress: Ports 1025-65535 from cluster, all traffic from self and private nodes
  - Egress: All traffic

#### Configuration
```hcl
module "eks" {
  source = "./modules/eks"
  
  project_name       = var.project_name
  cluster_name       = var.eks_cluster_name != "" ? var.eks_cluster_name : "${var.project_name}-cluster"
  vpc_id             = module.vpc.vpc_id
  private_subnet_ids = module.vpc.private_subnet_ids
  public_subnet_ids  = module.vpc.public_subnet_ids
  kubernetes_version = var.eks_kubernetes_version    # Default: 1.32
  node_instance_type = var.eks_node_instance_type    # Default: t3.small
  key_pair_name      = var.key_pair_name
  tags               = var.tags
}
```

---

## Network Design

### IP Address Allocation

| Component | CIDR Block | Subnet Size | Purpose |
|-----------|------------|-------------|---------|
| VPC | 10.0.0.0/16 | /16 (65,536 IPs) | Main VPC CIDR |
| Public Subnet 1 (AZ-1) | 10.0.0.0/19 | /19 (8,192 IPs) | Public resources in AZ-1 |
| Public Subnet 2 (AZ-2) | 10.0.32.0/19 | /19 (8,192 IPs) | Public resources in AZ-2 |
| Public Subnet 3 (AZ-3) | 10.0.64.0/19 | /19 (8,192 IPs) | Public resources in AZ-3 |
| Private Subnet 1 (AZ-1) | 10.0.96.0/19 | /19 (8,192 IPs) | Private resources in AZ-1 |
| Private Subnet 2 (AZ-2) | 10.0.128.0/19 | /19 (8,192 IPs) | Private resources in AZ-2 |
| Private Subnet 3 (AZ-3) | 10.0.160.0/19 | /19 (8,192 IPs) | Private resources in AZ-3 |

### Routing

#### Public Subnets
- **Route Table**: Single route table for all public subnets
- **Routes**:
  - `0.0.0.0/0` → Internet Gateway
  - Local VPC traffic → Local

#### Private Subnets
- **Route Tables**: One per private subnet (3 total)
- **Routes**:
  - `0.0.0.0/0` → NAT Gateway (in same AZ)
  - Local VPC traffic → Local

### Network Flow

#### Inbound Traffic (Internet → Resources)
1. Internet → Internet Gateway
2. Internet Gateway → Public Subnet Route Table
3. Route Table → Public Subnet Resources
   - EC2 Public Instance
   - ASG Public Instances
   - EKS Public Nodes

#### Outbound Traffic (Resources → Internet)
**From Public Subnets:**
1. Resource → Public Subnet Route Table
2. Route Table → Internet Gateway
3. Internet Gateway → Internet

**From Private Subnets:**
1. Resource → Private Subnet Route Table
2. Route Table → NAT Gateway (same AZ)
3. NAT Gateway → Internet Gateway
4. Internet Gateway → Internet

#### Inter-Subnet Communication
- All resources within VPC can communicate via local routing
- Security groups control access at instance level

---

## Security Design

### Network Security

#### Defense in Depth Layers
1. **VPC Level**: Network isolation from other AWS accounts/VPCs
2. **Subnet Level**: Public/private separation
3. **Security Group Level**: Instance-level firewall rules
4. **IAM Level**: Access control and permissions

#### Security Group Rules Summary

| Security Group | Ingress Rules | Egress Rules |
|----------------|---------------|--------------|
| Public Instances SG | SSH (22) from configured CIDR<br>HTTP (80) from 0.0.0.0/0<br>HTTPS (443) from 0.0.0.0/0 | All traffic (0.0.0.0/0) |
| Private Instances SG | SSH (22) from Public Instances SG<br>All traffic from VPC CIDR | All traffic (0.0.0.0/0) |
| EKS Cluster SG | Port 443 from Node Group SGs | All traffic (0.0.0.0/0) |
| EKS Private Node SG | Ports 1025-65535 from Cluster SG<br>All traffic from self | All traffic (0.0.0.0/0) |
| EKS Public Node SG | Ports 1025-65535 from Cluster SG<br>All traffic from self<br>All traffic from Private Node SG | All traffic (0.0.0.0/0) |

### IAM Security

#### Principle of Least Privilege
- Each component has dedicated IAM roles with minimal required permissions
- No cross-component permission sharing
- Managed AWS policies used where possible

#### IAM Roles Summary

| Role | Trust Relationship | Policies |
|------|-------------------|----------|
| EKS Cluster Role (eksClusterRole) | eks.amazonaws.com | AmazonEKSClusterPolicy |
| EKS Node Group Role (AmazonEKSNodeRole) | ec2.amazonaws.com | AmazonEKSWorkerNodePolicy<br>AmazonEKS_CNI_Policy<br>AmazonEC2ContainerRegistryReadOnly |
| ASG Instance Role | ec2.amazonaws.com | CloudWatchAgentServerPolicy |
| ASG Instance Role | ec2.amazonaws.com | CloudWatchAgentServerPolicy |

### Data Security

#### Encryption
- **EBS Volumes**: Default encryption (AWS managed keys)
- **Data in Transit**: TLS/HTTPS for API communications
- **EKS Secrets**: Kubernetes secrets (consider AWS Secrets Manager integration)

#### Key Management
- AWS Key Pair for SSH access (user-provided)
- Consider AWS Systems Manager Session Manager for secure access

### Security Best Practices

1. **SSH Access Restriction**: Configure `ssh_allowed_cidr` to specific IP ranges
2. **Key Pair Management**: Use AWS Systems Manager Parameter Store or Secrets Manager
3. **Security Group Review**: Regularly audit security group rules
4. **Network ACLs**: Consider adding network ACLs for additional layer
5. **VPC Flow Logs**: Enable for network traffic monitoring
6. **CloudTrail**: Enable for API call auditing
7. **GuardDuty**: Consider enabling for threat detection

---

## Scalability and High Availability

### High Availability Design

#### Multi-AZ Deployment
- **VPC**: Spans 3 availability zones
- **Subnets**: Public and private subnets in each AZ
- **NAT Gateways**: One per AZ for redundancy
- **EKS**: Control plane is multi-AZ managed service
- **EKS Nodes**: Distributed across AZs (1 private, 1 public)

#### Availability Characteristics

| Component | Availability | Notes |
|-----------|--------------|-------|
| VPC | 99.99% | AWS managed |
| Internet Gateway | 99.99% | AWS managed |
| NAT Gateway | 99.99% per AZ | AWS managed, one per AZ |
| EC2 Instances | Single AZ | Consider multi-AZ deployment |
| ASG | Multi-AZ capable | Currently single subnet, can be expanded |
| EKS Control Plane | 99.95% | AWS managed, multi-AZ |
| EKS Nodes | Single AZ | Fixed to 1 node per subnet |

### Scalability Design

#### Horizontal Scaling
- **ASG**: Auto-scales based on CPU utilization
  - Min: 1 instance
  - Max: 5 instances (configurable)
  - Desired: 1 instance (configurable)
  
#### Vertical Scaling
- Instance types can be changed via Terraform variables
- EKS node instance types configurable

#### Scaling Recommendations

**ASG Scaling:**
- Current: Single subnet deployment
- **Recommendation**: Deploy ASG across multiple subnets/AZs for better HA
- Consider target tracking scaling policies for smoother scaling

**EKS Scaling:**
- Current: Fixed 1 node per node group
- **Recommendation**: Enable auto-scaling with Cluster Autoscaler
- Consider managed node groups with auto-scaling enabled

**EC2 Instances:**
- Current: Single instance per subnet
- **Recommendation**: Use ASG for production workloads instead of standalone instances

### Performance Considerations

#### Network Performance
- NAT Gateway: Up to 45 Gbps bandwidth per gateway
- Internet Gateway: Scales automatically
- VPC: Supports up to 5 VPCs per region (soft limit)

#### Compute Performance
- Instance types can be upgraded based on workload requirements
- Consider placement groups for low-latency requirements

---

## Deployment Strategy

### Terraform Module Structure

```
terraform/
├── main.tf                    # Root module configuration
├── variables.tf               # Root module variables
├── outputs.tf                # Root module outputs
├── terraform.tfvars.example  # Example variable values
└── modules/
    ├── vpc/                  # VPC module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── ec2/                  # EC2 module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    ├── asg/                  # Auto Scaling Group module
    │   ├── main.tf
    │   ├── variables.tf
    │   └── outputs.tf
    └── eks/                  # EKS module
        ├── main.tf
        ├── variables.tf
        └── outputs.tf
```

### Deployment Workflow

#### 1. Prerequisites
```bash
# Install Terraform (>= 1.0)
# Configure AWS credentials
aws configure

# Create SSH key pair in AWS
aws ec2 create-key-pair --key-name my-key-pair --query 'KeyMaterial' --output text > my-key-pair.pem
chmod 400 my-key-pair.pem
```

#### 2. Configuration
```bash
# Copy example variables file
cp terraform.tfvars.example terraform.tfvars

# Edit terraform.tfvars with your values
# - Set project_name
# - Set key_pair_name
# - Adjust instance types
# - Configure ASG parameters
# - Set EKS cluster name (or leave empty to disable)
```

#### 3. Initialize Terraform
```bash
terraform init
```

#### 4. Plan Deployment
```bash
terraform plan -out=tfplan
```

#### 5. Apply Configuration
```bash
terraform apply tfplan
```

#### 6. Verify Deployment
```bash
# Check outputs
terraform output

# Verify EC2 instances
aws ec2 describe-instances --filters "Name=tag:Name,Values=my-project-*"

# Verify EKS cluster
aws eks describe-cluster --name my-project-cluster
```

### Deployment Phases

#### Phase 1: Foundation (VPC)
1. Deploy VPC module
2. Verify subnets, route tables, NAT gateways
3. Test connectivity

#### Phase 2: Compute (EC2)
1. Deploy EC2 module
2. Verify instances are running
3. Test SSH access

#### Phase 3: Auto Scaling (ASG)
1. Deploy ASG module
2. Verify launch templates
3. Test auto-scaling triggers

#### Phase 4: Container Platform (EKS)
1. Deploy EKS module
2. Configure kubectl
3. Verify node groups
4. Deploy test workloads

### Rollback Strategy

#### Terraform State Management
- Use remote state backend (S3 + DynamoDB) for production
- Enable state locking
- Regular state backups

#### Rollback Procedure
```bash
# If deployment fails, use previous state
terraform state list
terraform show

# Rollback to previous version
git checkout <previous-commit>
terraform apply
```

---

## Cost Considerations

### Cost Breakdown (Estimated Monthly)

| Component | Quantity | Unit Cost | Monthly Cost |
|-----------|----------|-----------|--------------|
| VPC | 1 | Free | $0 |
| Internet Gateway | 1 | Free | $0 |
| NAT Gateway | 1 | $0.045/hour + data transfer | ~$32 + data |
| EC2 Public Instance (t3.micro) | 1 | $0.0104/hour | ~$7.50 |
| EC2 Private Instance (t3.micro) | 1 | $0.0104/hour | ~$7.50 |
| ASG Public (t3.micro, 1 instance) | 1 | $0.0104/hour | ~$7.50 |
| ASG Private (t3.micro, 1 instance) | 1 | $0.0104/hour | ~$7.50 |
| EKS Control Plane | 1 | $0.10/hour | ~$72 |
| EKS Private Node (t3.small) | 1 | $0.0208/hour | ~$15 |
| EKS Public Node (t3.small) | 1 | $0.0208/hour | ~$15 |
| EBS Volumes | Variable | $0.10/GB-month | Variable |
| Data Transfer | Variable | $0.09/GB (outbound) | Variable |
| **Total (Base)** | | | **~$230/month** |

*Note: Costs are estimates and vary by region and usage*

### Cost Optimization Recommendations

1. **NAT Gateways**: 
   - Consider single NAT Gateway for non-production
   - Use NAT Instances for cost-sensitive environments
   - Monitor data transfer costs

2. **Instance Types**:
   - Use smaller instance types for development
   - Consider Spot Instances for ASG (with appropriate handling)
   - Right-size based on actual usage

3. **EKS**:
   - Disable EKS if not needed (set `eks_cluster_name = ""`)
   - Use smaller node instance types for development
   - Consider Fargate for serverless containers

4. **Auto Scaling**:
   - Set appropriate min/max sizes
   - Use scheduled scaling for predictable workloads
   - Monitor and adjust CPU target thresholds

5. **Resource Tagging**:
   - Implement cost allocation tags
   - Use AWS Cost Explorer for analysis
   - Set up billing alerts

6. **Reserved Instances**:
   - Consider Reserved Instances for predictable workloads
   - Use Savings Plans for flexible commitments

---

## Monitoring and Logging

### CloudWatch Integration

#### Metrics Collected
- **EC2**: CPUUtilization, NetworkIn/Out, DiskReadOps/WriteOps
- **ASG**: GroupDesiredCapacity, GroupInServiceInstances, GroupTotalInstances
- **EKS**: Cluster metrics via CloudWatch Container Insights
- **NAT Gateway**: BytesInFromDestination, BytesOutToDestination, PacketDropCount

#### Alarms Configured
- **ASG CPU High**: Triggers scale-up when CPU > threshold
- **ASG CPU Low**: Triggers scale-down when CPU < threshold

#### Logs Collected
- **EKS Cluster Logs**: API, audit, authenticator, controller, scheduler
- **CloudWatch Log Group**: `/aws/eks/{cluster-name}/cluster`
- **Log Retention**: 7 days (configurable)

### Monitoring Recommendations

1. **Additional CloudWatch Alarms**:
   - EC2 instance status checks
   - EKS node health
   - NAT Gateway availability
   - VPC flow log anomalies

2. **Container Insights**:
   - Enable CloudWatch Container Insights for EKS
   - Monitor pod metrics, node metrics

3. **Application Monitoring**:
   - Integrate application-level monitoring (e.g., Prometheus, Grafana)
   - Use AWS X-Ray for distributed tracing

4. **Dashboards**:
   - Create CloudWatch dashboards for key metrics
   - Monitor cost and usage dashboards

---

## Disaster Recovery

### Backup Strategy

#### Infrastructure as Code
- **Terraform State**: Store in S3 with versioning enabled
- **Code Repository**: Version control (Git)
- **Configuration**: Store tfvars securely (encrypted)

#### Data Backup
- **EBS Snapshots**: Automated snapshots for critical volumes
- **EKS**: Backup etcd data (AWS managed)
- **Application Data**: Implement application-level backups

### Recovery Procedures

#### Infrastructure Recovery
```bash
# Restore from Terraform state
terraform init
terraform plan
terraform apply

# Restore from backup state
aws s3 cp s3://terraform-state-backup/terraform.tfstate .
terraform apply
```

#### Data Recovery
- Restore EBS volumes from snapshots
- Restore application data from backups
- Recover EKS workloads from container images

### RTO/RPO Targets

| Component | RTO Target | RPO Target | Notes |
|-----------|------------|------------|-------|
| VPC Infrastructure | < 1 hour | N/A | Infrastructure only |
| EC2 Instances | < 1 hour | < 24 hours | Depends on backup frequency |
| ASG | < 30 minutes | N/A | Auto-recovery via ASG |
| EKS Cluster | < 2 hours | < 1 hour | Control plane + nodes |
| Application Data | Variable | Variable | Application-specific |

---

## Appendix

### A. Default Configuration Values

| Variable | Default Value | Description |
|----------|---------------|-------------|
| `aws_region` | us-east-1 | AWS region |
| `project_name` | my-project | Project name prefix |
| `vpc_cidr` | 10.0.0.0/16 | VPC CIDR block |
| `enable_nat_gateway` | true | Enable NAT gateways |
| `instance_type` | t3.micro | EC2 instance type |
| `asg_instance_type` | t3.micro | ASG instance type |
| `asg_min_size` | 1 | ASG minimum size |
| `asg_max_size` | 5 | ASG maximum size |
| `asg_desired_capacity` | 1 | ASG desired capacity |
| `asg_cpu_target` | 60 | CPU target percentage |
| `eks_kubernetes_version` | 1.32 | Kubernetes version (1.32, 1.33, 1.34) |
| `eks_node_instance_type` | t3.small | EKS node instance type |

### B. Resource Naming Convention

All resources follow the pattern: `{project_name}-{resource-type}-{identifier}`

Examples:
- `my-project-vpc`
- `my-project-public-subnet-1`
- `my-project-eks-cluster-role`
- `my-project-public-asg`

### C. Terraform State Management

#### Recommended Backend Configuration
```hcl
terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "infrastructure/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "terraform-state-lock"
  }
}
```

### D. Security Checklist

- [ ] SSH access restricted to specific IP ranges
- [ ] Key pairs stored securely
- [ ] Security groups follow least privilege
- [ ] IAM roles use minimal permissions
- [ ] VPC Flow Logs enabled
- [ ] CloudTrail enabled
- [ ] Encryption enabled for EBS volumes
- [ ] Regular security group audits
- [ ] Network ACLs configured (optional)
- [ ] WAF configured for public-facing resources (if applicable)

### E. Troubleshooting Guide

#### Common Issues

1. **NAT Gateway not accessible from private subnet**
   - Check route table associations
   - Verify NAT Gateway is in public subnet
   - Check security group rules

2. **EKS nodes not joining cluster**
   - Verify IAM roles and policies
   - Check security group rules
   - Verify subnet tags

3. **ASG not scaling**
   - Check CloudWatch alarms
   - Verify IAM permissions for CloudWatch
   - Check ASG limits

4. **Terraform state conflicts**
   - Use remote state backend
   - Enable state locking
   - Coordinate with team

### F. References

- [AWS VPC Documentation](https://docs.aws.amazon.com/vpc/)
- [AWS EKS Documentation](https://docs.aws.amazon.com/eks/)
- [Terraform AWS Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- [AWS Well-Architected Framework](https://aws.amazon.com/architecture/well-architected/)

---

## Document Revision History

| Version | Date | Author | Changes |
|---------|------|--------|---------|
| 1.0 | 2024 | Infrastructure Team | Initial HLD and Architecture Plan |

---

**End of Document**

