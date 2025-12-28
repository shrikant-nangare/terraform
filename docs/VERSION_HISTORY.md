# Version History

This document tracks all changes made to the Terraform infrastructure codebase, organized by commit.

---

## Version 1.12 - 2025-12-28

### Commit: 224cf69
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 15:19:16 -0500  
**Message:** Enhance EKS module to support existing IAM roles for cluster and node group; add corresponding variables and update resource dependencies accordingly.

**Files Changed:**
- `main.tf` (20 lines modified)
- `modules/eks/main.tf` (67 lines modified)
- `modules/eks/outputs.tf` (4 lines modified)
- `modules/eks/variables.tf` (12 lines added)
- `terraform.tfvars.example` (6 lines added)
- `variables.tf` (13 lines added)

**Summary:** Added support for using existing IAM roles for EKS cluster and node groups. Introduced new variables to allow users to specify existing role ARNs instead of creating new ones, providing more flexibility in IAM management.

**Changes:**
- Added variables for existing cluster and node group IAM role ARNs
- Updated EKS module to conditionally use existing roles or create new ones
- Modified resource dependencies to handle both scenarios
- Updated outputs to reflect the new role configuration options
- Added example values in terraform.tfvars.example

---

## Version 1.11 - 2025-12-28

### Commit: a0bcdb8
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 15:15:57 -0500  
**Message:** Remove CloudWatch log group resource from EKS module to prevent permission issues; update comments to clarify automatic creation by EKS.

**Files Changed:**
- `modules/eks/main.tf` (26 lines modified: 4 insertions, 22 deletions)

**Summary:** Removed the CloudWatch log group resource from the EKS module as EKS automatically creates log groups. This prevents permission conflicts and simplifies the configuration.

**Changes:**
- Removed `aws_cloudwatch_log_group` resource
- Updated comments to clarify that EKS automatically creates log groups
- Simplified module configuration

---

## Version 1.10 - 2025-12-28

### Commit: 00f9d74
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 15:14:43 -0500  
**Message:** Add prevent_destroy lifecycle rule to CloudWatch log group in EKS module to avoid accidental deletion

**Files Changed:**
- `modules/eks/main.tf` (3 lines added)

**Summary:** Added a lifecycle rule to prevent accidental deletion of the CloudWatch log group, protecting important logging data.

**Changes:**
- Added `prevent_destroy = true` lifecycle block to CloudWatch log group resource

---

## Version 1.9 - 2025-12-28

### Commit: 2dd5f3b
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:34:10 -0500  
**Message:** Update EKS module to modify security group ingress rules and adjust CloudWatch log retention settings to avoid permission issues

**Files Changed:**
- `modules/eks/main.tf` (16 lines modified: 13 insertions, 7 deletions)
- `modules/eks/variables.tf` (4 lines modified: 4 insertions, 2 deletions)

**Summary:** Updated security group ingress rules for better node communication and adjusted CloudWatch log retention settings to resolve permission issues.

**Changes:**
- Modified security group ingress rules in EKS module
- Adjusted CloudWatch log retention variable settings
- Improved security group configuration for node-to-node communication

---

## Version 1.8 - 2025-12-28

### Commit: 35b7d2d
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:29:53 -0500  
**Message:** Refactor EC2 module to enhance Auto Scaling Group configurations and improve instance management.

**Files Changed:**
- `ARCHITECTURE_DIAGRAMS.md` (424 lines added)
- `BEST_PRACTICES_ANALYSIS.md` (557 lines added)
- `HLD_ARCHITECTURE_PLAN.md` (882 lines added)

**Summary:** Added comprehensive architecture documentation including diagrams, best practices analysis, and high-level design architecture plan.

**Changes:**
- Created architecture diagrams documentation
- Added best practices analysis document
- Created high-level design architecture plan document

---

## Version 1.7 - 2025-12-28

### Commit: 0a48d27
**Author:** shrikantnangare (166190171+shrikant-nangare@users.noreply.github.com)  
**Date:** 2025-12-28 14:22:37 -0500  
**Message:** Merge pull request #1 from shrikant-nangare/asg-ec2-refactor

**Files Changed:**
- `.terraform.lock.hcl` (20 lines added)
- `main.tf` (21 lines modified)
- `modules/asg/main.tf` (340 lines added - new file)
- `modules/asg/outputs.tf` (45 lines added - new file)
- `modules/asg/variables.tf` (73 lines added - new file)
- `modules/ec2/main.tf` (14 lines modified)
- `modules/ec2/outputs.tf` (30 lines modified)
- `modules/eks/main.tf` (20 lines modified)
- `outputs.tf` (51 lines modified)
- `terraform.tfvars.example` (9 lines added)
- `variables.tf` (31 lines added)

**Summary:** Merged pull request that introduced a new Auto Scaling Group (ASG) module and refactored EC2 module integration. This was a major refactoring that separated ASG functionality into its own module.

**Changes:**
- Created new ASG module with comprehensive Auto Scaling Group configuration
- Updated EC2 module to work with the new ASG module
- Modified main.tf to integrate the ASG module
- Updated outputs to include ASG-related information
- Added new variables for ASG configuration
- Updated terraform.tfvars.example with ASG examples
- Updated Terraform provider lock file

---

## Version 1.6 - 2025-12-28

### Commit: 1c29709
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:22:21 -0500  
**Message:** Update EC2 module to support multiple instance types and improve Auto Scaling Group settings for better resource management.

