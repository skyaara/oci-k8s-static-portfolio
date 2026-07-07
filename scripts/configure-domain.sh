#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: $0 example.com" >&2
  exit 1
fi

DOMAIN="$1"
WWW="www.${DOMAIN}"
SITE_URL="https://${WWW}"

replace() {
  find gitops site -type f \( -name '*.yaml' -o -name '*.yml' -o -name '*.mjs' -o -name '*.astro' -o -name '*.txt' -o -name '*.ts' -o -name '*.conf' \) \
    -not -path 'site/node_modules/*' \
    -exec sed -i '' \
      -e "s/example.com/${DOMAIN}/g" \
      -e "s/www.example.com/${WWW}/g" {} +
}

replace
echo "Configured domain: ${SITE_URL}"
echo "Also update config/domain.example.env and terraform/infra/terraform.tfvars manually."
