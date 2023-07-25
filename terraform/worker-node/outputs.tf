output "external_address_range" {
  value = "${sakuracloud_subnet.bgp-subnet.ip_addresses[0]}/${lookup(var.external_subnet, terraform.workspace)}"
}

output "k8s_router_ip_address" {
  value = sakuracloud_server.k8s-router.*.ip_address
}

output "k8s_node_server_ip_address" {
  value = sakuracloud_server.k8s-node-server.*.ip_address
}

output "k8s_lb_server_ip_address" {
  value = sakuracloud_server.k8s-lb-server.*.ip_address
}
