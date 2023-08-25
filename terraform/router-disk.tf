resource "sakuracloud_disk" "k8s-router-disk" {
  count             = lookup(var.router, terraform.workspace)
  name              = "k8s-router-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.debian-archive.id
  size              = lookup(var.router_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
