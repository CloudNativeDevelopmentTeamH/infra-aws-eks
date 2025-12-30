# infra-aws-eks
IaC for AWS EKS setup

## Install AWS CLI
```sh
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

---

## Install OpenTofu
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

---

## Create Cluster

```sh
tofu init
tofu plan
tofu apply
```

---

## Update Cluster

```sh
tofu init -upgrade # if providers changes have been made
tofu plan -var-file values.tfvars
tofu apply -var-file values.tfvars
```

---

## Set local kubeconfig

```sh
aws eks update-kubeconfig --name cnd-prod-eks --region eu-central-1
```

---

## Deploy & Update Argo

First update Cluster
```sh
tofu init -upgrade # if providers changes have been made
tofu plan -var="enable_argocd=true" -var-file values.tfvars
tofu apply -var="enable_argocd=true" -var-file values.tfvars
```

---

## Connect to jump server

```sh
# Get IP
tofu output jump_server_public_ip

# Connect via SSH
ssh -i cnd-prod-eks-jump-server-key.pem ec2-user@<IP-goes-here>
```

---

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