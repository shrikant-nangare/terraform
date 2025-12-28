#!/bin/bash

# Script to check EKS role ARNs and verify they match the current AWS account

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "EKS Role ARN Verification"
echo "=========================================="
echo ""

# Get current AWS account ID
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI is not installed${NC}"
    exit 1
fi

CURRENT_ACCOUNT=$(aws sts get-caller-identity --query Account --output text 2>/dev/null)
if [ -z "$CURRENT_ACCOUNT" ]; then
    echo -e "${RED}Error: Could not get AWS account ID. Check your AWS credentials.${NC}"
    exit 1
fi

echo -e "${GREEN}Current AWS Account ID: $CURRENT_ACCOUNT${NC}"
echo ""

# Check terraform.tfvars
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    exit 1
fi

# Extract role ARNs from terraform.tfvars
CLUSTER_ROLE_ARN=$(grep -E "^eks_cluster_role_arn\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')
NODE_ROLE_ARN=$(grep -E "^eks_node_group_role_arn\s*=" terraform.tfvars | sed 's/.*=\s*"\(.*\)".*/\1/' | tr -d ' ')

# Extract account IDs from ARNs
CLUSTER_ACCOUNT=$(echo "$CLUSTER_ROLE_ARN" | cut -d: -f5)
NODE_ACCOUNT=$(echo "$NODE_ROLE_ARN" | cut -d: -f5)

echo "Configuration in terraform.tfvars:"
echo "  Cluster Role ARN: $CLUSTER_ROLE_ARN"
echo "  Node Role ARN: $NODE_ROLE_ARN"
echo ""

# Check if account IDs match
if [ "$CLUSTER_ACCOUNT" != "$CURRENT_ACCOUNT" ]; then
    echo -e "${RED}ERROR: Cluster role ARN account ($CLUSTER_ACCOUNT) does not match current account ($CURRENT_ACCOUNT)${NC}"
    echo ""
    echo "Solution: Update eks_cluster_role_arn in terraform.tfvars to use account $CURRENT_ACCOUNT"
    echo "  Example: arn:aws:iam::${CURRENT_ACCOUNT}:role/eksClusterRole"
    EXIT_CODE=1
else
    echo -e "${GREEN}✓ Cluster role ARN account matches current account${NC}"
    EXIT_CODE=0
fi

if [ "$NODE_ACCOUNT" != "$CURRENT_ACCOUNT" ]; then
    echo -e "${RED}ERROR: Node role ARN account ($NODE_ACCOUNT) does not match current account ($CURRENT_ACCOUNT)${NC}"
    echo ""
    echo "Solution: Update eks_node_group_role_arn in terraform.tfvars to use account $CURRENT_ACCOUNT"
    echo "  Example: arn:aws:iam::${CURRENT_ACCOUNT}:role/AmazonEKSNodeRole"
    EXIT_CODE=1
else
    echo -e "${GREEN}✓ Node role ARN account matches current account${NC}"
fi

echo ""
echo "=========================================="
if [ $EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}All role ARNs are correct!${NC}"
else
    echo -e "${RED}Role ARN account mismatch detected!${NC}"
    echo ""
    echo "Quick fix:"
    echo "  sed -i '' 's|660526765185|${CURRENT_ACCOUNT}|g' terraform.tfvars"
fi
echo "=========================================="

exit $EXIT_CODE

