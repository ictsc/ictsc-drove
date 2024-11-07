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
  value  = "163.43.138.216"
}

resource "sakuracloud_dns_record" "root_record_ipv6" {
  dns_id = sakuracloud_dns.k8s_dns.id
  ttl    = 300
  name   = "@"
  type   = "AAAA"
  value  = "2001:e42:407:1035::2:0"
}

resource "sakuracloud_dns_record" "wildcard_record" {
  dns_id = sakuracloud_dns.k8s_dns.id
  ttl    = 300
  name   = "*"
  type   = "CNAME"
  value  = "${sakuracloud_dns.k8s_dns.zone}."
}
