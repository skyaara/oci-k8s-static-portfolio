variable "compartment_id" {
  type        = string
  description = "The compartment to create the resources in"
}

variable "vcn_id" {
  type        = string
  description = "OCID of an existing VCN with an internet gateway"
}

variable "k8s_subnet_cidr" {
  type        = string
  description = "CIDR for the OKE public subnet (must not overlap existing subnets in the VCN)"
  default     = "10.0.1.0/24"
}

variable "region" {
  description = "OCI region"
  type        = string

  default = "ap-hyderabad-1" # your OCI home region
}

variable "ssh_public_key" {
  description = "SSH Public Key used to access all instances"
  type        = string
}

variable "kubernetes_version" {
  description = "Version of Kubernetes"
  type        = string

  default = "v1.33.1"
}

variable "kubernetes_worker_nodes" {
  description = "Worker node count"
  type        = number

  default = 2
}
