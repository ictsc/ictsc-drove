resource "sakuracloud_internet" "k8s-external-switch" {
  name       = "k8s-external-switch"
  netmask    = lookup(var.external_subnet, terraform.workspace)
  band_width = 100
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_subnet" "bgp-subnet" {
  internet_id = sakuracloud_internet.k8s-external-switch.id
  next_hop    = sakuracloud_internet.k8s-external-switch.ip_addresses[length(sakuracloud_internet.k8s-external-switch.ip_addresses) - 11]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
