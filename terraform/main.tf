terraform {
  required_version = "> 1.9.0"

  required_providers {
    sakuracloud = {
      source  = "sacloud/sakuracloud"
      version = "2.29.1"
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

provider "sakuracloud" {}

data "sakuracloud_archive" "ubuntu_archive" {
  os_type = "ubuntu2204"
}

resource "sakuracloud_ssh_key_gen" "gen_key" {
  name = "k8s-pub-key"

  provisioner "local-exec" {
    command = "echo \"${self.private_key}\" > ../id_rsa_${terraform.workspace}; chmod 0600 ../id_rsa_${terraform.workspace}"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f ../id_rsa_${terraform.workspace}"
  }
}
