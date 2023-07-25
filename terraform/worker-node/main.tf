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
