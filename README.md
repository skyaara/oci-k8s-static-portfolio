# Portfolio on Oracle Always Free Kubernetes

Static [Astro](https://astro.build) portfolio **built into an nginx Docker image** and deployed to Oracle OKE. No FluxCD, no Envoy Gateway — just nginx behind an OCI Load Balancer.

## Architecture

```
Astro (SSG)  →  Docker (nginx:alpine)  →  K8s Deployment  →  OCI Load Balancer :80
                                                                    ↓
                                                              Cloudflare DNS + TLS
```

- **Build**: `site/Dockerfile` runs `npm run build`, copies `dist/` into nginx
- **Serve**: nginx handles static files, caching headers, and apex → www redirect
- **Ingress**: Kubernetes `LoadBalancer` Service (OCI flexible LB + NSG from Terraform)
- **DNS/TLS**: Cloudflare (external-dns for `www`, Cloudflare proxy for HTTPS)
- **Deploy**: `kubectl` + `docker` — no GitOps operator

## Prerequisites

| Requirement | Notes |
|-------------|--------|
| OCI Always Free | ARM (A1) capacity; OKE `cluster-count` ≥ 1 |
| Domain on Cloudflare | DNS + TLS at the edge |
| Tools | Terraform ≥ 1.12, OCI CLI, kubectl, helm, Docker |

## Install tools (macOS)

```bash
brew install hashicorp/tap/terraform oci-cli kubectl helm docker node
```

## Quick start

### 0. Local secrets (not committed)

```bash
cp terraform/infra/terraform.tfvars.example terraform/infra/terraform.tfvars
cp config/domain.example.env config/domain.env
```

### 1. OCI auth + Terraform state (one-time)

```bash
oci setup config
oci os ns get

TENANCY_OCID=$(grep tenancy ~/.oci/config | cut -d= -f2)
oci os bucket create --name terraform-states --versioning Enabled --compartment-id "$TENANCY_OCID"
```

Set `namespace` in `terraform/infra/_terraform.tf` from `oci os ns get`.

### 2. Configure `terraform/infra/terraform.tfvars`

```hcl
compartment_id          = "ocid1.tenancy.oc1..YOUR_TENANCY_OCID"
region                  = "ap-hyderabad-1"
vcn_id                  = "ocid1.vcn.oc1..YOUR_VCN_OCID"
k8s_subnet_cidr         = "10.0.0.0/24"
ssh_public_key          = "ssh-ed25519 AAAA... your-key"
kubernetes_worker_nodes = 2
```

### 3. Provision OKE

```bash
cd terraform/infra
terraform init && terraform apply
kubectl --kubeconfig ../.kube.config get nodes
```

### 4. Configure domain

```bash
./scripts/configure-domain.sh yourdomain.com
```

Updates `site/nginx.conf`, `site/astro.config.mjs`, and the Load Balancer external-dns hostname in `gitops/apps/portfolio/service.yaml`.

### 5. external-dns (one-time, optional but recommended)

```bash
export CLOUDFLARE_API_TOKEN="your-token"
./scripts/setup-dns.sh
```

Creates the `www.yourdomain.com` A record pointing at the Load Balancer.

### 6. Build nginx image and deploy

```bash
# Build Astro into nginx image, push to GHCR, deploy to cluster
./scripts/deploy-portfolio.sh \
  --build --push \
  --image ghcr.io/YOUR_GITHUB_USERNAME/portfolio:latest
```

The Dockerfile builds the static site and serves it from nginx — no separate `npm run build` step needed.

### 7. Cloudflare

1. **SSL/TLS** → Full (strict) or Flexible (origin HTTP on port 80)
2. **Redirect rule**: `yourdomain.com` → `https://www.yourdomain.com${uri.path}` (301)
3. Ensure `www` record is proxied (orange cloud) if using Cloudflare TLS

### 8. Verify

```bash
kubectl --kubeconfig terraform/.kube.config get svc portfolio -n portfolio
curl -I http://www.yourdomain.com/
curl https://www.yourdomain.com/sitemap-index.xml
```

## Build the nginx image locally

```bash
cd site
docker build --platform linux/arm64 -t portfolio:local .
docker run --rm -p 8080:80 portfolio:local
open http://localhost:8080
```

## Useful commands

```bash
# Redeploy after code changes
./scripts/deploy-portfolio.sh --build --push --image ghcr.io/YOU/portfolio:latest

# Watch rollout
kubectl --kubeconfig terraform/.kube.config rollout status deployment/portfolio -n portfolio

# Load Balancer address
kubectl --kubeconfig terraform/.kube.config get svc portfolio -n portfolio

# Astro dev (no Docker)
cd site && npm install && npm run dev
```

## Project layout

```
site/                         Astro site + Dockerfile + nginx.conf
gitops/apps/portfolio/        Deployment + LoadBalancer Service
deploy/helm-values/           external-dns Helm values
terraform/infra/              OKE cluster + ingress NSG
scripts/
  configure-domain.sh       Replace example.com placeholders
  setup-dns.sh              Install external-dns (Cloudflare)
  deploy-portfolio.sh       Build nginx image + kubectl deploy
```

## Free tier

2× ARM nodes (1 oCPU, 6GB each). nginx pod uses ~32MB RAM. OKE Basic cluster is free.

## What we removed

- FluxCD / GitOps operators
- Envoy Gateway + HTTPRoute
- cert-manager (TLS terminates at Cloudflare)
- `gitops/platform/` stack

See [docs/fluxcd-migration.md](docs/fluxcd-migration.md) only if you want GitOps later.
