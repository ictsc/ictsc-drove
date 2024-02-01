resource "sakuracloud_internet" "k8s_external_switch" {
  name       = "k8s-${terraform.workspace}-external-switch"
  netmask    = lookup(var.external_subnet, terraform.workspace, 0)
  band_width = 100
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_subnet" "bgp_subnet" {
  internet_id = sakuracloud_internet.k8s_external_switch.id
  next_hop    = sakuracloud_server.k8s_router[0].ip_address
  netmask     = 28
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
