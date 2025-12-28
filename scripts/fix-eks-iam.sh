#!/bin/bash

# Script to fix EKS IAM permission error by using existing IAM roles
# This script will:
# 1. Find existing EKS IAM roles in your AWS account
# 2. Create/update terraform.tfvars with the role ARNs
# 3. Clean up the created roles from Terraform state
# 4. Re-apply Terraform

set -e

echo "=========================================="
echo "EKS IAM Permission Fix Script"
echo "=========================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if AWS CLI is available
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed or not in PATH${NC}"
    echo "Please install AWS CLI or add it to your PATH"
    exit 1
fi

# Check AWS credentials
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    echo "Please run 'aws configure' to set up your credentials"
    exit 1
fi

echo "Step 1: Finding existing EKS IAM roles..."
echo ""

# Find cluster role
echo "Searching for EKS cluster roles..."
CLUSTER_ROLES=$(aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{Name:RoleName, Arn:Arn}' --output json 2>/dev/null || echo "[]")

# Try common role names
COMMON_CLUSTER_ROLES=("eksClusterRole" "EKS-Cluster-Role" "AmazonEKSClusterRole" "eks-cluster-role")
CLUSTER_ROLE_ARN=""

for role_name in "${COMMON_CLUSTER_ROLES[@]}"; do
    role_arn=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$role_arn" ] && [ "$role_arn" != "None" ]; then
        CLUSTER_ROLE_ARN="$role_arn"
        echo -e "${GREEN}Found cluster role: $role_name${NC}"
        echo "  ARN: $CLUSTER_ROLE_ARN"
        break
    fi
done

# Find node group role
echo ""
echo "Searching for EKS node group roles..."
COMMON_NODE_ROLES=("AmazonEKSNodeRole" "EKS-Node-Role" "eksNodeRole" "eks-node-role")
NODE_ROLE_ARN=""

for role_name in "${COMMON_NODE_ROLES[@]}"; do
    role_arn=$(aws iam get-role --role-name "$role_name" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$role_arn" ] && [ "$role_arn" != "None" ]; then
        NODE_ROLE_ARN="$role_arn"
        echo -e "${GREEN}Found node role: $role_name${NC}"
        echo "  ARN: $NODE_ROLE_ARN"
        break
    fi
done

# If roles not found, list all EKS-related roles
if [ -z "$CLUSTER_ROLE_ARN" ] || [ -z "$NODE_ROLE_ARN" ]; then
    echo ""
    echo -e "${YELLOW}Common roles not found. Listing all roles with 'eks' in name:${NC}"
    aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table 2>/dev/null || echo "Could not list roles"
    echo ""
    echo -e "${YELLOW}Please manually find the role ARNs and update terraform.tfvars${NC}"
    echo "Or ask your AWS administrator for the EKS role ARNs"
    exit 1
fi

echo ""
echo "Step 2: Creating/updating terraform.tfvars..."
echo ""

# Check if terraform.tfvars exists
if [ -f "terraform.tfvars" ]; then
    echo "terraform.tfvars already exists. Backing up to terraform.tfvars.backup"
    cp terraform.tfvars terraform.tfvars.backup
fi

# Create terraform.tfvars from example if it doesn't exist
if [ ! -f "terraform.tfvars" ]; then
    if [ -f "terraform.tfvars.example" ]; then
        cp terraform.tfvars.example terraform.tfvars
        echo "Created terraform.tfvars from terraform.tfvars.example"
    else
        echo -e "${RED}Error: terraform.tfvars.example not found${NC}"
        exit 1
    fi
fi

# Update terraform.tfvars with role ARNs
# Use sed to update or add the role ARN lines
if grep -q "eks_cluster_role_arn" terraform.tfvars; then
    # Update existing line
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
        sed -i '' "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
        sed -i '' "s|eks_cluster_name = .*|eks_cluster_name = \"myekscluster\"|" terraform.tfvars
    else
        # Linux
        sed -i "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
        sed -i "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
        sed -i "s|eks_cluster_name = .*|eks_cluster_name = \"myekscluster\"|" terraform.tfvars
    fi
else
    # Append if not found
    echo "" >> terraform.tfvars
    echo "# EKS IAM Roles (auto-configured by fix-eks-iam.sh)" >> terraform.tfvars
    echo "eks_cluster_name = \"myekscluster\"" >> terraform.tfvars
    echo "eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"" >> terraform.tfvars
    echo "eks_node_group_role_arn = \"$NODE_ROLE_ARN\"" >> terraform.tfvars
fi

echo -e "${GREEN}Updated terraform.tfvars with role ARNs${NC}"
echo ""

echo "Step 3: Cleaning up created IAM roles from Terraform state..."
echo ""

# Remove created roles from state
ROLES_TO_REMOVE=(
    "module.eks[0].aws_iam_role.cluster[0]"
    "module.eks[0].aws_iam_role.node_group[0]"
    "module.eks[0].aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy[0]"
    "module.eks[0].aws_iam_role_policy_attachment.node_group_AmazonEKSWorkerNodePolicy[0]"
    "module.eks[0].aws_iam_role_policy_attachment.node_group_AmazonEKS_CNI_Policy[0]"
    "module.eks[0].aws_iam_role_policy_attachment.node_group_AmazonEC2ContainerRegistryReadOnly[0]"
)

for resource in "${ROLES_TO_REMOVE[@]}"; do
    if terraform state list | grep -q "^${resource}$"; then
        echo "Removing $resource from state..."
        terraform state rm "$resource" 2>/dev/null || echo "  (already removed or doesn't exist)"
    fi
done

echo ""
echo -e "${GREEN}State cleanup complete${NC}"
echo ""

echo "Step 4: Running terraform plan to verify changes..."
echo ""
terraform plan

echo ""
echo "=========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Review the terraform plan above"
echo "2. If everything looks good, run: terraform apply"
echo ""
echo "The script has:"
echo "  ✓ Found existing EKS IAM roles"
echo "  ✓ Updated terraform.tfvars with role ARNs"
echo "  ✓ Cleaned up created roles from Terraform state"
echo ""
echo "Your terraform.tfvars now contains:"
echo "  eks_cluster_name = \"myekscluster\""
echo "  eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\""
echo "  eks_node_group_role_arn = \"$NODE_ROLE_ARN\""
echo ""

