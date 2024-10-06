resource "sakuracloud_switch" "k8s_internal_switch" {
  name = "k8s-${terraform.workspace}-internal-switch"
  tags = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_vpc_router" "standard" {
  name                = "k8s-${terraform.workspace}-internal-router"
  tags                = ["k8s", terraform.workspace]
  internet_connection = true

  private_network_interface {
    index        = 1
    switch_id    = sakuracloud_switch.k8s_internal_switch.id
    ip_addresses = ["192.168.100.254"]
    netmask      = 24
  }
}
