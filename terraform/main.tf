terraform {
  required_version = ">= 0.12.5"
  required_providers {
    sakuracloud = {
      source  = "sacloud/sakuracloud"
      version = "2.25.3"
    }
  }

  backend "s3" {
    endpoints = {
      s3 = "https://s3.isk01.sakurastorage.jp"
    }
    region                      = "jp-north-1"
    key                         = "terraform.tfstate"
    skip_credentials_validation = true
    skip_requesting_account_id  = true
    skip_region_validation      = true
    skip_s3_checksum            = true
  }
}

# Configure the SakuraCloud Provider
provider "sakuracloud" {}

# ubuntu archive
data "sakuracloud_archive" "ubuntu_archive" {
  os_type = "ubuntu2204"
}

# pub key
resource "sakuracloud_ssh_key_gen" "gen_key" {
  name = "k8s-pub-key"

  provisioner "local-exec" {
    command = "echo \"${self.private_key}\" > ../id_rsa; chmod 0600 ../id_rsa"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ../id_rsa"
  }
}
