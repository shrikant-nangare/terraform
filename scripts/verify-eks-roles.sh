#!/bin/bash

# Script to verify EKS roles exist in current AWS account

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "Verifying EKS Roles"
echo "=========================================="
echo ""

# Get current AWS account ID
CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$CURRENT_ACCOUNT" ]; then
    echo -e "${RED}Error: Could not get AWS account ID. Check your AWS credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}Current AWS Account ID: $CURRENT_ACCOUNT${NC}"
echo ""

# Check if roles exist
CLUSTER_ROLE_NAME="eksClusterRole"
NODE_ROLE_NAME="AmazonEKSNodeRole"

echo "Checking for role: $CLUSTER_ROLE_NAME"
if aws iam get-role --role-name "$CLUSTER_ROLE_NAME" &>/dev/null; then
    ROLE_ARN=$(aws iam get-role --role-name "$CLUSTER_ROLE_NAME" --query 'Role.Arn' --output text)
    echo -e "${GREEN}✓ Found: $ROLE_ARN${NC}"
    
    # Verify account ID matches
    ROLE_ACCOUNT=$(echo "$ROLE_ARN" | cut -d: -f5)
    if [ "$ROLE_ACCOUNT" == "$CURRENT_ACCOUNT" ]; then
        echo -e "${GREEN}  Account ID matches!${NC}"
    else
        echo -e "${RED}  WARNING: Role is in account $ROLE_ACCOUNT, but you're authenticated to $CURRENT_ACCOUNT${NC}"
    fi
else
    echo -e "${RED}✗ Role not found: $CLUSTER_ROLE_NAME${NC}"
    echo "  You may need to create this role or use a different role name"
fi

echo ""
echo "Checking for role: $NODE_ROLE_NAME"
if aws iam get-role --role-name "$NODE_ROLE_NAME" &>/dev/null; then
    ROLE_ARN=$(aws iam get-role --role-name "$NODE_ROLE_NAME" --query 'Role.Arn' --output text)
    echo -e "${GREEN}✓ Found: $ROLE_ARN${NC}"
    
    # Verify account ID matches
    ROLE_ACCOUNT=$(echo "$ROLE_ARN" | cut -d: -f5)
    if [ "$ROLE_ACCOUNT" == "$CURRENT_ACCOUNT" ]; then
        echo -e "${GREEN}  Account ID matches!${NC}"
    else
        echo -e "${RED}  WARNING: Role is in account $ROLE_ACCOUNT, but you're authenticated to $CURRENT_ACCOUNT${NC}"
    fi
else
    echo -e "${RED}✗ Role not found: $NODE_ROLE_NAME${NC}"
    echo "  You may need to create this role or use a different role name"
fi

echo ""
echo "=========================================="
echo "Summary"
echo "=========================================="
echo ""
echo "If roles don't exist, you have two options:"
echo ""
echo "Option 1: Let Terraform create the roles"
echo "  Set in terraform.tfvars:"
echo "    use_eks_permitted_roles = true"
echo "    eks_cluster_role_arn = \"\""
echo "    eks_node_group_role_arn = \"\""
echo ""
echo "Option 2: Create roles manually"
echo "  Run: ./scripts/create-permitted-eks-roles.sh"
echo ""

