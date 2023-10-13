resource "sakuracloud_server" "k8s_control_plane" {
  count  = lookup(var.control_plane, terraform.workspace)
  name   = "k8s_control_plane_${count.index + 1}_${terraform.workspace}"
  core   = lookup(var.control_plane_cpu, terraform.workspace)
  memory = lookup(var.control_plane_mem, terraform.workspace)
  disks  = [sakuracloud_disk.k8s_control_plane_disk[count.index].id]
  tags   = ["k8s", terraform.workspace, "@nic-double-queue"]

  network_interface {
    upstream = sakuracloud_internet.k8s_external_switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s_internal_switch.id
    user_ip_address = "192.168.100.1${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s_control_plane_${count.index + 1}_${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = [sakuracloud_ssh_key_gen.gen_key.id]
    ip_address      = sakuracloud_internet.k8s_external_switch.ip_addresses[count.index + lookup(var.router, terraform.workspace)]
    gateway         = sakuracloud_internet.k8s_external_switch.gateway
    netmask         = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
