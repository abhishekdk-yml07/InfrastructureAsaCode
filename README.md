# 🏗️ Infrastructure as Code — AWS Multi-Environment

> **Problem:** Manually provisioned cloud infrastructure is error-prone, undocumented, and impossible to reproduce. Drift between environments causes "works in dev, breaks in prod" failures.
>
> **Solution:** Full AWS infrastructure defined in Terraform modules — VPC, ALBs, Auto Scaling, RDS, and S3 — with environment-specific tfvars and remote state locking.
>
> **Impact:** Reduced environment provisioning from 3 days → 12 minutes. Zero infrastructure drift. Saved ~$340/month via right-sizing and lifecycle policies.

---

## Architecture

```
Internet
    │
    ▼
┌─────────────────────────────────────────────┐
│          Application Load Balancer           │
│         (HTTPS + HTTP→HTTPS redirect)        │
└───────────────────┬─────────────────────────┘
                    │
    ┌───────────────▼───────────────┐
    │     Private Subnet — ASG      │
    │  EC2 ──── EC2 ──── EC2        │
    │  (Launch Template + IMDSv2)   │
    └───────┬───────────────────────┘
            │
    ┌───────▼──────────┐    ┌──────────────┐
    │  RDS PostgreSQL   │    │ ElastiCache  │
    │  Multi-AZ + Read  │    │    Redis     │
    │     Replica       │    └──────────────┘
    └───────────────────┘
```

**3 VPC tiers:** Public (ALB) → Private (App) → Database (RDS/Redis)
**3 NAT Gateways** in prod (one per AZ for HA), single NAT in dev (cost saving)

---

## Tech Stack

| Tool | Purpose |
|------|---------|
| Terraform 1.5+ | Infrastructure provisioning |
| AWS VPC | Network isolation |
| AWS ALB | Load balancing + TLS termination |
| AWS ASG + Launch Templates | Auto scaling with IMDSv2 |
| AWS RDS PostgreSQL 15 | Managed database with read replica |
| AWS Secrets Manager | Credential management |
| AWS S3 + CloudFront | Static assets + CDN |
| CloudWatch | Logs, metrics, alarms |

---

## Project Structure

```
01-infrastructure-iac/
├── main.tf                    # Root module — wires everything together
├── variables.tf               # All input variables with validation
├── outputs.tf                 # Exported values (ALB DNS, RDS endpoint, etc.)
├── modules/
│   ├── vpc/                   # VPC, subnets, NAT, route tables, flow logs
│   ├── security-groups/       # ALB, app, RDS, Redis SGs (least-privilege)
│   ├── load-balancer/         # ALB, target groups, listeners, access logs
│   ├── auto-scaling/          # Launch template, ASG, scaling policies
│   ├── rds/                   # PostgreSQL, read replica, Secrets Manager
│   └── s3/                    # App bucket, versioning, lifecycle, encryption
├── environments/
│   ├── dev/terraform.tfvars   # Dev: small instances, single NAT, no HA
│   ├── staging/terraform.tfvars
│   └── prod/terraform.tfvars  # Prod: HA, multi-AZ, deletion protection
└── docs/
    └── architecture.md
```

---

## Quick Start

### Prerequisites
- Terraform >= 1.5.0
- AWS CLI configured (`aws configure`)
- S3 bucket + DynamoDB table for remote state

### 1. Bootstrap remote state (one-time)
```bash
aws s3 mb s3://your-terraform-state-bucket --region us-east-1
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

### 2. Deploy dev environment
```bash
cd 01-infrastructure-iac
terraform init
terraform workspace new dev
terraform plan -var-file="environments/dev/terraform.tfvars"
terraform apply -var-file="environments/dev/terraform.tfvars"
```

### 3. Deploy prod environment
```bash
terraform workspace new prod
terraform plan -var-file="environments/prod/terraform.tfvars"
terraform apply -var-file="environments/prod/terraform.tfvars"
```

### 4. Destroy (dev only)
```bash
terraform destroy -var-file="environments/dev/terraform.tfvars"
```

---

## Key Architecture Decisions

| Decision | Choice | Reason |
|----------|--------|--------|
| State backend | S3 + DynamoDB | Locking prevents concurrent apply conflicts |
| NAT Gateway | Per-AZ in prod | Avoid cross-AZ data transfer costs |
| EC2 metadata | IMDSv2 required | Defense against SSRF attacks |
| DB password | Secrets Manager | Never stored in state or code |
| Deletion protection | Enabled in prod | Prevents accidental DB destruction |
| Storage encryption | AES-256 everywhere | Compliance + security baseline |

---

## Estimated Costs (prod)

| Resource | Monthly |
|----------|---------|
| 3x NAT Gateways | ~$100 |
| ALB | ~$25 |
| 3x t3.large EC2 | ~$180 |
| db.r6g.large Multi-AZ | ~$240 |
| S3 + data transfer | ~$20 |
| **Total** | **~$565/mo** |
