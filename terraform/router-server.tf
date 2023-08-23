resource "sakuracloud_server" "k8s-router" {
  count  = lookup(var.router, terraform.workspace)
  name   = "k8s-router-${count.index + 1}-${terraform.workspace}"
  core   = lookup(var.router_cpu, terraform.workspace)
  memory = lookup(var.router_mem, terraform.workspace)
  disks  = ["${sakuracloud_disk.k8s-router-disk[count.index].id}"]
  tags   = ["k8s", "${terraform.workspace}", "@nic-double-queue"]

  network_interface {
    upstream = sakuracloud_internet.k8s-external-switch.switch_id
  }

  disk_edit_parameter {
    hostname        = "k8s-router-${count.index + 1}-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "false"
    ip_address      = sakuracloud_internet.k8s-external-switch.ip_addresses[count.index]
    gateway         = sakuracloud_internet.k8s-external-switch.gateway
    netmask         = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
