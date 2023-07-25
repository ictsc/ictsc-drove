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

# Load the control-plane module
module "control-plane" {
  source = "./control-plane"
}

# Load the worker-node module
module "worker-node" {
  source = "./worker-node"
}
