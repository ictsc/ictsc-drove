terraform {
  required_version = ">= 0.12.5"
  required_providers {
    sakuracloud = {
      source  = "sacloud/sakuracloud"
      version = "2.22.0"
    }
  }

  backend "s3" {
    endpoint                    = "s3.isk01.sakurastorage.jp"
    region                      = "jp-north-1"
    bucket                      = "ictsc-k8s-cluster"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_region_validation      = true
  }
}

# Configure the SakuraCloud Provider
provider "sakuracloud" {
}

# ubuntu archive
data "sakuracloud_archive" "ubuntu-archive" {
  os_type = "ubuntu2204"
}

# pub key
resource "sakuracloud_ssh_key_gen" "gen_key" {
  name = "k8s_pub_key"

  provisioner "local-exec" {
    command = "echo \"${self.private_key}\" > ../id_rsa; chmod 0600 ../id_rsa"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ../id_rsa"
  }
}

resource "sakuracloud_internet" "k8s-external-switch" {
  name       = "k8s-external-switch"
  netmask    = lookup(var.external_subnet, terraform.workspace)
  band_width = 100
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_subnet" "bgp-subnet" {
  internet_id = sakuracloud_internet.k8s-external-switch.id
  next_hop    = sakuracloud_internet.k8s-external-switch.ip_addresses[length(sakuracloud_internet.k8s-external-switch.ip_addresses) - 11]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_switch" "k8s-internal-switch" {
  name = "k8s-internal-switch"
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

# disks
resource "sakuracloud_disk" "k8s-router-disk" {
  count             = lookup(var.router, terraform.workspace)
  name              = "k8s-router-${count.index + 1}-${terraform.workspace}"
  source_archive_id = lookup(var.router_archive_id, terraform.workspace)
  size              = lookup(var.router_disk, terraform.workspace)
  tags              = ["k8s", "${terraform.workspace}"]
}

resource "sakuracloud_disk" "k8s-master-disk" {
  count             = lookup(var.master, terraform.workspace)
  name              = "k8s-master-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu-archive.id
  size              = lookup(var.master_disk, terraform.workspace)
  tags              = ["k8s", "${terraform.workspace}"]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s-node-disk" {
  count             = lookup(var.node, terraform.workspace)
  name              = "k8s-node-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu-archive.id
  size              = lookup(var.node_disk, terraform.workspace)
  tags              = ["k8s", "${terraform.workspace}"]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s-rook-disk" {
  count = lookup(var.node, terraform.workspace)
  name  = "k8s-rook-${count.index + 1}-${terraform.workspace}"
  size  = lookup(var.node_rook_disk, terraform.workspace)
  tags  = ["k8s", "${terraform.workspace}"]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_disk" "k8s-lb-disk" {
  count             = lookup(var.lb, terraform.workspace)
  name              = "k8s-lb-${count.index + 1}-${terraform.workspace}"
  source_archive_id = data.sakuracloud_archive.ubuntu-archive.id
  size              = lookup(var.lb_disk, terraform.workspace)
  tags              = ["k8s", "${terraform.workspace}"]
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

# servers
resource "sakuracloud_server" "k8s-router" {
  count  = lookup(var.router, terraform.workspace)
  name   = "k8s-router-${count.index + 1}-${terraform.workspace}"
  core   = lookup(var.router_cpu, terraform.workspace)
  memory = lookup(var.router_mem, terraform.workspace)
  disks  = ["${sakuracloud_disk.k8s-router-disk[count.index].id}"]
  tags   = ["k8s", "${terraform.workspace}", "@nic-double-queue"]

  network_interface {
    upstream = sakuracloud_internet.k8s-external-switch.switch_id
  }

  disk_edit_parameter {
    hostname        = "k8s-router-${count.index + 1}-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "false"
    ip_address      = sakuracloud_internet.k8s-external-switch.ip_addresses[count.index]
    gateway         = sakuracloud_internet.k8s-external-switch.gateway
    netmask         = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_server" "k8s-master-server" {
  count  = lookup(var.master, terraform.workspace)
  name   = "k8s-master-${count.index + 1}-server-${terraform.workspace}"
  core   = lookup(var.master_cpu, terraform.workspace)
  memory = lookup(var.master_mem, terraform.workspace)
  disks  = ["${sakuracloud_disk.k8s-master-disk[count.index].id}"]
  tags   = ["k8s", "${terraform.workspace}", "@nic-double-queue"]

  network_interface {
    upstream = sakuracloud_internet.k8s-external-switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s-internal-switch.id
    user_ip_address = "192.168.100.1${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s-master-${count.index + 1}-server-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = ["${sakuracloud_ssh_key_gen.gen_key.id}"]
    ip_address      = sakuracloud_internet.k8s-external-switch.ip_addresses[count.index + lookup(var.router, terraform.workspace)]
    gateway         = sakuracloud_internet.k8s-external-switch.gateway
    netmask         = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_server" "k8s-node-server" {
  count  = lookup(var.node, terraform.workspace)
  name   = "k8s-node-${count.index + 1}-server-${terraform.workspace}"
  core   = lookup(var.node_cpu, terraform.workspace)
  memory = lookup(var.node_mem, terraform.workspace)
  disks  = ["${sakuracloud_disk.k8s-node-disk[count.index].id}", "${sakuracloud_disk.k8s-rook-disk[count.index].id}"]
  tags   = ["k8s", "${terraform.workspace}", "@nic-double-queue"]
  network_interface {
    upstream = sakuracloud_internet.k8s-external-switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s-internal-switch.id
    user_ip_address = "192.168.100.2${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s-node-${count.index + 1}-server-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = ["${sakuracloud_ssh_key_gen.gen_key.id}"]
    # note_ids        = ["<ID>", "<ID>"]
    ip_address = sakuracloud_internet.k8s-external-switch.ip_addresses[count.index + length(sakuracloud_internet.k8s-external-switch.ip_addresses) - 4]
    gateway    = sakuracloud_internet.k8s-external-switch.gateway
    netmask    = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

resource "sakuracloud_server" "k8s-lb-server" {
  count  = lookup(var.lb, terraform.workspace)
  name   = "k8s-lb-${count.index + 1}-server-${terraform.workspace}"
  core   = lookup(var.lb_cpu, terraform.workspace)
  memory = lookup(var.lb_mem, terraform.workspace)
  disks  = ["${sakuracloud_disk.k8s-lb-disk[count.index].id}"]
  tags   = ["k8s", "${terraform.workspace}", "@nic-double-queue"]
  network_interface {
    upstream = sakuracloud_internet.k8s-external-switch.switch_id
  }
  network_interface {
    upstream        = sakuracloud_switch.k8s-internal-switch.id
    user_ip_address = "192.168.100.3${count.index}"
  }
  disk_edit_parameter {
    hostname        = "k8s-lb-${count.index + 1}-server-${terraform.workspace}"
    password        = var.cluster_pass
    disable_pw_auth = "true"
    ssh_key_ids     = ["${sakuracloud_ssh_key_gen.gen_key.id}"]
    # note_ids      = ["<ID>", "<ID>"]
    ip_address = sakuracloud_internet.k8s-external-switch.ip_addresses[count.index + lookup(var.router, terraform.workspace) + lookup(var.master, terraform.workspace)]
    gateway    = sakuracloud_internet.k8s-external-switch.gateway
    netmask    = lookup(var.external_subnet, terraform.workspace)
  }
  timeouts {
    create = "1h"
    delete = "1h"
  }
}

# output
output "show_workspaces" {
  value = terraform.workspace
}

output "vip_address" {
  value = sakuracloud_internet.k8s-external-switch.ip_addresses[lookup(var.router, terraform.workspace) + lookup(var.master, terraform.workspace) + lookup(var.lb, terraform.workspace)]
}

output "metallb_address_range" {
  value = "${sakuracloud_subnet.bgp-subnet.ip_addresses[0]}/${lookup(var.external_subnet, terraform.workspace)}"
}

output "k8s_router_ipaddress" {
  value = sakuracloud_server.k8s-router.*.ip_address
}

output "k8s_bgp_router_ipaddress" {
  value = sakuracloud_server.k8s-router.*.ip_address
}

output "k8s_master_server_ipaddress" {
  value = sakuracloud_server.k8s-master-server.*.ip_address
}

output "k8s_node_server_ipaddress" {
  value = sakuracloud_server.k8s-node-server.*.ip_address
}

output "k8s_lb_server_ipaddress" {
  value = sakuracloud_server.k8s-lb-server.*.ip_address
}

output "public_address_list" {
  value = sakuracloud_internet.k8s-external-switch.ip_addresses
}
