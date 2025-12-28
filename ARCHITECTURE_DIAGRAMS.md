# Architecture Diagrams

This document contains detailed architecture diagrams for the AWS infrastructure.

## Network Architecture

### VPC and Subnet Layout

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                              AWS Region (us-east-1)                          │
│                                                                               │
│  ┌───────────────────────────────────────────────────────────────────────┐ │
│  │                        VPC: 10.0.0.0/16                                │ │
│  │                                                                         │ │
│  │  ┌───────────────────────────────────────────────────────────────────┐ │ │
│  │  │                    Internet Gateway (IGW)                          │ │ │
│  │  └───────────────────────────────────────────────────────────────────┘ │ │
│  │                              │                                          │ │
│  │                              │                                          │ │
│  │  ┌───────────────────────────┼───────────────────────────────────────┐ │ │
│  │  │      Availability Zone 1  │  Availability Zone 2  │  AZ 3        │ │ │
│  │  │                           │                       │              │ │ │
│  │  │  ┌─────────────────────┐  │  ┌─────────────────┐ │ ┌──────────┐ │ │ │
│  │  │  │ Public Subnet 1     │  │  │ Public Subnet 2 │ │ │Public    │ │ │ │
│  │  │  │ 10.0.0.0/19         │  │  │ 10.0.32.0/19   │ │ │Subnet 3  │ │ │ │
│  │  │  │                     │  │  │                 │ │ │10.0.64/19│ │ │ │
│  │  │  │ ┌─────────────────┐ │  │  │                 │ │ │          │ │ │ │
│  │  │  │ │ NAT Gateway     │ │  │  │                 │ │ │          │ │ │ │
│  │  │  │ │ + Elastic IP    │ │  │  │                 │ │ │          │ │ │ │
│  │  │  │ │ (Shared by all) │ │  │  │                 │ │ │          │ │ │ │
│  │  │  │ └─────────────────┘ │  │  │                 │ │ │          │ │ │ │
│  │  │  │                     │  │  │                 │ │ │          │ │ │ │
│  │  │  │ EC2 Public          │  │  │                 │ │ │          │ │ │ │
│  │  │  │ ASG Public          │  │  │                 │ │ │          │ │ │ │
│  │  │  │ EKS Public Node     │  │  │                 │ │ │          │ │ │ │
│  │  │  └─────────────────────┘  │  │ └─────────────────┘ │ └──────────┘ │ │ │
│  │  │                           │  │                     │              │ │ │
│  │  │  ┌─────────────────────┐  │  │  ┌─────────────────┐ │ ┌──────────┐ │ │ │
│  │  │  │ Private Subnet 1    │  │  │  │ Private Subnet 2│ │ │Private   │ │ │ │
│  │  │  │ 10.0.96.0/19       │  │  │  │ 10.0.128.0/19  │ │ │Subnet 3  │ │ │ │
│  │  │  │                     │  │  │  │                 │ │ │10.0.160/19│ │ │
│  │  │  │ EC2 Private         │  │  │  │                 │ │ │          │ │ │ │
│  │  │  │ ASG Private         │  │  │  │                 │ │ │          │ │ │ │
│  │  │  │ EKS Private Node    │  │  │  │                 │ │ │          │ │ │ │
│  │  │  │ EKS Control Plane   │  │  │  │                 │ │ │          │ │ │ │
│  │  │  └─────────────────────┘  │  │  │ └─────────────────┘ │ └──────────┘ │ │ │
│  │  └───────────────────────────┴──┴──────────────────────┴──────────────┘ │ │
│  └───────────────────────────────────────────────────────────────────────────┘ │
│                                                                               │
└─────────────────────────────────────────────────────────────────────────────┘
```

## Data Flow Diagrams

### Internet to Public Resources

```
Internet
   │
   │ HTTP/HTTPS (80/443)
   │ SSH (22)
   │
   ▼
┌─────────────────┐
│ Internet Gateway│
└─────────────────┘
   │
   │
   ▼
┌─────────────────────────────────────┐
│ Public Subnet Route Table           │
│ Route: 0.0.0.0/0 → IGW              │
└─────────────────────────────────────┘
   │
   ├─────────────────┬─────────────────┐
   ▼                 ▼                 ▼
┌──────────┐    ┌──────────┐    ┌──────────┐
│ EC2      │    │ ASG      │    │ EKS      │
│ Public   │    │ Public   │    │ Public   │
│ Instance │    │ Instances│    │ Node     │
└──────────┘    └──────────┘    └──────────┘
```

### Private Resources Outbound Traffic

```
Private Subnet Resources
   │
   │ Outbound Traffic
   │
   ▼
