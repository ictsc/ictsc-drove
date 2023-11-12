resource "sakuracloud_disk" "k8s_lb_disk" {
  count             = lookup(var.lb, terraform.workspace, 0)
  name              = "k8s-lb-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.lb_disk, terraform.workspace, 0)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
