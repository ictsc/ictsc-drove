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

# Configure the SakuraCloud Provider
provider "sakuracloud" {
}

# Load the control-plane module
module "control-plane" {
  source = "./control-plane"
}

# Load the worker-node module
module "worker-node" {
  source = "./worker-node"
}

# Load the network module
module "network" {
  source = "./network"
}

# Load the router module
module "router" {
  source = "./router"
}

# Load the load-balancer module
module "lb" {
  source = "./lb"
}
