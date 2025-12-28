# AWS Resource Limits for This Infrastructure

This document outlines the instance type and EBS limits for your Terraform infrastructure.

## EC2 Instance Type Limits

### Allowed Instance Types

Your infrastructure is configured to use **burstable performance instances (T-series) only**:

#### Supported Instance Families
- **t2**: nano, micro, small, medium
- **t3**: nano, micro, small, medium  
- **t4g**: nano, micro, small, medium (ARM-based)

#### Current Configuration
Based on your `terraform.tfvars`:
- **EC2 Instances**: `t3.micro` (default)
- **ASG Instances**: `t3.micro` (default)
- **EKS Node Instances**: `t3.small` (default)

### Instance Resource Limits

#### Per Instance Limits
- **Max vCPUs per instance**: 2 vCPUs
- **Max RAM per instance**: 4 GB

#### Account-Wide Limits
- **Max concurrent instances**: 10 instances
- **Max total vCPUs**: 10 vCPUs across all instances
- **Max total RAM**: 20 GiB across all instances

#### Instance Specifications by Type

| Instance Type | vCPUs | RAM (GiB) | Network Performance | EBS Bandwidth (Mbps) |
|---------------|-------|-----------|---------------------|----------------------|
| t2.nano       | 1     | 0.5       | Low to Moderate     | Up to 32             |
| t2.micro      | 1     | 1         | Low to Moderate     | Up to 32             |
| t2.small      | 1     | 2         | Low to Moderate     | Up to 32             |
| t2.medium     | 2     | 4         | Low to Moderate     | Up to 32             |
| t3.nano       | 2     | 0.5       | Up to 5 Gbps        | Up to 2,085          |
| t3.micro      | 2     | 1         | Up to 5 Gbps        | Up to 2,085          |
| t3.small      | 2     | 2         | Up to 5 Gbps        | Up to 2,085          |
| t3.medium     | 2     | 4         | Up to 5 Gbps        | Up to 2,085          |
| t4g.nano      | 2     | 0.5       | Up to 5 Gbps        | Up to 2,085          |
| t4g.micro     | 2     | 1         | Up to 5 Gbps        | Up to 2,085          |
| t4g.small     | 2     | 2         | Up to 5 Gbps        | Up to 2,085          |
| t4g.medium    | 2     | 4         | Up to 5 Gbps        | Up to 2,085          |

### Instance Lifecycle Rules
- **Max stopped instances**: 3 instances at any time
- **Shutdown behavior**: Terminate (instances are terminated on shutdown)

### Explicitly Disallowed Instance Types
Do NOT use:
- ❌ Spot Instances
- ❌ Dedicated Hosts
- ❌ Capacity Reservations
- ❌ Scheduled Instances
- ❌ Reserved Instances (unless explicitly required)
- ❌ Instance Store volumes (ephemeral storage)
- ❌ Non-T-series instances (m5, c5, r5, etc.)

## EBS (Elastic Block Storage) Limits

### Allowed Volume Types
- **GP2** (General Purpose SSD) - Default
- **GP3** (General Purpose SSD) - Recommended for cost optimization

### EBS Volume Limits

#### Per Volume Limits
- **Max volume size**: **30 GB per volume**
- **Min volume size**: 1 GB (for GP2/GP3)
- **IOPS**: Standard IOPS only (no Provisioned IOPS)
- **Throughput**: Standard throughput limits

#### GP2 Specifications
- **Baseline IOPS**: 3 IOPS per GB (min 100 IOPS, max 16,000 IOPS)
- **Burst IOPS**: Up to 3,000 IOPS
- **Throughput**: Up to 250 MB/s
- **Volume size range**: 1 GB - 16 TB (but limited to 30 GB in your environment)

#### GP3 Specifications
- **Baseline IOPS**: 3,000 IOPS (can be increased up to 16,000)
- **Burst IOPS**: Not applicable (consistent performance)
- **Throughput**: 125 MB/s (can be increased up to 1,000 MB/s)
- **Volume size range**: 1 GB - 16 TB (but limited to 30 GB in your environment)

### EBS Features

