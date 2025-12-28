# AWS Infrastructure Rules and Constraints

## Context / Constraints (Must Always Be Enforced)
You are working within a restricted AWS environment. Any infrastructure code, configuration, validation logic, or recommendations must strictly comply with the following rules. Do not suggest or generate anything outside these limits.

## EC2 (Elastic Compute Cloud)

### Allowed EC2 Instance Types
- **t2**: nano, micro, small, medium
- **t3**: nano, micro, small, medium
- **t4g**: nano, micro, small, medium (ARM-based)

### Supported Operating Systems
- RHEL (Red Hat Enterprise Linux)
- Amazon Linux 2
- Windows
- Ubuntu

### Compute & Resource Limits
- **Per Instance:**
  - Max vCPUs per instance: 2
  - Max RAM per instance: 4 GB
- **Concurrent Instances:**
  - Max concurrent instances: 10
- **Account-wide limits:**
  - Max 10 vCPUs total
  - Max 20 GiB RAM total

### Storage Constraints
- Max volume size: 30 GB
- Allowed volume types: **GP2, GP3 only**
- Any generated storage must respect these limits

### Instance & Lifecycle Rules
- No more than 3 stopped instances allowed at any time
- Instance shutdown behavior: **Terminate**
- Use burstable performance instances (T-series) only

### Explicitly Disallowed Features
Do NOT generate or reference:
- Spot Instances
- Dedicated Hosts
- Capacity Reservations
- Scheduled Instances
- Fast Snapshot Restores (FSR)
- Reserved Instances (unless explicitly required)
- Instance Store volumes (ephemeral storage)

## VPC (Virtual Private Cloud) & Networking

### Allowed Features
- VPC creation with CIDR blocks
- Public and Private Subnets
- Internet Gateway (IGW)
- NAT Gateway (for private subnet internet access)
- Route Tables and Route Table Associations
- Security Groups
- Network ACLs (basic)

### Limits
- Standard VPC limits apply
- NAT Gateways: Use only when required for private subnet internet access
- No more than 3 NAT Gateways per VPC (one per availability zone)

### Explicitly Disallowed Features
Do NOT generate or reference:
- VPN Connections
- VPN Gateways
- Transit Gateways
- VPC Peering (unless explicitly required)
- Traffic Mirroring
- AWS PrivateLink endpoints (unless explicitly required)
- Direct Connect


## AWS Lambda

### Allowed
- **Supported Languages:**
  - Python, Java, Node.js, Go, Ruby, .NET Core, and more
- **Function Configuration:**
  - Basic monitoring
  - Function URLs supported
  - Layer usage permitted
  - Environment variables

### Limits
- **Memory:** Max 256 MB
- **Timeout:** Max 10 seconds
- **Invocation Rate:** Max 300/hour
- **Container images:** Not supported (use ZIP deployment only)


## EC2 Image Builder

### Allowed
- **Valid schedules:** "rate(1 day)" or "cron" with a daily frequency
- **Allowed Instance Types:**
  - t3.micro, t3.small, t3.medium
  - t4g.micro, t4g.small, t4g.medium
- **Components:**
  - Basic build components
  - Standard OS support
- **Pipeline:**
  - Basic build pipeline
  - Standard distribution

### Limits
- Limited customization of components
- Limited testing for pipeline


## Elastic Beanstalk

### Allowed
- **Environments:**
  - Web server supported
  - Worker supported
- **Platform:**
  - Latest versions only
  - Standard platform branches

### Limits
- EC2 limits apply (see EC2 section)
- Basic load balancing only
- Limited custom platforms
- No advanced configuration options


## EKS (Elastic Kubernetes Service)

### Allowed
- Basic operations are supported
- **Managed node groups (EC2-based)** - Optional, use when Fargate doesn't meet requirements
- **Fargate profiles** - Recommended for resource-constrained environments
- Standard Kubernetes features

### Service Roles Permitted
- **Cluster Service Role:** 
  - Permitted name: `eksClusterRole`
  - Must have `AmazonEKSClusterPolicy` attached
- **Node Service Role (for managed node groups):**
  - Permitted name: `AmazonEKSNodeRole`
  - Must have policies attached:
    - `AmazonEKSWorkerNodePolicy`
    - `AmazonEKS_CNI_Policy`
    - `AmazonEC2ContainerRegistryReadOnly`
- **Fargate Pod Execution Role:**
  - Custom IAM role with `AmazonEKSFargatePodExecutionRolePolicy`
  - Created automatically by Terraform if not provided

### Node Group Instance Types (for managed node groups only)
- **Must comply with EC2 instance type restrictions:**
  - t2: nano, micro, small, medium
  - t3: nano, micro, small, medium
  - t4g: nano, micro, small, medium
- **Node sizing:** Must respect EC2 resource limits (2 vCPU, 4 GB RAM per instance)
- **Limit:** Maximum 3 EC2 nodes per node group

### Fargate Profiles (Recommended)
- **Recommended for resource-constrained environments** due to strict pod limits
- **Advantages:**
  - No EC2 instance management required
  - Automatic scaling based on pod requests
  - Automatic compliance with pod resource limits
  - Pay only for running pods
