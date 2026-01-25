# AWS EKS Infrastructure

Infrastructure as Code (IaC) for provisioning a production-ready AWS EKS cluster using OpenTofu/Terraform. This project sets up a complete Kubernetes environment with networking, security, storage, ingress, and optional ArgoCD GitOps deployment.

## 🏗️ Architecture Overview

This infrastructure creates:

- **EKS Cluster**: Managed Kubernetes control plane (v1.x)
- **VPC & Networking**: Custom VPC with 2 public subnets across availability zones
- **Worker Nodes**: Auto-scaling node group (2-3 t3.small instances)
- **AWS Load Balancer Controller**: For ALB/NLB ingress management
- **EBS CSI Driver**: Persistent volume support with EBS storage
- **Jump Server**: Bastion host for secure cluster access
- **ECR Integration**: IAM roles for container image pulling
- **ArgoCD (Optional)**: GitOps continuous delivery
- **OIDC Provider**: For IAM Roles for Service Accounts (IRSA)

### Infrastructure Components

```
AWS Account (eu-central-1)
├── VPC (10.0.0.0/16)
│   ├── Public Subnet 1 (10.0.0.0/24) - AZ1
│   ├── Public Subnet 2 (10.0.1.0/24) - AZ2
│   ├── Internet Gateway
│   └── Route Tables
│
├── EKS Cluster
│   ├── Control Plane (Managed by AWS)
│   ├── Node Group (2-3 t3.small instances)
│   ├── Security Groups
│   └── IAM Roles & Policies
│
├── Add-ons
│   ├── AWS Load Balancer Controller
│   ├── EBS CSI Driver (Persistent Volumes)
│   └── ArgoCD (Optional)
│
├── Jump Server (Amazon Linux 2023)
│   ├── EC2 Instance (t2.micro)
│   ├── Public IP with SSH access
│   └── Pre-installed: kubectl, helm, awscli
│
└── IAM
    ├── OIDC Provider (IRSA)
    ├── ECR Access Role (for image pulling)
    ├── EBS CSI Driver Role
    └── ALB Controller Role
```

## 📋 Prerequisites

### Required Tools

1. **AWS CLI** - For AWS authentication and management
2. **OpenTofu** - Infrastructure as Code tool (Terraform-compatible)
3. **kubectl** - Kubernetes command-line tool
4. **helm** - Kubernetes package manager (for ArgoCD)

### AWS Requirements

- AWS Account with appropriate credentials
- IAM permissions to create:
  - VPC, Subnets, Internet Gateway, Route Tables
  - EKS Cluster, Node Groups
  - EC2 Instances, Security Groups
  - IAM Roles, Policies, OIDC Provider
  - Load Balancers (via ALB Controller)
  - ECR Repositories


### Install AWS CLI
```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

### Install OpenTofu
```sh
# Download the installer script:
curl --proto '=https' --tlsv1.2 -fsSL https://get.opentofu.org/install-opentofu.sh -o install-opentofu.sh
# Alternatively: wget --secure-protocol=TLSv1_2 --https-only https://get.opentofu.org/install-opentofu.sh -O install-opentofu.sh

# Give it execution permissions:
chmod +x install-opentofu.sh

# Please inspect the downloaded script

# Run the installer:
./install-opentofu.sh --install-method deb

# Remove the installer:
rm -f install-opentofu.sh
```

## Create Cluster

```sh
tofu init
tofu plan
tofu apply
```


## Update Cluster

```sh
tofu init -upgrade # if providers changes have been made
tofu plan -var-file values.tfvars
tofu apply -var-file values.tfvars
```


## Set local kubeconfig

```sh
aws eks update-kubeconfig --name cnd-prod-eks --region eu-central-1
```


## Deploy & Update Argo

First update Cluster
```sh
tofu init -upgrade # if providers changes have been made
tofu plan -var="enable_argocd=true" -var-file values.tfvars
tofu apply -var="enable_argocd=true" -var-file values.tfvars
```


## Connect to jump server

```sh
# Get IP
tofu output jump_server_public_ip

# Connect via SSH (without port forwarding)
ssh -i cnd-prod-eks-jump-server-key.pem ec2-user@<IP-goes-here>

# Connect via SSH (with port fowarding to localhost:8888)
ssh -i cnd-prod-eks-jump-server-key.pem -L 8888:localhost:8888 ec2-user@<IP-goes-here>
```


## Get ArgoCD secret

```sh
kubectl -n argocd get secret argocd-initial-admin-secret \
  -o jsonpath="{.data.password}" \
| base64 -d \
| awk '{ printf "\033[31m%s\033[0m\n", $0 }'
```


## References

- https://github.com/opentofu/terraform-provider-aws/tree/v6.27.0/examples/eks-getting-started
- https://search.opentofu.org/provider/hashicorp/aws/latest/docs/resources/eks_cluster
- https://developer.hashicorp.com/terraform/tutorials/kubernetes/eks