resource "sakuracloud_disk" "k8s-router-disk" {
  count             = lookup(var.router, terraform.workspace)
  name              = "k8s-router-${count.index + 1}-${terraform.workspace}"
  source_archive_id = lookup(var.router_archive_id, terraform.workspace)
  size              = lookup(var.router_disk, terraform.workspace)
  tags              = ["k8s", terraform.workspace]
}