- **Requirements:**
  - Pods MUST have resource requests and limits defined
  - Maximum 3 Fargate profiles per cluster
- **Limitations:**
  - DaemonSets not supported
  - Privileged containers not supported
  - Host networking not supported

### Limits
- **Pod Resource Limits:**
  - Maximum CPU per Pod: 256 millicores
  - Maximum Memory per Pod: 512 MiB
- **Pod Count per Namespace:**
  - Maximum Pods per Namespace: 3 pods
- **Cluster Resource Caps:**
  - Cumulative CPU Cap per Cluster: 2000 millicores (2 CPUs)
  - Cumulative Memory Cap per Cluster: 4096 MiB (4 GB)
- **Fargate Profiles:**
  - Maximum Fargate Profiles per Cluster: 3 profiles
- **Account-Level Resource Caps:**
  - Maximum Account-Wide CPU Cap: 6000 millicores (6 CPUs)
  - Maximum Account-Wide Memory Cap: 12288 MiB (12 GiB)
- **Node Groups (if using managed node groups):**
  - Maximum nodes per cluster: Limited by account-wide EC2 limits
  - Maximum 3 nodes per node group
  - Node groups must use private subnets (with NAT Gateway) or public subnets
  - Must carefully manage node counts to stay within cluster and account CPU limits


## ECR/ECR Public (Elastic Container Registry)

### Allowed
- Basic operations are supported
- **Repository Features:**
  - Basic operations (push/pull)
  - Scanning enabled
  - Lifecycle policies
- **Access:**
  - Standard authentication
  - Public repository support
  - IAM-based access control

### Limits
- Standard ECR limits apply
- No advanced features (replication, cross-region, etc.)

## S3 (Simple Storage Service)

### Allowed
- Basic operations are supported
- **Operations:**
  - Standard bucket operations
  - Object management (upload, download, delete)
  - Basic lifecycle rules
  - Versioning (basic)
- **Encryption:**
  - Standard encryption required (SSE-S3 or SSE-KMS)

### Limits
- No compliance mode locks
- Limited bucket policies (basic IAM policies only)
- Standard encryption required
- No advanced features (replication, analytics, etc.)

## EBS (Elastic Block Storage)

### Allowed
- **Operations:**
  - Basic snapshot management
  - Standard volume operations
  - Encryption supported (SSE)
- **Volume Types:**
  - GP2 (General Purpose SSD)
  - GP3 (General Purpose SSD)

### Resource Limits
- **Volume Types:** GP2/GP3 only
- **Max volume size:** 30 GB per volume
- **IOPS:** Standard IOPS only (no Provisioned IOPS)
- **Throughput:** Standard throughput limits


## EFS (Elastic File System)

### Allowed
- Basic operations are supported
- **Performance:**
  - General Purpose performance mode only
  - Transition to IA (Infrequent Access) after one day
  - Bursting throughput only
  - Standard IOPS limits
- **Features:**
  - Lifecycle management
  - Basic access points
  - Standard encryption (at rest and in transit)

### Resource Limits
- **File Systems:**
  - Max 2 per account
  - Max 5 GB per system
  - Growth: 1 GB/hour max
- **No Provisioned Throughput mode**




## RDS (Relational Database Service)

### Allowed
- **Instance Classes allowed:**
  - *.micro, *.small, *.medium
- **Instance Types allowed:**
  - db.t2.small, db.t3.small, db.t4g.small
  - db.t2.nano, db.t3.nano, db.t4g.nano
  - db.t2.micro, db.t3.micro, db.t4g.micro
  - db.t2.medium, db.t3.medium, db.t4g.medium
  - (Burstable classes - T series only)
- **Engines:**
  - MariaDB, MySQL
  - PostgreSQL
  - Oracle SE 2
  - SQL Server Express Edition
  - Aurora MySQL/PostgreSQL

### Specificities
- Creating roles, attaching policies and passing roles specific to:
  - `rds-monitoring-role`
  - `rds-proxy-role-*`
  - `kk-rds-role`
- Creating policies that include `rds-proxy` or `kk-rds-policy`

### Resource Limits
- **Storage:**
  - Max 30 GB
  - Standard IOPS only
  - No Provisioned IOPS for RDS Storage
- **Volume Types:** GP2/GP3 only

### Key Considerations
- Use the Dev/Test or Free tier template, wherever prompted
- Burstable (T-classes) to be used as the instance configuration
- If prompted for Deployment options, please select **Single-AZ DB instance deployment**
- Stick to GP2/GP3, as there would be constraints on Provisioned IOPS
- No Multi-AZ deployments


## DynamoDB

### Allowed
- **Capacity:**
  - Provisioned Throughput
    - Read Capacity Units (RCU): 1
    - Write Capacity Units (WCU): 1
  - Table Class: `PAY_PER_REQUEST` (On-Demand)
- **Features:**
  - PartiQL supported
  - Point-in-time recovery
  - Basic backup features
  - TTL (Time To Live)
  - Streams (basic)

