#!/usr/bin/env python
# -*- coding:utf-8 -*-

import os
import subprocess
import json
from minio import Minio  # type: ignore


def fetch_tfstate(wsp: str):
    m_client = Minio(
        "s3.isk01.sakurastorage.jp",
        access_key=os.environ.get("TF_STATE_ACCESS_KEY"),
        secret_key=os.environ.get("TF_STATE_SECRET_KEY"),
        secure=True,
    )

    response = m_client.get_object(
        "ictsc-k8s-cluster",
        f"env:/{wsp}/terraform.tfstate",
    )

    return json.loads(response.read())


def get_wsp():
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
    hosts = fetch_tfstate(get_wsp())

    # Uncomment below to see the tfstate object
    #
    # import pprint
    # print(hosts["outputs"])

    inventory_gp = {}
    for host_name in hosts["outputs"]:
        if host_name == "public_address_list":
            continue

        if host_name == "k8s_lb_server_ipaddress":
            inventory["lb_server"] = {"hosts": []}
            inventory_gp = inventory["lb_server"]
        elif host_name == "k8s_master_server_ipaddress":
            inventory["master_server"] = {"hosts": []}
            inventory_gp = inventory["master_server"]
        elif host_name == "k8s_node_server_ipaddress":
            inventory["node_server"] = {"hosts": []}
            inventory_gp = inventory["node_server"]

        ip_addresses = hosts["outputs"][host_name]["value"]
        node = 0
        master = 0

        for ip in ip_addresses:
            # inventory filter list
            # private reject
            if (
                ip[:11] == "192.168.100"
                or host_name == "show_workspaces"
                or host_name == "vip_address"
            ):
                continue

            inventory_gp["hosts"].append(ip)
            if host_name == "k8s_master_server_ipaddress":
                inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                    ip: {"internal_ip": f"192.168.100.1{str(master)}"}
                }
                master += 1
            elif host_name == "k8s_node_server_ipaddress":
                inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                    ip: {"internal_ip": f"192.168.100.2{str(node)}"}
                }
                node += 1
            elif host_name == "k8s_router_ipaddress":
                continue

        if host_name == "k8s_lb_server_ipaddress":
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
    inventory["delegate_server"] = {"hosts": [inventory["master_server"]["hosts"][0]]}

    print(json.dumps(inventory))


if __name__ == "__main__":
    main()
