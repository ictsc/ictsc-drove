resource "sakuracloud_internet" "k8s_external_switch" {
  name       = "k8s-${terraform.workspace}-external-switch"
  tags       = ["k8s", terraform.workspace]
  netmask    = lookup(var.external_subnet, terraform.workspace, 0)
  band_width = 100
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

