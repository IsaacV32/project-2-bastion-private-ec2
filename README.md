# Project 2 — Bastion + Private EC2 Pattern (Terraform)

This repo builds **Project 2** of my cloud engineering portfolio: an EC2 + Linux project focused on secure access patterns.

It follows on from **Project 1 (Production-Grade AWS VPC)** which delivered:
- Multi-AZ public & private subnets
- Internet Gateway + NAT Gateways (per AZ)
- Correct routing
- VPC Flow Logs to CloudWatch

## Goal (Project 2)
Build a **bastion host pattern** for controlled admin access, then deploy **private EC2 instances** that are not publicly reachable.

**Target end-state**
- Bastion EC2 in a public subnet (restricted SSH)
- Private EC2 instances in private subnets (no public IPs)
- Access via:
  - Bastion SSH → private instances 
  - Later: AWS SSM Session Manager (preferred production approach)

---

## Stage 1 — Compute Module Baseline ✅
This stage scaffolds the compute layer as a Terraform module.

### What’s included
- `modules/compute` created with:
  - Input variables (VPC + subnet wiring)
  - Amazon Linux 2023 AMI lookup (data source)
  - Security Group skeletons:
    - Bastion SG (ingress will be restricted to a trusted CIDR)
    - Private EC2 SG placeholder (rules added in later stages)
- Root module wiring and variables (environment inputs)

### What’s intentionally NOT included yet
- No EC2 instances deployed yet (bastion comes in Stage 2)
- No SSH key or CIDR values committed (kept in `terraform.tfvars`, ignored by git)

### Why this stage exists
In real infrastructure repos, modules are built up incrementally. Stage 1 proves:
- module boundaries / separation of concerns
- clean inputs/outputs
- foundations before resources

---

## Quickstart
1) Configure AWS credentials
2) Create `terraform.tfvars` (not committed) with your values:
```hcl
project_name     = "project-2-bastion-private-ec2"
environment      = "dev"
allowed_ssh_cidr = "YOUR_PUBLIC_IP/32"
bastion_key_name = "your-existing-keypair-name"

## Stage 2 — Bastion Host 
This stage deploys a public bastion host for controlled administrative access.

### What’s included
- Bastion EC2 instance deployed into a public subnet
- Security group restricts SSH (22) to a trusted CIDR (`allowed_ssh_cidr`)
- IMDSv2 enforced (`http_tokens = required`)
- Outputs include the bastion public IP for SSH verification

### Verification
- Successfully SSH’d into the bastion using the configured key pair
- Confirmed outbound connectivity from the instance (`curl ifconfig.me`)