┌─────────────────────────────────────┐
│ Private Subnet Route Tables         │
│ Route: 0.0.0.0/0 → NAT Gateway      │
│ (All private subnets share same NAT)│
└─────────────────────────────────────┘
   │
   │ (Routes to AZ-1)
   ▼
┌─────────────────┐
│ NAT Gateway     │
│ (in Public Sub 1│
│  Shared by all) │
└─────────────────┘
   │
   │
   ▼
┌─────────────────┐
│ Internet Gateway│
└─────────────────┘
   │
   │
   ▼
Internet
```

### Inter-Subnet Communication

```
┌─────────────────────────────────────────────────────────────┐
│                    VPC (10.0.0.0/16)                         │
│                                                              │
│  ┌──────────────┐         ┌──────────────┐                 │
│  │ Public       │◄────────┤ Private      │                 │
│  │ Subnet       │  VPC    │ Subnet       │                 │
│  │              │  Local  │              │                 │
│  │ EC2 Public   │  Route  │ EC2 Private  │                 │
│  │ ASG Public   │         │ ASG Private  │                 │
│  │ EKS Public   │         │ EKS Private   │                 │
│  │              │         │ EKS Control  │                 │
│  └──────────────┘         └──────────────┘                 │
│         │                          │                        │
│         └──────────┬───────────────┘                        │
│                    │                                        │
│                    ▼                                        │
│         All traffic within VPC CIDR                         │
│         (controlled by Security Groups)                     │
└─────────────────────────────────────────────────────────────┘
```

## Security Architecture

### Security Group Relationships

```
┌─────────────────────────────────────────────────────────────┐
│                    Security Group Matrix                     │
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │ Public Instances │      │ Private         │            │
│  │ Security Group   │      │ Instances SG    │            │
│  │                  │      │                  │            │
│  │ Ingress:         │      │ Ingress:         │            │
│  │ - SSH (22)       │─────►│ - SSH from       │            │
│  │   from CIDR      │      │   Public SG     │            │
│  │ - HTTP (80)      │      │ - All from VPC  │            │
│  │   from 0.0.0.0/0 │      │   CIDR          │            │
│  │ - HTTPS (443)    │      │                  │            │
│  │   from 0.0.0.0/0 │      │ Egress:         │            │
│  │                  │      │ - All traffic   │            │
│  │ Egress:          │      │                  │            │
│  │ - All traffic    │      └──────────────────┘            │
│  └──────────────────┘                                       │
│                                                              │
│  ┌──────────────────┐      ┌──────────────────┐            │
│  │ EKS Cluster      │      │ EKS Node Group   │            │
│  │ Security Group   │◄─────┤ Security Group   │            │
│  │                  │      │                  │            │
│  │ Ingress:         │      │ Ingress:         │            │
│  │ - Port 443       │      │ - Ports 1025-    │            │
│  │   from Node SGs  │      │   65535 from     │            │
│  │                  │      │   Cluster SG    │            │
│  │ Egress:          │      │ - All from self  │            │
│  │ - All traffic    │      │                  │            │
│  └──────────────────┘      │ Egress:          │            │
│                            │ - All traffic    │            │
│                            └──────────────────┘            │
└─────────────────────────────────────────────────────────────┘
```

## Auto Scaling Architecture

### ASG Scaling Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    Auto Scaling Flow                        │
│                                                              │
│  ┌──────────────┐                                           │
│  │ EC2 Instances│                                           │
│  │ (ASG)        │                                           │
│  └──────┬───────┘                                           │
│         │                                                    │
│         │ CPU Metrics                                       │
│         ▼                                                    │
│  ┌──────────────────┐                                       │
│  │ CloudWatch      │                                       │
│  │ Metrics         │                                       │
│  └──────┬──────────┘                                       │
│         │                                                    │
│         │ Evaluation                                        │
│         ▼                                                    │
│  ┌──────────────────┐      ┌──────────────────┐           │
│  │ CPU High Alarm   │      │ CPU Low Alarm    │           │
│  │ (> 60% for 10min)│      │ (< 60% for 10min)│           │
│  └──────┬───────────┘      └──────┬───────────┘           │
│         │                          │                        │
│         │                          │                        │
│         ▼                          ▼                        │
│  ┌──────────────────┐      ┌──────────────────┐           │
│  │ Scale Up Policy  │      │ Scale Down Policy│           │
│  │ (+1 instance)    │      │ (-1 instance)    │           │
│  └──────┬───────────┘      └──────┬───────────┘           │
│         │                          │                        │
│         └──────────┬───────────────┘                        │
│                    │                                        │
│                    ▼                                        │
│         ┌──────────────────┐                               │
│         │ Auto Scaling     │                               │
│         │ Group            │                               │
│         │                  │                               │
│         │ Adjusts capacity │                               │
│         └──────────────────┘                               │
│                    │                                        │
│                    ▼                                        │
│         ┌──────────────────┐                               │
│         │ Launch Template  │                               │
│         │ Creates new      │                               │
│         │ instances        │                               │
│         └──────────────────┘                               │
└─────────────────────────────────────────────────────────────┘
```

