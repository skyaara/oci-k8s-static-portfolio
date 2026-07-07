#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBECONFIG="${KUBECONFIG:-${ROOT}/terraform/.kube.config}"
export KUBECONFIG

if [[ -z "${CLOUDFLARE_API_TOKEN:-}" ]]; then
  echo "Set CLOUDFLARE_API_TOKEN before running this script." >&2
  exit 1
fi

if ! command -v helm >/dev/null 2>&1; then
  echo "helm is required." >&2
  exit 1
fi

if ! command -v kubectl >/dev/null 2>&1; then
  echo "kubectl is required." >&2
  exit 1
fi

echo "Using kubeconfig: ${KUBECONFIG}"

echo "Installing external-dns (Cloudflare)..."
kubectl create namespace external-dns --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic external-dns-config \
  --namespace external-dns \
  --from-literal=apiKey="${CLOUDFLARE_API_TOKEN}" \
  --dry-run=client -o yaml | kubectl apply -f -

helm repo add external-dns https://kubernetes-sigs.github.io/external-dns >/dev/null 2>&1 || true
helm upgrade --install external-dns external-dns/external-dns \
  --namespace external-dns \
  --version 1.20.0 \
  -f "${ROOT}/deploy/helm-values/external-dns.yaml" \
  --wait

echo "external-dns ready. Deploy the portfolio Service to create the www DNS record."
