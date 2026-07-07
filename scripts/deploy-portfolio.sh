#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT}/terraform/.kube.config}"
export KUBECONFIG

IMAGE="${IMAGE:-ghcr.io/YOUR_GITHUB_USERNAME/portfolio:latest}"
BUILD="${BUILD:-false}"
PUSH="${PUSH:-false}"

usage() {
  echo "Usage: $0 [--build] [--push] [--image IMAGE]" >&2
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --build) BUILD=true; shift ;;
    --push) PUSH=true; shift ;;
    --image) IMAGE="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) echo "Unknown option: $1" >&2; usage ;;
  esac
done

SERVICE_MANIFEST="${ROOT}/gitops/apps/portfolio/service.yaml"

if [[ -z "${INGRESS_SECURITY_GROUP_OCID:-}" ]] && command -v terraform >/dev/null 2>&1; then
  if terraform -chdir="${ROOT}/terraform/infra" output -raw ingress_security_group_id >/dev/null 2>&1; then
    INGRESS_SECURITY_GROUP_OCID="$(terraform -chdir="${ROOT}/terraform/infra" output -raw ingress_security_group_id)"
  fi
fi

if [[ -n "${INGRESS_SECURITY_GROUP_OCID:-}" ]]; then
  echo "Patching Load Balancer NSG annotation..."
  sed -i '' "s|YOUR_INGRESS_SECURITY_GROUP_OCID|${INGRESS_SECURITY_GROUP_OCID}|g" \
    "${SERVICE_MANIFEST}"
fi

if [[ "${BUILD}" == "true" ]]; then
  echo "Building nginx image (Astro static site baked in): ${IMAGE}"
  if [[ "${PUSH}" == "true" ]]; then
    docker buildx build --platform linux/arm64 -t "${IMAGE}" --push "${ROOT}/site"
  else
    docker buildx build --platform linux/arm64 -t "${IMAGE}" "${ROOT}/site"
  fi
fi

echo "Deploying portfolio..."
kubectl apply -k "${ROOT}/gitops/apps/portfolio"
kubectl set image deployment/portfolio portfolio="${IMAGE}" -n portfolio
kubectl rollout status deployment/portfolio -n portfolio

echo "Waiting for Load Balancer..."
kubectl wait --for=condition=ready --timeout=300s -n portfolio service/portfolio 2>/dev/null || true

LB_HOSTNAME="$(kubectl get svc portfolio -n portfolio -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' 2>/dev/null || true)"
LB_IP="$(kubectl get svc portfolio -n portfolio -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null || true)"

echo "Portfolio deployed."
if [[ -n "${LB_HOSTNAME}" ]]; then
  echo "Load Balancer: ${LB_HOSTNAME}"
elif [[ -n "${LB_IP}" ]]; then
  echo "Load Balancer IP: ${LB_IP}"
else
  echo "Load Balancer still provisioning — run: kubectl get svc portfolio -n portfolio -w"
fi
