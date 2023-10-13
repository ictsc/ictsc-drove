resource "sakuracloud_disk" "k8s_lb_disk" {
  count             = lookup(var.lb, terraform.workspace)
  name              = "k8s_lb_${count.index + 1}_${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.lb_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
