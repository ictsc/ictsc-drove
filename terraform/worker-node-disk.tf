resource "sakuracloud_disk" "k8s-node-disk" {
  count             = lookup(var.node, terraform.workspace)
  name              = "k8s-node-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.node_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s-rook-disk" {
  count = lookup(var.node, terraform.workspace)
  name  = "k8s-rook-${count.index + 1}-${terraform.workspace}"
  size  = lookup(var.node_rook_disk, terraform.workspace)
  tags  = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
