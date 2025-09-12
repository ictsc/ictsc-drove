output "cluster_pass" {
  value     = random_password.cluster_pass.result
  sensitive = true
}

output "vip_address" {
  value = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.control_plane, terraform.workspace, 0)]
}

output "min_ip_address" {
  value = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.control_plane, terraform.workspace, 0) + 1]
}

output "max_ip_address" {
  value = sakuracloud_internet.k8s_external_switch.max_ip_address
}

output "ipv6_prefix" {
  value = sakuracloud_internet.k8s_external_switch.ipv6_prefix
}

output "ipv6_prefix_len" {
  value = sakuracloud_internet.k8s_external_switch.ipv6_prefix_len
}

output "k8s_control_plane_ip_address" {
  value = sakuracloud_server.k8s_control_plane[*].ip_address
}

output "k8s_worker_node_ip_address" {
  value = sakuracloud_server.k8s_worker_node[*].ip_address
}

output "k8s_dns_zone" {
  value = sakuracloud_dns.k8s_dns.zone
}

output "k8s_dns_nameservers" {
  value = sakuracloud_dns.k8s_dns.dns_servers
}
