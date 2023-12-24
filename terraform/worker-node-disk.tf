resource "sakuracloud_disk" "k8s_worker_node_disk" {
  count             = lookup(var.worker_node, terraform.workspace, 0)
  name              = "k8s-${terraform.workspace}-worker-node-${count.index + 1}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.worker_node_disk, terraform.workspace, 0)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s_rook_disk" {
  count = lookup(var.worker_node, terraform.workspace, 0)
  name  = "k8s-${terraform.workspace}-rook-${count.index + 1}"
  size  = lookup(var.worker_node_rook_disk, terraform.workspace, 0)
  tags  = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