**Files Changed:**
- `.terraform.lock.hcl` (20 lines added)

**Summary:** Updated Terraform provider lock file to support new provider versions required for enhanced EC2 and ASG functionality.

**Changes:**
- Updated Terraform provider lock file

---

## Version 1.5 - 2025-12-28

### Commit: b5bf6da
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:22:13 -0500  
**Message:** Refactor EC2 module to create single instances in public and private subnets, update output variables for individual instance IDs, and add Auto Scaling Group configuration with associated variables.

**Files Changed:**
- `main.tf` (21 lines modified)
- `modules/asg/main.tf` (340 lines added - new file)
- `modules/asg/outputs.tf` (45 lines added - new file)
- `modules/asg/variables.tf` (73 lines added - new file)
- `modules/ec2/main.tf` (14 lines modified)
- `modules/ec2/outputs.tf` (30 lines modified)
- `outputs.tf` (51 lines modified)
- `terraform.tfvars.example` (9 lines added)
- `variables.tf` (31 lines added)

**Summary:** Major refactoring of EC2 module to support single instances in both public and private subnets. Introduced Auto Scaling Group module and updated outputs to provide individual instance IDs.

**Changes:**
- Refactored EC2 module to create single instances per subnet type
- Created new ASG module with full Auto Scaling Group support
- Updated output variables to expose individual instance IDs
- Added ASG-related variables and configuration
- Updated terraform.tfvars.example with new configuration options

---

## Version 1.4 - 2025-12-28

### Commit: fb905a6
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:17:16 -0500  
**Message:** Refactor security group ingress rules in EKS module to allow self-communication among nodes

**Files Changed:**
- `modules/eks/main.tf` (20 lines modified: 10 insertions, 10 deletions)

**Summary:** Updated security group ingress rules to enable proper communication between EKS nodes within the cluster.

**Changes:**
- Modified security group ingress rules for node-to-node communication
- Improved security group configuration for cluster internal communication

---

## Version 1.3 - 2025-12-28

### Commit: 0491e43
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:15:58 -0500  
**Message:** Enhance Terraform configuration by adding security group and IAM role definitions for improved AWS infrastructure management

**Files Changed:**
- `.cursorfiles` => `.cursor/rules/00-global-config.md` (file moved/renamed)
- `.terraform.lock.hcl` (25 lines added)

**Summary:** Added Terraform provider lock file and updated cursor configuration files.

**Changes:**
- Updated Terraform provider lock file with provider versions
- Moved/renamed cursor configuration file

---

## Version 1.2 - 2025-12-28

### Commit: c1d06f3
**Author:** shrikant (shrikantnangare@gmail.com)  
**Date:** 2025-12-28 14:15:46 -0500  
**Message:** Add Terraform configuration for AWS infrastructure including VPC, EC2, and EKS modules

**Files Changed:**
- `.cursor/rules/01-ec2-rules.md` (347 lines added - new file)
- `.cursorfiles` (57 lines added - new file)
- `LICENSE` (121 lines removed)
- `README.md` (130 lines added, modifications)
- `main.tf` (59 lines added - new file)
- `modules/ec2/main.tf` (138 lines added - new file)
- `modules/ec2/outputs.tf` (35 lines added - new file)
- `modules/ec2/variables.tf` (55 lines added - new file)
- `modules/eks/main.tf` (338 lines added - new file)
- `modules/eks/outputs.tf` (80 lines added - new file)
- `modules/eks/variables.tf` (104 lines added - new file)
- `modules/vpc/main.tf` (148 lines added - new file)
- `modules/vpc/outputs.tf` (50 lines added - new file)
- `modules/vpc/variables.tf` (22 lines added - new file)
- `outputs.tf` (120 lines added - new file)
- `terraform.tfvars.example` (19 lines added - new file)
- `variables.tf` (72 lines added - new file)

**Summary:** Initial implementation of the complete Terraform infrastructure. This commit added all core modules (VPC, EC2, EKS) and supporting files.

**Changes:**
- Created VPC module with complete networking configuration
- Created EC2 module for instance management
- Created EKS module for Kubernetes cluster management
- Added main.tf to orchestrate all modules
- Created comprehensive variables.tf and outputs.tf
- Added terraform.tfvars.example for configuration examples
- Enhanced README.md with project documentation
- Added cursor configuration files for development
- Removed LICENSE file (moved to different location or format)

---

## Version 1.0 - 2025-07-13

### Commit: f0c0cfa
**Author:** shrikantnangare (166190171+shrikant-nangare@users.noreply.github.com)  
**Date:** 2025-07-13 12:40:09 -0400  
**Message:** Initial commit

**Files Changed:**
- `.gitignore` (37 lines added - new file)
- `LICENSE` (121 lines added - new file)
- `README.md` (2 lines added - new file)

**Summary:** Initial repository setup with basic project files.

**Changes:**
- Added .gitignore for Terraform projects
- Added LICENSE file
- Created initial README.md

---

## Summary Statistics

- **Total Commits:** 12
- **Total Files Changed:** 30+ unique files
- **Major Features Added:**
  - VPC Module
  - EC2 Module
  - EKS Module
  - ASG Module
  - Architecture Documentation
  - Support for existing IAM roles
  - Enhanced security group configurations

---

*Last Updated: 2025-12-28*

