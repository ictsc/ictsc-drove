resource "sakuracloud_server" "k8s-lb-server" {
  count  = lookup(var.lb, terraform.workspace)
  name   = "k8s-lb-${count.index + 1}-server-${terraform.workspace}"
  core   = lookup(var.lb_cpu, terraform.workspace)
  memory = lookup(var.lb_mem, terraform.workspace)
  disks  = [sakuracloud_disk.k8s-lb-disk[count.index].id]
  tags   = ["k8s", terraform.workspace, "@nic-double-queue"]
  network_interface {
    upstream = sakuracloud_internet.k8s_external_switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s_internal_switch.id
    user_ip_address = "192.168.100.3${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s-lb-${count.index + 1}-server-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = [sakuracloud_ssh_key_gen.gen_key.id]
    # note_ids      = ["<ID>", "<ID>"]
    ip_address = sakuracloud_internet.k8s_external_switch.ip_addresses[count.index + lookup(var.router, terraform.workspace) + lookup(var.control_plane, terraform.workspace)]
    gateway    = sakuracloud_internet.k8s_external_switch.gateway
    netmask    = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
