resource "sakuracloud_disk" "k8s_control_plane_disk" {
  count             = lookup(var.control_plane, terraform.workspace, 0)
  name              = "k8s-${terraform.workspace}-control-plane-${count.index + 1}"
  source_archive_id = data.sakuracloud_archive.ubuntu_archive.id
  size              = lookup(var.control_plane_disk, terraform.workspace, 0)
  tags              = ["k8s", terraform.workspace]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
