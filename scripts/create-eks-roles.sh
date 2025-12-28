#!/bin/bash

# Script to create EKS IAM roles if they don't exist
# This requires iam:CreateRole and iam:AttachRolePolicy permissions

set -e

echo "=========================================="
echo "Create EKS IAM Roles Script"
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

# Get project name from terraform.tfvars or use default
PROJECT_NAME=$(grep -E "^project_name\s*=" terraform.tfvars 2>/dev/null | sed 's/.*=\s*"\(.*\)".*/\1/' || echo "my-project")
CLUSTER_ROLE_NAME="${PROJECT_NAME}-eks-cluster-role"
NODE_ROLE_NAME="${PROJECT_NAME}-eks-node-group-role"

echo "Project name: $PROJECT_NAME"
echo "Cluster role name: $CLUSTER_ROLE_NAME"
echo "Node group role name: $NODE_ROLE_NAME"
echo ""

# Check if roles already exist
if aws iam get-role --role-name "$CLUSTER_ROLE_NAME" &>/dev/null; then
    CLUSTER_ROLE_ARN=$(aws iam get-role --role-name "$CLUSTER_ROLE_NAME" --query 'Role.Arn' --output text)
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

    # Create the role
    if aws iam create-role \
        --role-name "$CLUSTER_ROLE_NAME" \
        --assume-role-policy-document file:///tmp/cluster-trust-policy.json \
        --description "EKS Cluster Role for $PROJECT_NAME" &>/dev/null; then
        
        CLUSTER_ROLE_ARN=$(aws iam get-role --role-name "$CLUSTER_ROLE_NAME" --query 'Role.Arn' --output text)
        echo -e "${GREEN}Created cluster role: $CLUSTER_ROLE_ARN${NC}"
        
        # Attach policy
        aws iam attach-role-policy \
            --role-name "$CLUSTER_ROLE_NAME" \
            --policy-arn arn:aws:iam::aws:policy/AmazonEKSClusterPolicy
        
        echo -e "${GREEN}Attached AmazonEKSClusterPolicy${NC}"
    else
        echo -e "${RED}Failed to create cluster role. You may not have iam:CreateRole permission.${NC}"
        echo "Please ask your AWS administrator to create the role or provide an existing role ARN."
        exit 1
    fi
fi

echo ""

# Check if node role exists
if aws iam get-role --role-name "$NODE_ROLE_NAME" &>/dev/null; then
    NODE_ROLE_ARN=$(aws iam get-role --role-name "$NODE_ROLE_NAME" --query 'Role.Arn' --output text)
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

    # Create the role
    if aws iam create-role \
        --role-name "$NODE_ROLE_NAME" \
        --assume-role-policy-document file:///tmp/node-trust-policy.json \
        --description "EKS Node Group Role for $PROJECT_NAME" &>/dev/null; then
        
        NODE_ROLE_ARN=$(aws iam get-role --role-name "$NODE_ROLE_NAME" --query 'Role.Arn' --output text)
        echo -e "${GREEN}Created node group role: $NODE_ROLE_ARN${NC}"
        
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
        echo -e "${RED}Failed to create node group role. You may not have iam:CreateRole permission.${NC}"
        echo "Please ask your AWS administrator to create the role or provide an existing role ARN."
        exit 1
    fi
fi

# Clean up temp files
rm -f /tmp/cluster-trust-policy.json /tmp/node-trust-policy.json

echo ""
echo "=========================================="
echo -e "${GREEN}Roles ready!${NC}"
echo "=========================================="
echo ""
echo "Updating terraform.tfvars with role ARNs..."
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
echo -e "${YELLOW}Note: If you get 'iam:PassRole' error, you need permission to pass these roles to EKS.${NC}"
echo "Ask your AWS administrator to grant you iam:PassRole permission for these roles."
echo ""

