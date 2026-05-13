# Cloud Deployment — AWS Infrastructure with Terraform

A production-ready AWS infrastructure for deploying a full-stack web application (Angular frontend + Node.js backend + MySQL RDS), fully provisioned with Terraform.

---

## Architecture Overview

```
Internet
   │
   ├──▶ Frontend EC2 (public subnet A)
   │       └── Nginx serves Angular SPA
   │
   └──▶ Application Load Balancer (public subnets A & B)
           └──▶ Backend Auto Scaling Group (private subnets A & B)
                   └── Node.js / PM2 on port 3000
                           └──▶ RDS MySQL (private subnets A & B)
```

The VPC spans two availability zones for high availability. Backend instances and the database are isolated in private subnets and never directly reachable from the internet.

---

## Infrastructure Components

| Component | Resource | Details |
|---|---|---|
| **Networking** | VPC | `10.0.0.0/16`, 2 public + 2 private subnets |
| | Internet Gateway | Public internet access for public subnets |
| | NAT Gateway | Outbound internet access for private subnets |
| **Frontend** | EC2 Instance | `t3.micro`, public subnet, Nginx + Angular |
| **Backend** | Auto Scaling Group | 2–4 × `t3.micro`, private subnets |
| | Application Load Balancer | HTTP:80, forwards to backend on port 3000 |
| **Database** | RDS MySQL | `db.t3.micro`, 20 GB, private subnets |
| **Security** | 4 Security Groups | `frontend-sg`, `backend-sg`, `alb-sg`, `rds-sg` |

### Security Group Rules

```
frontend-sg  ←  HTTP :80  from 0.0.0.0/0
             ←  SSH  :22  from your IP only

alb-sg       ←  HTTP :80  from 0.0.0.0/0

backend-sg   ←  TCP  :3000 from alb-sg
             ←  SSH  :22   from frontend-sg

rds-sg       ←  TCP  :3306 from backend-sg only
```

---

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.0
- [AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html) configured with appropriate permissions
- An existing EC2 Key Pair in your target AWS region
- An Ubuntu AMI ID for your target region (e.g. Ubuntu 22.04 LTS)

---

## Getting Started

### 1. Clone the repository

```bash
git clone <your-repo-url>
cd infrastructure
```

### 2. Create your variables file

Create a `terraform.tfvars` file (already gitignored):

```hcl
aws_region  = "eu-west-1"
key_name    = "my-keypair"
ami_id      = "ami-xxxxxxxxxxxxxxxxx"
db_username = "admin"
db_password = "your-secure-password"
db_name     = "appdb"

# Optional: override the backend URL used by the frontend
# api_url   = "http://my-custom-domain.com"
```

### 3. Initialize and apply

```bash
terraform init
terraform plan
terraform apply
```

### 4. Access your application

After apply completes, Terraform prints:

```
frontend_ip      = "x.x.x.x"         # Open in browser → http://x.x.x.x
backend_alb_dns  = "backend-alb-xxx.elb.amazonaws.com"
rds_endpoint     = "xxx.rds.amazonaws.com"
key_pair_name    = "my-keypair"
```

---

## Project Structure

```
.
├── infrastructure/
│   ├── provider.tf       # AWS provider configuration
│   ├── variables.tf      # Input variable declarations
│   ├── vpc.tf            # VPC, subnets, IGW, NAT, route tables
│   ├── security.tf       # Security groups + RDS subnet group
│   ├── frontend.tf       # Frontend EC2 instance
│   ├── backend.tf        # Launch template, ALB, ASG, target group
│   ├── rds.tf            # RDS MySQL instance
│   ├── outputs.tf        # Output values
│   └── userdata/
│       ├── frontend.sh   # Installs Nginx, builds & serves Angular app
│       └── backend.sh    # Installs Node.js, clones repo, starts with PM2
```

---

## How the User Data Scripts Work

**`frontend.sh`**
1. Installs Nginx and Node.js 18
2. Allocates 2 GB swap to prevent OOM errors during the Angular build
3. Clones the frontend repository and patches the API URL at build time
4. Builds the Angular app and copies the output to `/var/www/html`
5. Configures Nginx as a reverse proxy with SPA fallback (`try_files`)

**`backend.sh`**
1. Installs Node.js 18, PM2, and the MySQL client
2. Clones the backend repository and writes a `.env` file with database credentials
3. Polls the RDS endpoint until the database is ready before starting the app
4. Starts the app with PM2 and persists it across reboots via `systemd`

---

## Variables Reference

| Variable | Description | Default |
|---|---|---|
| `aws_region` | AWS region to deploy into | — |
| `key_name` | EC2 Key Pair name for SSH access | — |
| `ami_id` | Ubuntu AMI ID for EC2 instances | — |
| `db_username` | RDS master username | — |
| `db_password` | RDS master password | — |
| `db_name` | Initial database name | — |
| `api_url` | Override backend URL for frontend | `""` (uses ALB DNS) |

---

## Tear Down

```bash
terraform destroy
```

> **Note:** The RDS instance is created with `skip_final_snapshot = true`. No automated snapshot is taken on destroy.

---

## Security Considerations

- Database credentials are injected at launch via EC2 user data and stored in a `.env` file on the instance. For production workloads, consider using **AWS Secrets Manager** or **Parameter Store** instead.
- SSH access to the frontend is restricted to the public IP detected at `terraform apply` time via the `checkip.amazonaws.com` lookup.
- The backend and database are never directly reachable from the internet.
- `terraform.tfvars` is gitignored to prevent accidental credential commits.
