resource "sakuracloud_internet" "k8s_external_switch" {
  name       = "k8s-external-switch"
  netmask    = lookup(var.external_subnet, terraform.workspace, 0)
  band_width = 100
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_subnet" "bgp_subnet" {
  internet_id = sakuracloud_internet.k8s_external_switch.id
  next_hop    = sakuracloud_internet.k8s_external_switch.ip_addresses[length(sakuracloud_internet.k8s_external_switch.ip_addresses) - 11]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
