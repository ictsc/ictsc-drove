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

resource "sakuracloud_dns_record" "root_record_ipv4" {
  dns_id = sakuracloud_dns.k8s_dns.id
  ttl    = 300
  name   = "@"
  type   = "A"
  value  = sakuracloud_internet.k8s_external_switch.ip_addresses[lookup(var.control_plane, terraform.workspace, 0) + 1]
}

resource "sakuracloud_dns_record" "root_record_ipv6" {
  dns_id = sakuracloud_dns.k8s_dns.id
  ttl    = 300
  name   = "@"
  type   = "AAAA"
  value  = sakuracloud_internet.k8s_external_switch.ipv6_prefix + "2:0"
}

resource "sakuracloud_dns_record" "wildcard_record" {
  depends_on = [sakuracloud_dns_record.root_record_ipv4]
  dns_id     = sakuracloud_dns.k8s_dns.id
  ttl        = 300
  name       = "*"
  type       = "CNAME"
  value      = "${sakuracloud_dns.k8s_dns.zone}."
}
