#!/bin/bash

# Quick fix script to attach all required AWS policies
# Run this script to fix permission errors

USER_NAME="kk_labs_user_461965"

echo "Attaching AWS managed policies to user: $USER_NAME"
echo ""

# Attach EC2 Full Access (covers VPC, NAT Gateway, etc.)
echo "Attaching AmazonEC2FullAccess..."
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEC2FullAccess

# Attach Auto Scaling Full Access
echo "Attaching AutoScalingFullAccess..."
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AutoScalingFullAccess

# Attach EKS Full Access
echo "Attaching AmazonEKSFullAccess..."
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn arn:aws:iam::aws:policy/AmazonEKSFullAccess

# Attach IAM Full Access (for creating roles)
echo "Attaching IAMFullAccess..."
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn arn:aws:iam::aws:policy/IAMFullAccess

# Attach CloudWatch Full Access (for ASG alarms)
echo "Attaching CloudWatchFullAccess..."
aws iam attach-user-policy \
  --user-name "$USER_NAME" \
  --policy-arn arn:aws:iam::aws:policy/CloudWatchFullAccess

echo ""
echo "========================================="
echo "All policies attached successfully!"
echo "========================================="
echo ""
echo "IMPORTANT: Wait 1-2 minutes for IAM permissions to propagate"
echo "before running 'terraform apply' again."
echo ""
echo "To verify policies are attached, run:"
echo "  aws iam list-attached-user-policies --user-name $USER_NAME"
echo ""

