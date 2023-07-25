output "vip_address" {
  value = sakuracloud_internet.k8s-external-switch.ip_addresses[lookup(var.router, terraform.workspace) + lookup(var.master, terraform.workspace) + lookup(var.lb, terraform.workspace)]
}

output "k8s_master_server_ip_address" {
  value = sakuracloud_server.k8s-master-server.*.ip_address
}
