# disk size plan: https://cloud.sakura.ad.jp/specification/server-disk/#server-disk-content02-price
variable "cluster_pass" {
  type    = string
  default = ""
}
variable "external_subnet" {
  type = map(any)
  default = {
    wsp = 28
    dev = 28
    prd = 28
  }
}
variable "master" {
  type = map(any)
  default = {
    wsp = 3
    dev = 3
    prd = 3
  }
}
variable "master_cpu" {
  type = map(any)
  default = {
    wsp = 4
    dev = 4
    prd = 4
  }
}
variable "master_mem" {
  type = map(any)
  default = {
    wsp = 8
    dev = 8
    prd = 8
  }
}
variable "master_disk" {
  type = map(any)
  default = {
    wsp = 40
    dev = 40
    prd = 40
  }
}

variable "node" {
  type = map(any)
  default = {
    wsp = 3
    dev = 3
    prd = 3
  }
}
variable "node_cpu" {
  type = map(any)
  default = {
    wsp = 4
    dev = 4
    prd = 4
  }
}
variable "node_mem" {
  type = map(any)
  default = {
    wsp = 16
    dev = 8
    prd = 16
  }
}
variable "node_disk" {
  type = map(any)
  default = {
    wsp = 40
    dev = 40
    prd = 40
  }
}

variable "node_rook_disk" {
  type = map(any)
  default = {
    wsp = 100
    dev = 40
    prd = 100
  }
}

variable "lb" {
  type = map(any)
  default = {
    wsp = 2
    dev = 2
    prd = 2
  }
}
variable "lb_cpu" {
  type = map(any)
  default = {
    wsp = 2
    dev = 2
    prd = 2
  }
}
variable "lb_mem" {
  type = map(any)
  default = {
    wsp = 2
    dev = 2
    prd = 2
  }
}
variable "lb_disk" {
  type = map(any)
  default = {
    wsp = 20
    dev = 20
    prd = 20
  }
}

variable "router" {
  type = map(any)
  default = {
    wsp = "1"
    dev = "1"
    prd = "1"
    bgp = "1"
  }
}

variable "router_cpu" {
  type = map(any)
  default = {
    wsp = "2"
    dev = "2"
    prd = "2"
  }
}
variable "router_mem" {
  type = map(any)
  default = {
    wsp = "2"
    dev = "2"
    prd = "2"
  }
}
variable "router_disk" {
  type = map(any)
  default = {
    wsp = "20"
    dev = "20"
    prd = "20"
  }
}
