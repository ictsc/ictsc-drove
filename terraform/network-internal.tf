resource "sakuracloud_switch" "k8s-internal-switch" {
  name = "k8s-internal-switch"
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
