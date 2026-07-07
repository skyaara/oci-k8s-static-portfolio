resource "oci_core_network_security_group" "ingress_lb" {
  compartment_id = var.compartment_id
  vcn_id         = local.vcn_id

  display_name = "ingress"
}

resource "oci_core_network_security_group_security_rule" "ingress_http" {
  network_security_group_id = oci_core_network_security_group.ingress_lb.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "ingress_80_lb"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 80
      min = 80
    }
  }
}

resource "oci_core_network_security_group_security_rule" "ingress_https" {
  network_security_group_id = oci_core_network_security_group.ingress_lb.id
  direction                 = "INGRESS"
  protocol                  = "6"

  description = "ingress_443_lb"

  source      = "0.0.0.0/0"
  source_type = "CIDR_BLOCK"

  tcp_options {
    destination_port_range {
      max = 443
      min = 443
    }
  }
}
