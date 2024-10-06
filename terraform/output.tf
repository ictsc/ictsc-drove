output "vip_address" {
  value = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.router, terraform.workspace, 0) + lookup(var.control_plane, terraform.workspace, 0)]
}

output "external_address_range" {
  value = format("%s/%s", sakuracloud_subnet.bgp_subnet.ip_addresses[0], 28)
}

output "k8s_router_ip_address" {
  value = sakuracloud_server.k8s_router[*].ip_address
}

output "k8s_control_plane_ip_address" {
  value = sakuracloud_server.k8s_control_plane[*].ip_address
}

output "k8s_worker_node_ip_address" {
  value = sakuracloud_server.k8s_worker_node[*].ip_address
}
