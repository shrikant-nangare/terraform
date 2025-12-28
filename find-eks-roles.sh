#!/bin/bash

# Quick script to find EKS IAM roles

echo "=========================================="
echo "Finding EKS IAM Roles"
echo "=========================================="
echo ""

if ! command -v aws &> /dev/null; then
    echo "Error: AWS CLI not found"
    exit 1
fi

if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: AWS credentials not configured"
    echo "Run: aws configure"
    exit 1
fi

echo "Searching for EKS-related IAM roles..."
echo ""

# List all roles with 'eks' in the name
echo "All roles containing 'eks' or 'EKS':"
aws iam list-roles --query 'Roles[?contains(RoleName, `eks`) || contains(RoleName, `EKS`)].{RoleName:RoleName, Arn:Arn}' --output table

echo ""
echo "Checking common EKS role names..."
echo ""

# Check common cluster role names
CLUSTER_ROLES=("eksClusterRole" "EKS-Cluster-Role" "AmazonEKSClusterRole" "eks-cluster-role")
echo "Cluster Roles:"
for role in "${CLUSTER_ROLES[@]}"; do
    arn=$(aws iam get-role --role-name "$role" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$arn" ] && [ "$arn" != "None" ]; then
        echo "  ✓ $role: $arn"
    else
        echo "  ✗ $role: Not found"
    fi
done

echo ""
echo "Node Group Roles:"
NODE_ROLES=("AmazonEKSNodeRole" "EKS-Node-Role" "eksNodeRole" "eks-node-role")
for role in "${NODE_ROLES[@]}"; do
    arn=$(aws iam get-role --role-name "$role" --query 'Role.Arn' --output text 2>/dev/null || echo "")
    if [ -n "$arn" ] && [ "$arn" != "None" ]; then
        echo "  ✓ $role: $arn"
    else
        echo "  ✗ $role: Not found"
    fi
done

echo ""
echo "=========================================="
echo "Copy the ARNs above and update terraform.tfvars"
echo "=========================================="

