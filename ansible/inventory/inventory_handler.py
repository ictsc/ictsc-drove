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
        "ictsc-k8s-cluster",
        f"env:/{workspace}/terraform.tfstate",
    )

    return json.loads(response.read())


def get_workspace():
    cmd = "terraform workspace show"
    working_dir = "../../terraform"

    return (
        subprocess.Popen(cmd, cwd=working_dir, stdout=subprocess.PIPE, shell=True)
        .communicate()[0]
        .decode("utf-8")
        .strip()
    )


def main():
    inventory = {
        "cloud_servers": {"children": ["master_server", "lb_server", "node_server"]},
        "_meta": {},
    }
    workspace = get_workspace()
    hosts = fetch_tfstate(workspace)

    # Uncomment below to see the tfstate object
    #
    # import pprint
    # print(hosts["outputs"])

    inventory_gp = {}
    for output_key in hosts["outputs"]:
        match output_key:
            case "k8s_lb_server_ipaddress":
                inventory["lb_server"] = {"hosts": []}
                inventory_gp = inventory["lb_server"]
            case "k8s_master_server_ipaddress":
                inventory["master_server"] = {"hosts": []}
                inventory_gp = inventory["master_server"]
            case "k8s_node_server_ipaddress":
                inventory["node_server"] = {"hosts": []}
                inventory_gp = inventory["node_server"]
            case "k8s_router_ipaddress":
                inventory["bgp_router"] = {"hosts": []}
                inventory_gp = inventory["bgp_router"]
            case _:
                continue

        ip_addresses = hosts["outputs"][output_key]["value"]
        node = 0
        master = 0

        for ip in ip_addresses:
            # inventory filter list
            # private reject
            if ip[:11] == "192.168.100":
                continue

            inventory_gp["hosts"].append(ip)

            match output_key:
                case "k8s_master_server_ipaddress":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip: {"internal_ip": f"192.168.100.1{str(master)}"}
                    }
                    master += 1
                case "k8s_node_server_ipaddress":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip: {"internal_ip": f"192.168.100.2{str(node)}"}
                    }
                    node += 1

        if output_key == "k8s_lb_server_ipaddress":
            inventory["_meta"] = inventory["_meta"] | {
                "hostvars": {
                    inventory_gp["hosts"][0]: {
                        "opposite": inventory_gp["hosts"][1],
                        "priority": "150",
                        "state": "MASTER",
                        "internal_ip": "192.168.100.31",
                    },
                    inventory_gp["hosts"][1]: {
                        "opposite": inventory_gp["hosts"][0],
                        "priority": "101",
                        "state": "BACKUP",
                        "internal_ip": "192.168.100.32",
                    },
                }
            }

    inventory["lb_server"]["vars"] = {  # type: ignore
        "VIP": hosts["outputs"]["vip_address"]["value"]
    }
    inventory["bgp_router"]["vars"] = {  # type: ignore
        "bgp-address": hosts["outputs"]["external_address_range"]["value"]
    }
    inventory["delegate_server"] = {
        "hosts": [inventory["master_server"]["hosts"][0]],
        "vars": {"workspace": workspace},
    }

    print(json.dumps(inventory))


if __name__ == "__main__":
    main()
