#!/bin/bash

# Script to enable EKS cluster creation
# This script will:
# 1. Find existing EKS IAM roles
# 2. Update terraform.tfvars to enable EKS with those roles

set -e

echo "=========================================="
echo "Enable EKS Cluster Script"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    exit 1
fi

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

echo "Step 1: Finding existing EKS IAM roles..."
echo ""

# Find cluster role
CLUSTER_ROLE_ARN=""
NODE_ROLE_ARN=""

# Try common cluster role names
CLUSTER_ROLE_NAMES=("eksClusterRole" "EKS-Cluster-Role" "AmazonEKSClusterRole" "eks-cluster-role" "my-project-eks-cluster-role")
for role_name in "${CLUSTER_ROLE_NAMES[@]}"; do
    role_arn=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$role_arn" ] && [ "$role_arn" != "None" ]; then
        CLUSTER_ROLE_ARN="$role_arn"
        echo -e "${GREEN}Found cluster role: $role_name${NC}"
        echo "  ARN: $CLUSTER_ROLE_ARN"
        break
    fi
done

# Try common node role names
NODE_ROLE_NAMES=("AmazonEKSNodeRole" "EKS-Node-Role" "eksNodeRole" "eks-node-role" "my-project-eks-node-group-role")
for role_name in "${NODE_ROLE_NAMES[@]}"; do
    role_arn=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$role_arn" ] && [ "$role_arn" != "None" ]; then
        NODE_ROLE_ARN="$role_arn"
        echo -e "${GREEN}Found node role: $role_name${NC}"
        echo "  ARN: $NODE_ROLE_ARN"
        break
    fi
done

# If not found, list all EKS roles
if [ -z "$CLUSTER_ROLE_ARN" ] || [ -z "$NODE_ROLE_ARN" ]; then
    echo ""
    echo -e "${YELLOW}Common roles not found. Listing all roles with 'eks' in name:${NC}"
    aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table 2>/dev/null || echo "Could not list roles"
    echo ""
    
    if [ -z "$CLUSTER_ROLE_ARN" ]; then
        echo -e "${YELLOW}Please enter the cluster role ARN manually:${NC}"
        read -p "Cluster Role ARN: " CLUSTER_ROLE_ARN
    fi
    
    if [ -z "$NODE_ROLE_ARN" ]; then
        echo -e "${YELLOW}Please enter the node group role ARN manually:${NC}"
        read -p "Node Group Role ARN: " NODE_ROLE_ARN
    fi
fi

if [ -z "$CLUSTER_ROLE_ARN" ] || [ -z "$NODE_ROLE_ARN" ]; then
    echo -e "${RED}Error: Both cluster and node role ARNs are required${NC}"
    echo ""
    echo "You can find roles using:"
    echo "  aws iam list-roles --query 'Roles[?contains(RoleName, \`eks\`)].{Name:RoleName, Arn:Arn}' --output table"
    exit 1
fi

echo ""
echo "Step 2: Updating terraform.tfvars..."
echo ""

# Get cluster name (default or ask)
CLUSTER_NAME="myekscluster"
read -p "Enter EKS cluster name (default: myekscluster): " input
CLUSTER_NAME=${input:-$CLUSTER_NAME}

# Backup terraform.tfvars
cp terraform.tfvars terraform.tfvars.backup.$(date +%Y%m%d_%H%M%S)

# Update terraform.tfvars
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' "s|eks_cluster_name = .*|eks_cluster_name = \"$CLUSTER_NAME\"|" terraform.tfvars
    sed -i '' "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
    sed -i '' "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
else
    # Linux
    sed -i "s|eks_cluster_name = .*|eks_cluster_name = \"$CLUSTER_NAME\"|" terraform.tfvars
    sed -i "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
    sed -i "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
fi

echo -e "${GREEN}Updated terraform.tfvars:${NC}"
echo "  eks_cluster_name = \"$CLUSTER_NAME\""
echo "  eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\""
echo "  eks_node_group_role_arn = \"$NODE_ROLE_ARN\""
echo ""

echo "=========================================="
echo -e "${GREEN}EKS is now enabled!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review terraform.tfvars to verify the configuration"
echo "2. Run: terraform plan"
echo "3. If everything looks good, run: terraform apply"
echo ""
echo "Note: The EKS cluster creation may take 10-15 minutes"
echo ""