### Limits
- No global tables
- No advanced features (DAX, Global Tables, etc.)
- Standard encryption at rest

## IAM (Identity and Access Management)

### Allowed
- **Roles:**
  - Service roles for AWS services (EC2, EKS, RDS, etc.)
  - Custom IAM roles with managed policies
- **Policies:**
  - AWS managed policies
  - Custom inline policies (basic)
  - Policy attachments

### Limits
- Standard IAM limits apply
- No advanced features (SAML, OIDC providers unless explicitly required)
- Use least privilege principle

## Terraform Best Practices

### Module Structure
- Use modular structure for reusable components
- Separate modules for: VPC, EC2, EKS, RDS, etc.
- Each module should have: `main.tf`, `variables.tf`, `outputs.tf`

### Resource Naming
- Use consistent naming: `{project_name}-{resource-type}-{identifier}`
- Include resource type in names for clarity
- Use tags for resource organization

### Configuration
- Use `terraform.tfvars` for environment-specific values
- Never commit sensitive data (credentials, keys)
- Use variables with sensible defaults
- Document all variables with descriptions

### Validation
- Always validate instance types against allowed list
- Check resource limits before creating resources
- Ensure storage volumes use GP2/GP3 only
- Verify EC2 instance types comply with vCPU/RAM limits
- Validate EKS node instance types against EC2 restrictions
- Check account-wide resource limits before provisioning
- **For EKS:**
  - Prefer Fargate profiles for resource-constrained environments
  - If using managed node groups, ensure total CPU/memory stays within cluster and account limits
  - Verify pods have resource requests/limits when using Fargate
  - Ensure node group configurations don't exceed account-wide CPU cap (6000 millicores)


Quick note on IAM roles

EC2LabRole supports both PutRolePolicy and PassRole permissions.
SecretsManagerRDSMySQLRot-* too could be utilised for RDS-specific scenarios
‍
‍
EC2 Instances (Virtual Machines / Servers)

EC2 instances are virtual servers. They are elastic, meaning they can easily scale up or down.
Use nano, micro, small, or medium sizes for t1, t2, and t3 instances.
Use gp2 (General Purpose) volumes with a maximum storage size of 30GB.
Maximum of 3 stopped instances. If exceeded, all are terminated.
EC2 instances stop behavior is set to "terminate."
Total number of EC2 instances is limited to 5.
Ensure a default VPC exists, creating one if necessary.
‍
S3 - Object Storage

S3 buckets store files for easy upload and download.
Bucket names must be unique. Add random numbers to ensure uniqueness.
‍
RDS - Relational Database Service

RDS supports MySQL, MariaDB, PostgreSQL, Oracle, Microsoft SQL Server, and Amazon Aurora.
Use the Free tier for MySQL, MariaDB, and PostgreSQL.
For other engines, use a Single DB Instance, Burstable Class, micro or small instance, and General Purpose SSD (gp2).
‍
EKS - Elastic Kubernetes Service

EKS quickly sets up a Kubernetes cluster.
Cluster service role name: eksClusterRole (permitted name)
Node service role name: AmazonEKSNodeRole (permitted name)
CloudFormation stack name: eks-cluster-stack
**Fargate profiles are recommended** for resource-constrained environments (256m CPU, 512Mi memory per pod limits).
Limit of 3 Fargate profiles per cluster.
If using managed node groups:
  - Limit of 3 EC2 nodes per node group
  - Allowed EC2 instance types: t2.micro, t2.nano, t2.small, t2.medium, t3.micro, t3.nano, t3.small, t3.medium
  - Must respect account-wide CPU cap: 6000 millicores (6 CPUs)
  - Must respect cluster CPU cap: 2000 millicores (2 CPUs)
‍
ECR - Elastic Container Registry

Create and manage container repositories, similar to Docker Hub.
‍
Lambda - Serverless Computing

Run code without managing servers.
Memory size is limited to 256 MB, and timeout to 10 seconds. Violations are updated to 128 MB and 3 seconds.
If a function is invoked over 300 times in the last hour, it is deleted.
‍
CodePipeline - CI/CD Service

Automates build, test, and deploy phases.
Compute types limited to t3.micro, t3.small, t3.medium. Violations updated to t3.micro.
‍
CodeDeploy - Deployment Service

Automates application releases.
Allowed EC2 instance types: t2.micro, t3.micro, t3.nano. Violations updated to t2.micro.
‍
CodeBuild - Build Service

Compiles source code, runs tests, and produces packages.
Allowed compute types: BUILD_GENERAL1_SMALL, BUILD_GENERAL2_SMALL.
Violations updated to BUILD_GENERAL1_SMALL.
‍
ECS - Elastic Container Service

Manages containerized applications.
Limit of 3 container instances (EC2) per cluster. Violations result in cluster deletion.
Allowed EC2 instance types same as EKS.
Limit of 3 Fargate tasks per cluster.
‍
DynamoDB - NoSQL Database Service

Provides fast, scalable NoSQL databases.
Provisioned throughput set to 1 read and 1 write capacity unit.
Billing mode set to "PAY_PER_REQUEST."