#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
import subprocess
import json
from minio import Minio  # type: ignore


def fetch_tfstate(workspace: str):
    m_client = Minio(
        "s3.isk01.sakurastorage.jp",
        access_key=os.environ.get("TF_STATE_ACCESS_KEY"),
        secret_key=os.environ.get("TF_STATE_SECRET_KEY"),
        secure=True,
    )

    response = m_client.get_object(
        "ictsc-drove",
        f"env:/{workspace}/terraform.tfstate",
    )

    return json.loads(response.read())


def get_workspace():
    cmd = "terraform workspace show"
    working_dir = f"{os.path.dirname(__file__)}/../../terraform"

    return (
        subprocess.Popen(cmd, cwd=working_dir, stdout=subprocess.PIPE, shell=True)
        .communicate()[0]
        .decode("utf-8")
        .strip()
    )


def main():
    inventory = {
        "cloud_servers": {"children": ["control_plane", "lb", "worker_node"]},
        "_meta": {"hostvars": {}},
    }
    workspace = get_workspace()
    tfstate = fetch_tfstate(workspace)

    # Uncomment below to see the tfstate object
    #
    # import pprint
    # print(tfstate["outputs"])

    inventory_gp = {}
    for output_key in tfstate["outputs"]:
        match output_key:
            case "k8s_lb_ip_address":
                inventory["lb"] = {"hosts": []}
                inventory_gp = inventory["lb"]
            case "k8s_control_plane_ip_address":
                inventory["control_plane"] = {"hosts": []}
                inventory_gp = inventory["control_plane"]
            case "k8s_worker_node_ip_address":
                inventory["worker_node"] = {"hosts": []}
                inventory_gp = inventory["worker_node"]
            case "k8s_router_ip_address":
                inventory["bgp_router"] = {"hosts": []}
                inventory_gp = inventory["bgp_router"]
            case _:
                continue

        ip_addresses = tfstate["outputs"][output_key]["value"]
        worker_node = 0
        control_plane = 0

        for ip in ip_addresses:
            # inventory filter list
            # private reject
            if ip[:11] == "192.168.100":
                continue

            inventory_gp["hosts"].append(ip)

            match output_key:
                case "k8s_control_plane_ip_address":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip: {"internal_ip": f"192.168.100.1{str(control_plane)}"}
                    }
                    control_plane += 1
                case "k8s_worker_node_ip_address":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip: {"internal_ip": f"192.168.100.2{str(worker_node)}"}
                    }
                    worker_node += 1

        if output_key == "k8s_lb_ip_address":
            inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                inventory_gp["hosts"][0]: {
                    "opposite": inventory_gp["hosts"][1],
                    "priority": "150",
                    "state": "Master",
                    "internal_ip": "192.168.100.31",
                },
                inventory_gp["hosts"][1]: {
                    "opposite": inventory_gp["hosts"][0],
                    "priority": "101",
                    "state": "BACKUP",
                    "internal_ip": "192.168.100.32",
                },
            }

    inventory["lb"]["vars"] = {  # type: ignore
        "VIP": tfstate["outputs"]["vip_address"]["value"]
    }
    inventory["bgp_router"]["vars"] = {  # type: ignore
        "bgp_address": tfstate["outputs"]["external_address_range"]["value"]
    }
    inventory["delegate_plane"] = {
        "hosts": [inventory["control_plane"]["hosts"][0]],
        "vars": {"workspace": workspace},
    }

    print(json.dumps(inventory))


if __name__ == "__main__":
    main()