#### Allowed Operations
- ✅ Basic snapshot management
- ✅ Standard volume operations (create, attach, detach, delete)
- ✅ Encryption supported (SSE - Server-Side Encryption)
- ✅ Volume modifications (size, type)

#### Disallowed Features
- ❌ Provisioned IOPS (io1, io2 volumes)
- ❌ Throughput Optimized HDD (st1)
- ❌ Cold HDD (sc1)
- ❌ Magnetic volumes (standard)
- ❌ Fast Snapshot Restores (FSR)

### Current EBS Configuration

Your infrastructure uses **default EBS volumes** created automatically by EC2 instances:
- **Volume type**: GP2 (default from AMI)
- **Volume size**: Determined by AMI (typically 8 GB for Amazon Linux 2)
- **Encryption**: Not explicitly configured (uses default AMI settings)

### EBS Cost Considerations

| Volume Type | Cost per GB/month | IOPS Cost | Throughput Cost |
|-------------|-------------------|-----------|----------------|
| GP2         | $0.10             | Included  | Included       |
| GP3         | $0.08             | $0.005/IOPS (above 3,000) | $0.04/MBps (above 125) |

**Example**: 30 GB GP3 volume = $2.40/month (vs $3.00/month for GP2)

## Recommendations

### Instance Type Selection

1. **Development/Testing**: Use `t3.micro` or `t3.nano`
   - Cost-effective
   - Sufficient for basic workloads
   - 2 vCPUs, 1-2 GB RAM

2. **Production (Light)**: Use `t3.small` or `t3.medium`
   - Better performance
   - More RAM for applications
   - 2 vCPUs, 2-4 GB RAM

3. **EKS Nodes**: Use `t3.small` (current setting)
   - Good balance of cost and performance
   - Sufficient for container workloads
   - 2 vCPUs, 2 GB RAM

### EBS Volume Optimization

1. **Use GP3 instead of GP2**:
   ```hcl
   # In your EC2 module, you could add:
   root_block_device {
     volume_type = "gp3"
     volume_size = 20  # Max 30 GB
     encrypted   = true
   }
   ```

2. **Right-size volumes**:
   - Start with 20 GB for most workloads
   - Increase only if needed (up to 30 GB limit)
   - Monitor disk usage with CloudWatch

3. **Enable encryption**:
   - Always encrypt EBS volumes
   - Use AWS-managed keys (default)

## Checking Current Limits

### Check Instance Limits
```bash
# Check current running instances
aws ec2 describe-instances \
  --filters "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].[InstanceId,InstanceType,State.Name]' \
  --output table

# Check account limits
aws service-quotas get-service-quota \
  --service-code ec2 \
  --quota-code L-0263D0A3  # Running On-Demand EC2 instances
```

### Check EBS Limits
```bash
# List all EBS volumes
aws ec2 describe-volumes \
  --query 'Volumes[*].[VolumeId,Size,VolumeType,State]' \
  --output table

# Check volume size limits
aws service-quotas get-service-quota \
  --service-code ebs \
  --quota-code L-D18FCD1D  # General Purpose SSD (gp2) volume storage
```

## Requesting Limit Increases

If you need to increase limits, you can request via AWS Support:

1. **AWS Console**: 
   - Go to Service Quotas → AWS services → EC2 or EBS
   - Select the quota and click "Request quota increase"

2. **AWS CLI**:
   ```bash
   aws service-quotas request-service-quota-increase \
     --service-code ec2 \
     --quota-code L-0263D0A3 \
     --desired-value 20
   ```

## Summary

### Instance Type Summary
- ✅ **Allowed**: t2/t3/t4g (nano, micro, small, medium)
- ❌ **Not Allowed**: All other instance families
- 📊 **Per Instance**: Max 2 vCPU, 4 GB RAM
- 📊 **Account Total**: Max 10 instances, 10 vCPUs, 20 GiB RAM

### EBS Summary
- ✅ **Allowed**: GP2, GP3 volume types
- ❌ **Not Allowed**: io1, io2, st1, sc1, standard
- 📊 **Per Volume**: Max 30 GB
- 📊 **Features**: Standard IOPS, encryption supported

---

**Last Updated**: 2025-12-28

