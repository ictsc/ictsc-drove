terraform {
  required_version = "1.13.4"

  required_providers {
    sakuracloud = {
      source  = "sacloud/sakuracloud"
      version = "2.31.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "3.2.4"
    }
    local = {
      source  = "hashicorp/local"
      version = "2.5.3"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.2"
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

data "sakuracloud_archive" "ubuntu_archive" {
  os_type = "ubuntu2204"
}

resource "null_resource" "ssh-key" {
  provisioner "local-exec" {
    command = "cd ../dev && if [ ! -e keys ]; then chmod +x keys.sh; ./keys.sh; fi"
  }
}

data "local_file" "ssh-key" {
  filename   = "../dev/keys"
  depends_on = [null_resource.ssh-key]
}

resource "random_password" "cluster_pass" {
  length = 64
}
