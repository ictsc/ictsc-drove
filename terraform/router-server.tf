resource "sakuracloud_server" "k8s_router" {
  count  = lookup(var.router, terraform.workspace, 0)
  name   = "k8s-router-${count.index + 1}-${terraform.workspace}"
  core   = lookup(var.router_cpu, terraform.workspace, 0)
  memory = lookup(var.router_mem, terraform.workspace, 0)
  disks  = [sakuracloud_disk.k8s_router_disk[count.index].id]
  tags   = ["k8s", terraform.workspace, "@nic-double-queue"]

  network_interface {
    upstream = sakuracloud_internet.k8s_external_switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s_internal_switch.id
    user_ip_address = "192.168.100.${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s-router-${count.index + 1}-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = [sakuracloud_ssh_key_gen.gen_key.id]
    ip_address      = sakuracloud_internet.k8s_external_switch.ip_addresses[count.index]
    gateway         = sakuracloud_internet.k8s_external_switch.gateway
    netmask         = lookup(var.external_subnet, terraform.workspace, 0)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
