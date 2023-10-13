resource "sakuracloud_switch" "k8s_internal_switch" {
  name = "k8s_internal_switch"
  timeouts {
    create = "1h"
    delete = "1h"
  }
}
