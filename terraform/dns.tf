resource "sakuracloud_dns" "k8s_dns" {
  zone = "drove-${terraform.workspace}.ictsc.net"
}

resource "sakuracloud_dns_record" "k8s_apiserver_record" {
  dns_id = sakuracloud_dns.k8s_dns.id
  ttl    = 300
  name   = "k8s"
  type   = "A"
  value  = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.control_plane, terraform.workspace, 0)]
}
