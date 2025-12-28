#!/bin/bash

# Script to fix eks:CreateNodegroup permission error
# This grants the Terraform execution user the necessary EKS permissions

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Get current AWS identity
print_info "Checking current AWS identity..."
CURRENT_IDENTITY=$(aws sts get-caller-identity --output json)
USER_ARN=$(echo "$CURRENT_IDENTITY" | jq -r '.Arn')
ACCOUNT_ID=$(echo "$CURRENT_IDENTITY" | jq -r '.Account')

print_info "Current identity: $USER_ARN"
print_info "Account ID: $ACCOUNT_ID"

# Extract username from ARN
if [[ "$USER_ARN" == *":user/"* ]]; then
    USER_NAME=$(echo "$USER_ARN" | sed 's/.*:user\///')
    IDENTITY_TYPE="user"
elif [[ "$USER_ARN" == *":assumed-role/"* ]]; then
    ROLE_NAME=$(echo "$USER_ARN" | sed 's/.*:assumed-role\///' | sed 's/\/.*//')
    IDENTITY_TYPE="role"
    print_warn "You're using an assumed role. You'll need to attach the policy to the role: $ROLE_NAME"
    print_warn "Or ask your administrator to grant these permissions to the role."
    exit 1
else
    print_error "Could not determine identity type from ARN: $USER_ARN"
    exit 1
fi

print_info "Identity type: $IDENTITY_TYPE"
print_info "Name: $USER_NAME"

# Check if AmazonEKSFullAccess is already attached
print_info "Checking current policies..."
if aws iam list-attached-user-policies --user-name "$USER_NAME" --query "AttachedPolicies[?PolicyArn=='arn:aws:iam::aws:policy/AmazonEKSFullAccess']" --output text | grep -q "AmazonEKSFullAccess"; then
    print_warn "AmazonEKSFullAccess policy is already attached to user $USER_NAME"
    print_info "If you're still getting permission errors, wait 1-2 minutes for IAM propagation."
    exit 0
fi

# Attach AmazonEKSFullAccess policy
print_info "Attaching AmazonEKSFullAccess policy to user: $USER_NAME"
if aws iam attach-user-policy \
    --user-name "$USER_NAME" \
    --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess; then
    print_info "Successfully attached AmazonEKSFullAccess policy!"
else
    print_error "Failed to attach policy. You may need administrator privileges."
    exit 1
fi

# Also check and attach other commonly needed policies
print_info "Checking for other required policies..."

# EC2 Full Access (for VPC, subnets, security groups)
if ! aws iam list-attached-user-policies --user-name "$USER_NAME" --query "AttachedPolicies[?PolicyArn=='arn:aws:iam::aws:policy/AmazonEC2FullAccess']" --output text | grep -q "AmazonEC2FullAccess"; then
    print_info "Attaching AmazonEC2FullAccess policy..."
    aws iam attach-user-policy \
        --user-name "$USER_NAME" \
        --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess || print_warn "Could not attach EC2 policy (may already exist or insufficient permissions)"
fi

# IAM Full Access (for creating/managing roles)
if ! aws iam list-attached-user-policies --user-name "$USER_NAME" --query "AttachedPolicies[?PolicyArn=='arn:aws:iam::aws:policy/IAMFullAccess']" --output text | grep -q "IAMFullAccess"; then
    print_info "Attaching IAMFullAccess policy..."
    aws iam attach-user-policy \
        --user-name "$USER_NAME" \
        --policy-arn arn:aws:iam::aws:policy/IAMFullAccess || print_warn "Could not attach IAM policy (may already exist or insufficient permissions)"
fi

print_info "========================================="
print_info "Summary"
print_info "========================================="
print_info "Attached policies to user: $USER_NAME"
print_info ""
print_info "Attached policies:"
aws iam list-attached-user-policies --user-name "$USER_NAME" --output table

print_info ""
print_warn "IMPORTANT: Wait 1-2 minutes for IAM permissions to propagate before running terraform apply again."
print_info ""
print_info "After waiting, you can retry:"
print_info "  terraform apply"
print_info ""
print_info "Or if you were using -target, continue with:"
print_info "  terraform apply -target=module.eks[0].aws_eks_node_group.private -target=module.eks[0].aws_eks_node_group.public[0]"

