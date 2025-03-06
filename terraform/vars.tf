# disk size plan: https://cloud.sakura.ad.jp/specification/server-disk/#server-disk-content02-price
variable "cluster_pass" {
  type    = string
  default = ""
}
variable "external_subnet" {
  type = map(any)
  default = {
    dev  = 28
    prod = 28
  }
}

variable "control_plane" {
  type = map(any)
  default = {
    dev  = 3
    prod = 3
  }
}
variable "control_plane_cpu" {
  type = map(any)
  default = {
    dev  = 2
    prod = 2
  }
}
variable "control_plane_mem" {
  type = map(any)
  default = {
    dev  = 4
    prod = 4
  }
}
variable "control_plane_disk" {
  type = map(any)
  default = {
    dev  = 20
    prod = 20
  }
}

variable "worker_node" {
  type = map(any)
  default = {
    dev  = 8
    prod = 8
  }
}
variable "worker_node_cpu" {
  type = map(any)
  default = {
    dev  = 2
    prod = 4
  }
}
variable "worker_node_mem" {
  type = map(any)
  default = {
    dev  = 4
    prod = 8
  }
}
variable "worker_node_disk" {
  type = map(any)
  default = {
    dev  = 40
    prod = 40
  }
}
variable "worker_node_rook_disk" {
  type = map(any)
  default = {
    dev  = 20
    prod = 20
  }
}
