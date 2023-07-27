resource "sakuracloud_disk" "k8s-master-disk" {
  count             = lookup(var.master, terraform.workspace)
  name              = "k8s-master-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu-archive.id
  size              = lookup(var.master_disk, terraform.workspace)
  tags              = ["k8s", "${terraform.workspace}"]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
