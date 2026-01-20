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

## Stage 1 — Compute Module Baseline 
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

## Stage 3 — Private EC2 + Bastion-only SSH 
This stage deploys a private EC2 instance with no public IP and restricts SSH access to the bastion host only.

### What’s included
- Private EC2 deployed into a private subnet (no public IP)
- Security group allows SSH (22) **only** from the bastion security group
- IMDSv2 enforced on the private instance

### Verification
- Direct SSH from laptop → private instance fails (expected)
- SSH from bastion → private instance succeeds
- Private instance has outbound access via NAT (e.g. `dnf update` / `curl ifconfig.me`)

## Stage 4 — Secure Access via AWS SSM (No SSH) ✅

This stage replaces SSH-based access to private EC2 instances with **AWS Systems Manager Session Manager**, aligning with modern production security practices.

### What’s included
- IAM role and instance profile with `AmazonSSMManagedInstanceCore`
- Private EC2 attached to SSM instance profile
- **No inbound SSH rules** on private EC2 security group
- Access controlled entirely via IAM + SSM
- No SSH keys required for private instances

### Why this matters
- Eliminates SSH key management risk
- Zero inbound ports on private instances
- Full auditability via AWS CloudTrail and SSM logs
- Common pattern in regulated and enterprise environments

### Verification
- Private EC2 appears as **Online** in Systems Manager → Managed Instances
- Access via:
  ```bash
  aws ssm start-session --target <private_instance_id>

## Stage 5 — Private EC2 Auto Scaling Group (Launch Template + ASG) ✅

This stage replaces the single private EC2 instance with an Auto Scaling Group across private subnets (Multi-AZ).

### What’s included
- Launch Template for private instances (Amazon Linux 2023)
- Auto Scaling Group spanning private subnets
- IMDSv2 enforced
- SSM instance profile attached to all ASG instances (no SSH)
- Scales and self-heals automatically

### Verification
- ASG launches instances across private subnets
- Instances register as **Online** in SSM Managed Instances
- Terminating an instance triggers automatic replacement
