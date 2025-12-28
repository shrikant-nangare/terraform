#!/bin/bash

# Script to fix key pair error
# Options:
# 1. Set key_pair_name to empty (optional - instances won't have SSH access)
# 2. Find existing key pairs and use the first one
# 3. Create a new key pair

set -e

echo "=========================================="
echo "EC2 Key Pair Fix Script"
echo "=========================================="
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Check if terraform.tfvars exists
if [ ! -f "terraform.tfvars" ]; then
    echo -e "${RED}Error: terraform.tfvars not found${NC}"
    echo "Please run fix-eks-iam-simple.sh first or create terraform.tfvars manually"
    exit 1
fi

echo "Step 1: Checking for existing key pairs..."
echo ""

# Try to list key pairs
if command -v aws &> /dev/null && aws sts get-caller-identity &> /dev/null; then
    KEY_PAIRS=$(aws ec2 describe-key-pairs --query 'KeyPairs[*].KeyName' --output text 2>/dev/null || echo "")
    
    if [ -n "$KEY_PAIRS" ] && [ "$KEY_PAIRS" != "None" ]; then
        FIRST_KEY=$(echo $KEY_PAIRS | awk '{print $1}')
        echo -e "${GREEN}Found existing key pairs:${NC}"
        echo "$KEY_PAIRS" | tr ' ' '\n' | nl
        echo ""
        echo "Using first key pair: $FIRST_KEY"
        
        # Update terraform.tfvars
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' "s|key_pair_name = .*|key_pair_name = \"$FIRST_KEY\"|" terraform.tfvars
        else
            sed -i "s|key_pair_name = .*|key_pair_name = \"$FIRST_KEY\"|" terraform.tfvars
        fi
        
        echo -e "${GREEN}Updated terraform.tfvars with key pair: $FIRST_KEY${NC}"
    else
        echo -e "${YELLOW}No existing key pairs found${NC}"
        echo ""
        echo "Option 1: Make key pair optional (instances won't have SSH access)"
        echo "Option 2: Create a new key pair"
        echo ""
        read -p "Choose option (1 or 2, default: 1): " choice
        choice=${choice:-1}
        
        if [ "$choice" == "1" ]; then
            # Set to empty
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
            else
                sed -i 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
            fi
            echo -e "${GREEN}Set key_pair_name to empty (optional)${NC}"
            echo -e "${YELLOW}Note: You won't be able to SSH into instances without a key pair${NC}"
        else
            # Create new key pair
            KEY_NAME="${PROJECT_NAME:-my-project}-keypair"
            echo "Creating new key pair: $KEY_NAME"
            
            if aws ec2 create-key-pair --key-name "$KEY_NAME" --query 'KeyMaterial' --output text > "${KEY_NAME}.pem" 2>/dev/null; then
                chmod 400 "${KEY_NAME}.pem"
                echo -e "${GREEN}Created key pair: $KEY_NAME${NC}"
                echo "Private key saved to: ${KEY_NAME}.pem"
                echo -e "${YELLOW}IMPORTANT: Save this file securely! You won't be able to retrieve it again.${NC}"
                
                # Update terraform.tfvars
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' "s|key_pair_name = .*|key_pair_name = \"$KEY_NAME\"|" terraform.tfvars
                else
                    sed -i "s|key_pair_name = .*|key_pair_name = \"$KEY_NAME\"|" terraform.tfvars
                fi
            else
                echo -e "${RED}Failed to create key pair. Setting to empty instead.${NC}"
                if [[ "$OSTYPE" == "darwin"* ]]; then
                    sed -i '' 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
                else
                    sed -i 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
                fi
            fi
        fi
    fi
else
    echo -e "${YELLOW}AWS CLI not available or not configured${NC}"
    echo "Setting key_pair_name to empty (optional)"
    echo ""
    echo "You can manually update terraform.tfvars later with a valid key pair name"
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
    else
        sed -i 's|key_pair_name = .*|key_pair_name = ""|' terraform.tfvars
    fi
    echo -e "${GREEN}Set key_pair_name to empty${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}Key pair configuration updated!${NC}"
echo "=========================================="
echo ""
echo "Next step: Run terraform apply"
echo ""

