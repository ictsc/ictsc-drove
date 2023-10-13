resource "sakuracloud_disk" "k8s_control_plane_disk" {
  count             = lookup(var.control_plane, terraform.workspace)
  name              = "k8s-control-plane-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.control_plane_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
