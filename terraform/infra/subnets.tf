resource "oci_core_subnet" "vcn_public_subnet" {
  compartment_id    = var.compartment_id
  vcn_id            = local.vcn_id
  cidr_block        = var.k8s_subnet_cidr
  route_table_id    = oci_core_route_table.k8s_public.id
  security_list_ids = [oci_core_security_list.public_subnet_sl.id]
  display_name      = "k8s-public-subnet"
  dns_label         = "k8spub"
}

resource "oci_core_security_list" "public_subnet_sl" {
  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id
  display_name   = "k8s-public-subnet-sl"

  egress_security_rules {
    stateless        = false
    destination      = "0.0.0.0/0"
    destination_type = "CIDR_BLOCK"
    protocol         = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "10.0.0.0/16"
    source_type = "CIDR_BLOCK"
    protocol    = "all"
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 6443
      max = 6443
    }
  }

  ingress_security_rules {
    stateless   = false
    source      = "0.0.0.0/0"
    source_type = "CIDR_BLOCK"
    protocol    = "6"
    tcp_options {
      min = 30000
      max = 32767
    }
  }
}
