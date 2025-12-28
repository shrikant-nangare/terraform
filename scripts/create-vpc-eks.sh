#!/bin/bash

# Script to create VPC and launch EKS cluster
# This script handles dependencies and creates resources in the correct order

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if terraform is installed
if ! command -v terraform &> /dev/null; then
    print_error "Terraform is not installed. Please install Terraform first."
    exit 1
fi

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    print_warn "AWS CLI is not installed. Some verification steps may fail."
fi

# Find terraform root directory (where main.tf is located)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TERRAFORM_DIR="$SCRIPT_DIR/.."

# Check if main.tf exists in parent directory
if [ -f "$TERRAFORM_DIR/main.tf" ]; then
    cd "$TERRAFORM_DIR" || exit 1
    print_info "Changed to terraform directory: $(pwd)"
elif [ -f "main.tf" ]; then
    # Already in terraform directory
    TERRAFORM_DIR="$(pwd)"
    print_info "Running from terraform directory: $(pwd)"
else
    print_error "main.tf not found. Please run this script from the terraform directory or scripts directory."
    exit 1
fi

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    print_error "terraform.tfvars not found. Please create it from terraform.tfvars.example"
    exit 1
fi

# Check if eks_cluster_name is set
EKS_CLUSTER_NAME=$(grep -E "^eks_cluster_name\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
if [ -z "$EKS_CLUSTER_NAME" ] || [ "$EKS_CLUSTER_NAME" == "" ]; then
    print_error "eks_cluster_name is not set or is empty in terraform.tfvars"
    print_info "Please set eks_cluster_name in terraform.tfvars to enable EKS"
    exit 1
fi

print_info "EKS cluster name: $EKS_CLUSTER_NAME"

# Check if use_eks_permitted_roles is set
USE_PERMITTED_ROLES=$(grep -E "^use_eks_permitted_roles\s*=" terraform.tfvars | sed 's/.*=\s*\(.*\)/\1/' | tr -d ' ')
if [ -z "$USE_PERMITTED_ROLES" ]; then
    USE_PERMITTED_ROLES="false"
fi

print_info "Use permitted roles: $USE_PERMITTED_ROLES"

# Initialize Terraform if needed
if [ ! -d ".terraform" ]; then
    print_info "Initializing Terraform..."
    terraform init
else
    print_info "Terraform already initialized"
fi

# Step 1: Create VPC
print_info "========================================="
print_info "Step 1: Creating VPC and networking..."
print_info "========================================="

if terraform state list 2>/dev/null | grep -q "module.vpc"; then
    print_warn "VPC already exists in state. Skipping VPC creation."
    print_info "To recreate VPC, run: terraform destroy -target=module.vpc"
else
    print_info "Planning VPC resources..."
    terraform plan -target=module.vpc -out=tfplan-vpc
    
    print_info "Applying VPC configuration..."
    terraform apply tfplan-vpc
    rm -f tfplan-vpc
    
    print_info "VPC created successfully!"
fi

# Step 2: Create EKS IAM Roles (if using permitted roles)
if [ "$USE_PERMITTED_ROLES" == "true" ]; then
    print_info "========================================="
    print_info "Step 2: Creating EKS IAM Roles..."
    print_info "========================================="
    
    # Check if roles already exist
    if terraform state list 2>/dev/null | grep -q "aws_iam_role.eks_cluster\[0\]"; then
        print_warn "EKS IAM roles already exist in state. Skipping role creation."
    else
        print_info "Creating EKS cluster role..."
        terraform apply -target=aws_iam_role.eks_cluster[0] -auto-approve
        
        print_info "Creating EKS node group role..."
        terraform apply -target=aws_iam_role.eks_node_group[0] -auto-approve
        
        print_info "Attaching policies to cluster role..."
        terraform apply -target=aws_iam_role_policy_attachment.eks_cluster_policy[0] -auto-approve
        
        print_info "Attaching policies to node group role..."
        terraform apply \
            -target=aws_iam_role_policy_attachment.eks_node_worker_policy[0] \
            -target=aws_iam_role_policy_attachment.eks_node_cni_policy[0] \
            -target=aws_iam_role_policy_attachment.eks_node_registry_policy[0] \
            -auto-approve
        
        print_info "EKS IAM roles created successfully!"
    fi
else
    print_info "Using existing IAM roles (use_eks_permitted_roles = false)"
    print_info "Verifying role ARNs are set in terraform.tfvars..."
    
    CLUSTER_ROLE_ARN=$(grep -E "^eks_cluster_role_arn\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
    NODE_ROLE_ARN=$(grep -E "^eks_node_group_role_arn\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
    
    if [ -z "$CLUSTER_ROLE_ARN" ] || [ "$CLUSTER_ROLE_ARN" == "" ]; then
        print_error "eks_cluster_role_arn is not set in terraform.tfvars"
        exit 1
    fi
    
    if [ -z "$NODE_ROLE_ARN" ] || [ "$NODE_ROLE_ARN" == "" ]; then
        print_error "eks_node_group_role_arn is not set in terraform.tfvars"
        exit 1
    fi
    
    print_info "Cluster role ARN: $CLUSTER_ROLE_ARN"
    print_info "Node group role ARN: $NODE_ROLE_ARN"
fi

# Step 3: Create EKS Cluster
print_info "========================================="
print_info "Step 3: Creating EKS Cluster..."
print_info "========================================="

if terraform state list 2>/dev/null | grep -q "module.eks\[0\].aws_eks_cluster.main"; then
    print_warn "EKS cluster already exists in state."
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_info "Skipping EKS cluster creation."
        exit 0
    fi
fi

print_info "Planning EKS resources..."
terraform plan -target=module.eks[0] -out=tfplan-eks

print_info "Applying EKS configuration (this may take 10-15 minutes)..."
terraform apply tfplan-eks
rm -f tfplan-eks

print_info "EKS cluster created successfully!"

# Step 4: Verification
print_info "========================================="
print_info "Step 4: Verifying EKS Cluster..."
print_info "========================================="

if command -v aws &> /dev/null; then
    print_info "Checking cluster status..."
    if aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "${AWS_REGION:-us-east-1}" &>/dev/null; then
        CLUSTER_STATUS=$(aws eks describe-cluster --name "$EKS_CLUSTER_NAME" --region "${AWS_REGION:-us-east-1}" --query 'cluster.status' --output text 2>/dev/null || echo "UNKNOWN")
        print_info "Cluster status: $CLUSTER_STATUS"
        
        if [ "$CLUSTER_STATUS" == "ACTIVE" ]; then
            print_info "Cluster is ACTIVE!"
            
            # List node groups
            print_info "Listing node groups..."
            aws eks list-nodegroups --cluster-name "$EKS_CLUSTER_NAME" --region "${AWS_REGION:-us-east-1}" 2>/dev/null || print_warn "Could not list node groups"
        else
            print_warn "Cluster status is $CLUSTER_STATUS. It may still be provisioning."
        fi
    else
        print_warn "Could not verify cluster via AWS CLI. Please check manually."
    fi
else
    print_warn "AWS CLI not available. Skipping verification."
fi

# Summary
print_info "========================================="
print_info "Summary"
print_info "========================================="
print_info "VPC: Created/Exists"
print_info "EKS Cluster: Created"
print_info "Cluster Name: $EKS_CLUSTER_NAME"
print_info ""
print_info "Next steps:"
print_info "1. Configure kubectl: aws eks update-kubeconfig --region ${AWS_REGION:-us-east-1} --name $EKS_CLUSTER_NAME"
print_info "2. Verify nodes: kubectl get nodes"
print_info "3. Check cluster: kubectl cluster-info"
print_info ""
print_info "To view all resources: terraform state list"
print_info "To destroy EKS only: terraform destroy -target=module.eks[0]"
print_info "To destroy everything: terraform destroy"

