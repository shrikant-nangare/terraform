#!/bin/bash

# Script to create EKS IAM roles with the permitted names:
# - eksClusterRole (cluster role)
# - AmazonEKSNodeRole (node group role)

set -e

echo "=========================================="
echo "Create Permitted EKS IAM Roles"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}Error: AWS CLI not found${NC}"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}Error: AWS credentials not configured${NC}"
    exit 1
fi

ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
CLUSTER_ROLE_NAME="eksClusterRole"
NODE_ROLE_NAME="AmazonEKSNodeRole"

CLUSTER_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${CLUSTER_ROLE_NAME}"
NODE_ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${NODE_ROLE_NAME}"

echo "Account ID: $ACCOUNT_ID"
echo "Cluster role: $CLUSTER_ROLE_NAME"
echo "Node role: $NODE_ROLE_NAME"
echo ""

# Create cluster role
if aws iam get-role --role-name "$CLUSTER_ROLE_NAME" &>/dev/null; then
    echo -e "${GREEN}Cluster role already exists: $CLUSTER_ROLE_ARN${NC}"
else
    echo "Creating cluster role: $CLUSTER_ROLE_NAME"
    
    # Create trust policy for cluster role
    cat > /tmp/cluster-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    if aws iam create-role \
        --role-name "$CLUSTER_ROLE_NAME" \
        --assume-role-policy-document file:///tmp/cluster-trust-policy.json \
        --description "EKS Cluster Service Role" &>/dev/null; then
        
        echo -e "${GREEN}Created cluster role${NC}"
        
        # Attach policy
        aws iam attach-role-policy \
            --role-name "$CLUSTER_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
        
        echo -e "${GREEN}Attached AmazonEKSClusterPolicy${NC}"
    else
        echo -e "${RED}Failed to create cluster role${NC}"
        echo "You may not have iam:CreateRole permission."
        echo "Please ask your AWS administrator to create the role."
        exit 1
    fi
fi

echo ""

# Create node role
if aws iam get-role --role-name "$NODE_ROLE_NAME" &>/dev/null; then
    echo -e "${GREEN}Node group role already exists: $NODE_ROLE_ARN${NC}"
else
    echo "Creating node group role: $NODE_ROLE_NAME"
    
    # Create trust policy for node role
    cat > /tmp/node-trust-policy.json <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

    if aws iam create-role \
        --role-name "$NODE_ROLE_NAME" \
        --assume-role-policy-document file:///tmp/node-trust-policy.json \
        --description "EKS Node Group Service Role" &>/dev/null; then
        
        echo -e "${GREEN}Created node group role${NC}"
        
        # Attach policies
        aws iam attach-role-policy \
            --role-name "$NODE_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy
        
        aws iam attach-role-policy \
            --role-name "$NODE_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy
        
        aws iam attach-role-policy \
            --role-name "$NODE_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly
        
        echo -e "${GREEN}Attached required node group policies${NC}"
    else
        echo -e "${RED}Failed to create node group role${NC}"
        echo "You may not have iam:CreateRole permission."
        echo "Please ask your AWS administrator to create the role."
        exit 1
    fi
fi

# Clean up temp files
rm -f /tmp/cluster-trust-policy.json /tmp/node-trust-policy.json

echo ""
echo "=========================================="
echo -e "${GREEN}Roles created successfully!${NC}"
echo "=========================================="
echo ""
echo "Updating terraform.tfvars..."
echo ""

# Update terraform.tfvars
if [ -f "terraform.tfvars" ]; then
    cp terraform.tfvars terraform.tfvars.backup.$(date +%Y%m%d_%H%M%S)
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
        sed -i '' "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
    else
        sed -i "s|eks_cluster_role_arn = .*|eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\"|" terraform.tfvars
        sed -i "s|eks_node_group_role_arn = .*|eks_node_group_role_arn = \"$NODE_ROLE_ARN\"|" terraform.tfvars
    fi
    
    echo -e "${GREEN}Updated terraform.tfvars:${NC}"
    echo "  eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\""
    echo "  eks_node_group_role_arn = \"$NODE_ROLE_ARN\""
else
    echo -e "${YELLOW}terraform.tfvars not found. Please manually add:${NC}"
    echo "  eks_cluster_role_arn = \"$CLUSTER_ROLE_ARN\""
    echo "  eks_node_group_role_arn = \"$NODE_ROLE_ARN\""
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Setup complete!${NC}"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Verify terraform.tfvars has the role ARNs"
echo "2. Run: terraform plan"
echo "3. Run: terraform apply"
echo ""
echo "Note: These are the permitted role names for your account."
echo ""

