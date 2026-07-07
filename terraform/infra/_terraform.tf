terraform {

  # this requires tf >=1.12
  backend "oci" {
    namespace = "YOUR_OCI_OBJECT_STORAGE_NAMESPACE" # oci os ns get
    bucket    = "terraform-states"
    key       = "infra/terraform.tfstate"
  }

  required_providers {
    jq = {
      source  = "massdriver-cloud/jq"
      version = "0.2.1"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
    oci = {
      source  = "oracle/oci"
      version = "~> 7.32.0"
    }
  }
}
