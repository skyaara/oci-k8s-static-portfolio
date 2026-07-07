# Reuse an existing VCN (no NAT/service gateway on Always Free).
# Worker nodes run on a public subnet with internet egress via the existing internet gateway.

data "oci_core_internet_gateways" "ig" {
  compartment_id = var.compartment_id
  vcn_id         = var.vcn_id
}

locals {
  vcn_id = var.vcn_id
  ig_id  = data.oci_core_internet_gateways.ig.gateways[0].id
}

resource "oci_core_route_table" "k8s_public" {
  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = "k8s-public-route"

  route_rules {
    destination       = "0.0.0.0/0"
    destination_type  = "CIDR_BLOCK"
    network_entity_id = local.ig_id
  }
}
