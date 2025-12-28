#!/bin/bash

# Script to fix Terraform AWS permissions for user kk_labs_user_461965
# This script attaches the required AWS managed policies to the IAM user

set -e

USER_NAME="kk_labs_user_461965"

echo "========================================="
echo "Fixing Terraform AWS Permissions"
echo "========================================="
echo ""
echo "User: $USER_NAME"
echo ""

# Check if user exists
echo "Checking if user exists..."
if ! aws iam get-user --user-name "$USER_NAME" &>/dev/null; then
    echo "ERROR: User $USER_NAME not found!"
    echo "Please verify the user name or check your AWS credentials."
    exit 1
fi

echo "User found. Current attached policies:"
aws iam list-attached-user-policies --user-name "$USER_NAME" --query 'AttachedPolicies[*].PolicyName' --output table
echo ""

# Function to attach policy if not already attached
attach_policy() {
    local policy_arn=$1
    local policy_name=$2
    
    # Check if policy is already attached
    if aws iam list-attached-user-policies --user-name "$USER_NAME" \
        --query "AttachedPolicies[?PolicyArn=='$policy_arn'].PolicyArn" \
        --output text | grep -q "$policy_arn"; then
        echo "✓ $policy_name is already attached"
    else
        echo "Attaching $policy_name..."
        if aws iam attach-user-policy \
            --user-name "$USER_NAME" \
            --policy-arn "$policy_arn"; then
            echo "✓ Successfully attached $policy_name"
        else
            echo "✗ Failed to attach $policy_name"
            return 1
        fi
    fi
}

# Attach required policies
echo "Attaching required AWS managed policies..."
echo ""

attach_policy "arn:aws:iam::aws:policy/AmazonEC2FullAccess" "AmazonEC2FullAccess"
attach_policy "arn:aws:iam::aws:policy/AutoScalingFullAccess" "AutoScalingFullAccess"
attach_policy "arn:aws:iam::aws:policy/AmazonEKSFullAccess" "AmazonEKSFullAccess"
attach_policy "arn:aws:iam::aws:policy/IAMFullAccess" "IAMFullAccess"
attach_policy "arn:aws:iam::aws:policy/CloudWatchFullAccess" "CloudWatchFullAccess"

echo ""
echo "========================================="
echo "Policy Attachment Complete"
echo "========================================="
echo ""
echo "Updated attached policies:"
aws iam list-attached-user-policies --user-name "$USER_NAME" --query 'AttachedPolicies[*].PolicyName' --output table
echo ""
echo "NOTE: IAM permission changes can take 1-5 minutes to propagate."
echo "Please wait a few minutes before running 'terraform apply' again."
echo ""
echo "To verify permissions, you can test with:"
echo "  aws ec2 describe-vpcs"
echo "  aws autoscaling describe-auto-scaling-groups"
echo "  aws eks list-clusters"
echo ""