## EKS Architecture

### EKS Cluster Components

```
┌─────────────────────────────────────────────────────────────┐
│                    EKS Cluster Architecture                  │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │           EKS Control Plane (AWS Managed)            │  │
│  │                                                       │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐          │  │
│  │  │ API      │  │ etcd     │  │ Scheduler │          │  │
│  │  │ Server   │  │          │  │          │          │  │
│  │  └──────────┘  └──────────┘  └──────────┘          │  │
│  │                                                       │  │
│  │  Multi-AZ, High Availability                         │  │
│  └──────────────────────────────────────────────────────┘  │
│                    │                                        │
│                    │ Kubernetes API                         │
│                    │                                        │
│  ┌─────────────────┼─────────────────────────────────┐  │
│  │                 │                                   │  │
│  │  ┌──────────────▼──────────────┐                  │  │
│  │  │ Private Node Group           │                  │  │
│  │  │ (Private Subnet)             │                  │  │
│  │  │                              │                  │  │
│  │  │ ┌──────────────────────────┐ │                  │  │
│  │  │ │ Worker Node (t3.small)  │ │                  │  │
│  │  │ │                         │ │                  │  │
│  │  │ │ - kubelet               │ │                  │  │
│  │  │ │ - kube-proxy            │ │                  │  │
│  │  │ │ - CNI Plugin            │ │                  │  │
│  │  │ │ - Container Runtime     │ │                  │  │
│  │  │ └──────────────────────────┘ │                  │  │
│  │  └──────────────────────────────┘                  │  │
│  │                                                    │  │
│  │  ┌──────────────────────────────┐                  │  │
│  │  │ Public Node Group            │                  │  │
│  │  │ (Public Subnet)              │                  │  │
│  │  │                              │                  │  │
│  │  │ ┌──────────────────────────┐ │                  │  │
│  │  │ │ Worker Node (t3.small)  │ │                  │  │
│  │  │ │                         │ │                  │  │
│  │  │ │ - kubelet               │ │                  │  │
│  │  │ │ - kube-proxy            │ │                  │  │
│  │  │ │ - CNI Plugin            │ │                  │  │
│  │  │ │ - Container Runtime     │ │                  │  │
│  │  │ └──────────────────────────┘ │                  │  │
│  │  └──────────────────────────────┘                  │  │
│  │                                                    │  │
│  └────────────────────────────────────────────────────┘  │
│                                                           │
│  ┌──────────────────────────────────────────────────────┐ │
│  │ IAM Roles                                             │ │
│  │                                                       │ │
│  │ ┌──────────────────┐  ┌──────────────────┐          │ │
│  │ │ Cluster Role     │  │ Node Group Role  │          │ │
│  │ │                  │  │                  │          │ │
│  │ │ EKS Cluster      │  │ EKS Worker Node  │          │ │
│  │ │ Policy           │  │ Policy           │          │ │
│  │ │                  │  │ EKS CNI Policy   │          │ │
│  │ │                  │  │ ECR ReadOnly     │          │ │
│  │ └──────────────────┘  └──────────────────┘          │ │
│  └──────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

## Deployment Architecture

### Terraform Module Dependencies

```
┌─────────────────────────────────────────────────────────────┐
│                    Module Dependency Graph                   │
│                                                              │
│  ┌──────────────┐                                           │
│  │   VPC        │                                           │
│  │   Module     │                                           │
│  └──────┬───────┘                                           │
│         │                                                    │
│         │ Provides:                                        │
│         │ - vpc_id                                          │
│         │ - subnet_ids                                      │
│         │ - cidr_block                                      │
│         │                                                    │
│         ├──────────────┬──────────────┬──────────────┐     │
│         │              │              │              │     │
│         ▼              ▼              ▼              ▼     │
│  ┌──────────┐  ┌──────────┐  ┌──────────┐  ┌──────────┐  │
│  │   EC2    │  │   ASG    │  │   EKS    │  │ (Future) │  │
│  │  Module  │  │  Module  │  │  Module  │  │ Modules  │  │
│  └──────────┘  └──────────┘  └──────────┘  └──────────┘  │
│         │              │              │                     │
│         │              │              │                     │
│         └──────────────┴──────────────┘                     │
│                    │                                        │
│                    │ Share Security Groups                  │
│                    │ (ASG uses EC2 SGs)                     │
│                    ▼                                        │
│         ┌──────────────────────┐                            │
│         │  Root Module        │                            │
│         │  (main.tf)          │                            │
│         │                     │                            │
│         │ Orchestrates all    │                            │
│         │ modules             │                            │
│         └──────────────────────┘                            │
└─────────────────────────────────────────────────────────────┘
```

## High Availability Design

### Multi-AZ Deployment

```
┌─────────────────────────────────────────────────────────────┐
│              High Availability Architecture                  │
│                                                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Availability │  │ Availability │  │ Availability │     │
│  │ Zone 1       │  │ Zone 2       │  │ Zone 3       │     │
│  │              │  │              │  │              │     │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │     │
│  │ │ Public   │ │  │ │ Public   │ │  │ │ Public   │ │     │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │     │
│  │ │          │ │  │ │          │ │  │ │          │ │     │
│  │ │ NAT GW   │ │  │ │ NAT GW   │ │  │ │ NAT GW   │ │     │
│  │ │          │ │  │ │          │ │  │ │          │ │     │
│  │ │ Resources│ │  │ │ Resources│ │  │ │ Resources│ │     │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │     │
│  │              │  │              │  │              │     │
│  │ ┌──────────┐ │  │ ┌──────────┐ │  │ ┌──────────┐ │     │
│  │ │ Private  │ │  │ │ Private  │ │  │ │ Private  │ │     │
│  │ │ Subnet   │ │  │ │ Subnet   │ │  │ │ Subnet   │ │     │
│  │ │          │ │  │ │          │ │  │ │          │ │     │
│  │ │ Resources│ │  │ │ Resources│ │  │ │ Resources│ │     │
│  │ │          │ │  │ │          │ │  │ │          │ │     │
│  │ │ EKS      │ │  │ │          │ │  │ │          │ │     │
│  │ │ Control  │ │  │ │          │ │  │ │          │ │     │
│  │ │ Plane    │ │  │ │          │ │  │ │          │ │     │
│  │ │ (Multi-AZ)│ │  │ │          │ │  │ │          │ │     │
│  │ └──────────┘ │  │ └──────────┘ │  │ └──────────┘ │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│                                                              │
│  Benefits:                                                   │
│  - Fault tolerance across AZs                                │
│  - No single point of failure                                │
│  - Automatic failover                                        │
│  - Load distribution                                         │
└─────────────────────────────────────────────────────────────┘
```

## Cost Optimization Architecture

### Resource Distribution for Cost Efficiency

```
┌─────────────────────────────────────────────────────────────┐
│              Cost-Optimized Architecture                     │
│                                                              │
│  Development Environment:                                    │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ - Single NAT Gateway (cost-optimized)                │  │
│  │ - Smaller instance types (t3.micro)                 │  │
│  │ - Reduced ASG limits (min=1, max=2)                 │  │
│  │ - EKS disabled or minimal nodes                     │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                              │
│  Production Environment:                                     │
│  ┌──────────────────────────────────────────────────────┐  │
│  │ - Single NAT Gateway (can be scaled if needed)     │  │
│  │ - Appropriate instance types                         │  │
│  │ - Full ASG scaling (min=2, max=10)                   │  │
│  │ - EKS with auto-scaling                               │  │
│  │ - Reserved Instances / Savings Plans                 │  │
│  │ - Consider multiple NAT Gateways for HA (manual)     │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

---

## Diagram Legend

- **Solid Lines**: Direct connections/routes
- **Dashed Lines**: Logical relationships
- **Arrows**: Data flow direction
- **Boxes**: Components/resources
- **Shaded Areas**: Logical groupings (VPC, AZs, etc.)

---

**Note**: These diagrams are conceptual representations. Actual AWS resource placement and routing may vary based on configuration.

