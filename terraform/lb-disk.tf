resource "sakuracloud_disk" "k8s-lb-disk" {
  count             = lookup(var.lb, terraform.workspace)
  name              = "k8s-lb-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu-archive.id
  size              = lookup(var.lb_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
