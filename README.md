# Three-Tier Architecture — AWS (Terraform + DevSecOps CI)

Enterprise-grade three-tier AWS infrastructure provisioned with Terraform, secured with WAFv2, and deployed through a DevSecOps GitHub Actions pipeline.

[![My Skills](https://skillicons.dev/icons?i=terraform,aws,githubactions)](https://skillicons.dev)

![Architecture](https://github.com/dev126712/three-tier-architecture/blob/6235857785ad7c407f1f26ef24c3ce65f9fb1e3f/Untitled%20Diagram.drawio.png)

---

## Infrastructure Overview

```
Internet
    │
    ▼
WAFv2 Web ACL  (SQLi, XSS, managed rule groups)
    │
    ▼
Public ALB  (internet-facing)
    │
    ▼
App Tier — Launch Template + Auto Scaling Group
    │
    ▼
Private (Internal) ALB  (App → DB tier boundary)
    │
    ▼
DB Tier  (private subnets, Multi-AZ)
```

### Networking

| Component | Detail |
|---|---|
| **VPC** | Custom VPC with public and private subnets |
| **IGW** | Internet Gateway for public tier |
| **Bastion Host** | Single hardened EC2 in public subnet with IAM role — SSH jump box for private resources |
| **Security Groups** | Scoped per tier: public ALB · internal ALB · App tier · Bastion |

### Security

| Component | Detail |
|---|---|
| **WAFv2 Web ACL** | Attached to public ALB — SQL injection, XSS, and managed rule group protection |
| **WAF Logging** | WAF decision logs shipped to S3 |
| **VPC Flow Logs** | All traffic logged to S3 with KMS SSE encryption |
| **S3 Hardening** | Server-side encryption (KMS) · versioning · lifecycle policy · public access block · access logging to replica bucket |
| **Replica S3 Bucket** | Separate bucket for access log storage with SSE + event notifications |

### Compute

| Component | Detail |
|---|---|
| **App Tier Launch Template** | EC2 with configurable AMI, instance type, user data |
| **Auto Scaling Group** | Scale out/in behind the private internal ALB based on demand |
| **Bastion Host IAM** | Instance profile with scoped IAM role — no long-lived credentials |

---

## CI/CD Pipeline (GitHub Actions)

Two workflows enforce quality and security on every push to `.tf` or workflow files.

### `ci-terraform.yml` — Infrastructure CI

| Step | Tool | What it does |
|---|---|---|
| Terraform Init | Terraform | Downloads providers and modules |
| Terraform Fmt | Terraform | Enforces HCL formatting |
| Terraform Validate | Terraform | Validates configuration syntax |
| Terraform Plan | Terraform | Shows infrastructure diff (no apply in CI) |

### `security.yml` — DevSecOps

| Step | Tool | What it checks |
|---|---|---|
| Workflow scan | Checkov | SAST on all `.github/workflows/*.yml` files |
| Terraform scan | Checkov | SAST on all `.tf` files — misconfigurations, policy violations |

---

## Quick Start

```bash
git clone https://github.com/dev126712/three-tier-architecture
cd three-tier-architecture

# Configure AWS credentials
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...

terraform init
terraform plan
terraform apply
```

---

## File Structure

| File | Resource |
|---|---|
| `vpc.tf` | VPC, subnets, routing |
| `igw.tf` | Internet Gateway |
| `public-alb.tf` | Public ALB + WAFv2 association |
| `private-alb.tf` | Internal ALB (App → DB boundary) |
| `app.tf` | App Tier launch template + ASG |
| `alb_sg.tf` | Security groups for ALBs |
| `baston-host.tf` | Bastion EC2, keypair, IAM role |
| `s3.tf` | VPC flow log bucket + replica bucket (SSE, lifecycle, versioning) |
| `web.tf` | WAFv2 Web ACL rules and logging |
| `subnets.tf` | Subnet definitions |
| `variables.tf` | Input variables |
| `provider.tf` | AWS provider configuration |
