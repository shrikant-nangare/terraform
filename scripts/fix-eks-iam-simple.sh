#!/bin/bash

# Simple script to fix EKS IAM permission error
# This script will:
# 1. Clean up created IAM roles from Terraform state
# 2. Create terraform.tfvars with EKS disabled (quick fix)
#    OR prepare it for manual role ARN entry

set -e

echo "=========================================="
echo "EKS IAM Permission Fix Script (Simple)"
echo "=========================================="
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "Step 1: Cleaning up created IAM roles from Terraform state..."
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

REMOVED_COUNT=0
for resource in "${ROLES_TO_REMOVE[@]}"; do
    if terraform state list 2>/dev/null | grep -q "^${resource}$"; then
        echo "Removing $resource from state..."
        if terraform state rm "$resource" 2>/dev/null; then
            REMOVED_COUNT=$((REMOVED_COUNT + 1))
        fi
    fi
done

if [ $REMOVED_COUNT -eq 0 ]; then
    echo "No roles found in state to remove (they may have already been removed)"
else
    echo -e "${GREEN}Removed $REMOVED_COUNT resources from state${NC}"
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
        echo -e "${YELLOW}Warning: terraform.tfvars.example not found${NC}"
        echo "Creating basic terraform.tfvars..."
        cat > terraform.tfvars <<EOF
# Basic Terraform configuration
aws_region = "us-east-1"
project_name = "my-project"
vpc_cidr = "10.0.0.0/16"
enable_nat_gateway = true

# EKS Configuration
# Option 1: Disable EKS (quick fix)
eks_cluster_name = ""

# Option 2: Use existing roles (uncomment and fill in)
# eks_cluster_name = "myekscluster"
# eks_cluster_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-CLUSTER-ROLE"
# eks_node_group_role_arn = "arn:aws:iam::YOUR-ACCOUNT-ID:role/YOUR-NODE-ROLE"
EOF
    fi
fi

# Update terraform.tfvars to disable EKS by default
if grep -q "eks_cluster_name" terraform.tfvars; then
    # Update existing line to disable EKS
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS
        sed -i '' 's/eks_cluster_name = .*/eks_cluster_name = ""/' terraform.tfvars
    else
        # Linux
        sed -i 's/eks_cluster_name = .*/eks_cluster_name = ""/' terraform.tfvars
    fi
    echo -e "${GREEN}Updated terraform.tfvars to disable EKS${NC}"
else
    # Add EKS configuration
    echo "" >> terraform.tfvars
    echo "# EKS Configuration - Disabled by default" >> terraform.tfvars
    echo "eks_cluster_name = \"\"" >> terraform.tfvars
    echo -e "${GREEN}Added EKS configuration to terraform.tfvars (disabled)${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Cleanup complete!${NC}"
echo "=========================================="
echo ""
echo "What was done:"
echo "  ✓ Removed created IAM roles from Terraform state"
echo "  ✓ Updated terraform.tfvars to disable EKS"
echo ""
echo "Next steps:"
echo ""
echo "Option 1: Continue without EKS (recommended for now)"
echo "  Run: terraform apply"
echo ""
echo "Option 2: Enable EKS with existing roles"
echo "  1. Find existing EKS roles:"
echo "     aws iam list-roles --query 'Roles[?contains(RoleName, \`eks\`)].{Name:RoleName, Arn:Arn}' --output table"
echo ""
echo "  2. Edit terraform.tfvars and set:"
echo "     eks_cluster_name = \"myekscluster\""
echo "     eks_cluster_role_arn = \"<your-cluster-role-arn>\""
echo "     eks_node_group_role_arn = \"<your-node-role-arn>\""
echo ""
echo "  3. Run: terraform apply"
echo ""

