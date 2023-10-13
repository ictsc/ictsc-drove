resource "sakuracloud_disk" "k8s_router_disk" {
  count             = lookup(var.router, terraform.workspace)
  name              = "k8s_router_${count.index + 1}_${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.router_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
