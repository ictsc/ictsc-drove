resource "sakuracloud_server" "k8s_worker_node" {
  count  = lookup(var.worker_node, terraform.workspace, 0)
  name   = "k8s-${terraform.workspace}-worker-node-${count.index + 1}"
  core   = lookup(var.worker_node_cpu, terraform.workspace, 0)
  memory = lookup(var.worker_node_mem, terraform.workspace, 0)
  disks  = [sakuracloud_disk.k8s_worker_node_disk[count.index].id, sakuracloud_disk.k8s_rook_disk[count.index].id]
  tags   = ["k8s", terraform.workspace]

  network_interface {
    upstream        = sakuracloud_switch.k8s_internal_switch.id
    user_ip_address = "192.168.100.${count.index + 101}"
  }
  disk_edit_parameter {
    hostname        = "k8s-${terraform.workspace}-worker-node-${count.index + 1}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_keys        = [data.local_file.ssh-key.content]
    ip_address      = "192.168.100.${count.index + 101}"
    gateway         = "192.168.100.254"
    netmask         = 24
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
