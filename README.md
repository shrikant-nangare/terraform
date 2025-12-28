# Terraform VPC Module

This Terraform configuration creates a VPC with 3 public subnets and 3 private subnets across multiple availability zones.

## AWS Credentials Configuration

There are several ways to configure AWS credentials for Terraform. Choose the method that best fits your environment:

### 1. AWS Credentials File (Recommended for Local Development)

Create or edit `~/.aws/credentials`:

```ini
[default]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

And optionally set the region in `~/.aws/config`:

```ini
[default]
region = us-east-1
```

### 2. Environment Variables

Set these environment variables in your shell:

```bash
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

Or add them to your `~/.bashrc` or `~/.zshrc`:

```bash
# Add to ~/.bashrc or ~/.zshrc
export AWS_ACCESS_KEY_ID="your-access-key-id"
export AWS_SECRET_ACCESS_KEY="your-secret-access-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. AWS SSO (Recommended for Organizations)

If your organization uses AWS SSO:

```bash
aws sso login --profile your-profile-name
export AWS_PROFILE=your-profile-name
```

### 4. IAM Roles (For EC2/ECS/Lambda)

If running Terraform on AWS infrastructure, use IAM roles. No credentials needed - Terraform will automatically use the instance profile.

### 5. Provider Configuration (Not Recommended)

You can hardcode credentials in the provider block, but this is **NOT recommended** for security reasons:

```hcl
provider "aws" {
  region     = "us-east-1"
  access_key = "YOUR_ACCESS_KEY"
  secret_key = "YOUR_SECRET_KEY"
}
```

**⚠️ Warning:** Never commit credentials to version control!

## Usage

1. Configure your AWS credentials using one of the methods above.

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the execution plan:
   ```bash
   terraform plan
   ```

4. Apply the configuration:
   ```bash
   terraform apply
   ```

5. (Optional) Customize variables by creating `terraform.tfvars`:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   # Edit terraform.tfvars with your values
   ```

## Variables

- `aws_region` - AWS region (default: `us-east-1`)
- `project_name` - Project name for resource naming (default: `my-project`)
- `vpc_cidr` - VPC CIDR block (default: `10.0.0.0/16`)
- `enable_nat_gateway` - Enable NAT Gateway for private subnets (default: `true`)
- `tags` - Map of tags to apply to all resources (default: `{}`)

## Outputs

The module outputs various resource IDs including:
- VPC ID and CIDR block
- Public and private subnet IDs and CIDRs
- Internet Gateway ID
- NAT Gateway IDs
- Route table IDs

## Module Structure

```
.
├── main.tf                 # Root module calling VPC module
├── variables.tf            # Root-level variables
├── outputs.tf             # Root-level outputs
├── terraform.tfvars.example
└── modules/
    └── vpc/
        ├── main.tf        # VPC resources
        ├── variables.tf   # Module variables
        └── outputs.tf     # Module outputs
```

