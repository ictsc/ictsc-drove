resource "sakuracloud_disk" "k8s_worker_node_disk" {
  count             = lookup(var.worker_node, terraform.workspace)
  name              = "k8s_worker_node_${count.index + 1}_${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.worker_node_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s_rook_disk" {
  count = lookup(var.worker_node, terraform.workspace)
  name  = "k8s_rook_${count.index + 1}_${terraform.workspace}"
  size  = lookup(var.worker_node_rook_disk, terraform.workspace)
  tags  = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
