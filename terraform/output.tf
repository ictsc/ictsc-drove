output "vip_address" {
  value = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.router, terraform.workspace) + lookup(var.master, terraform.workspace) + lookup(var.lb, terraform.workspace)]
}

output "external_address_range" {
  value = format("%s/%s", sakuracloud_subnet.bgp_subnet.ip_addresses[0], lookup(var.external_subnet, terraform.workspace))
}

output "k8s_router_ip_address" {
  value = sakuracloud_server.k8s-router[*].ip_address
}

output "k8s_master_server_ip_address" {
  value = sakuracloud_server.k8s-master-server[*].ip_address
}

output "k8s_node_server_ip_address" {
  value = sakuracloud_server.k8s-node-server[*].ip_address
}

output "k8s_lb_server_ip_address" {
  value = sakuracloud_server.k8s-lb-server[*].ip_address
}
