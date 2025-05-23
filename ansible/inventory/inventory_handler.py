#!/usr/bin/env python
# -*- coding:utf-8 -*-

import json
import os
import subprocess

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
        "all": {},
        "control_plane": {"hosts": []},
        "worker_node": {"hosts": []},
        "_meta": {"hostvars": {}},
    }
    workspace = get_workspace()
    tfstate = fetch_tfstate(workspace)

    # Uncomment below to see the tfstate object
    #
    # print(tfstate["outputs"])

    control_plane = 0
    worker_node = 0
    inventory_gp = {}

    # 利便性のため、IPv6プレフィックスに付いている一番後ろの「::」を削除
    # 例: 2001:db8:407:1013:: -> 2001:db8:407:1013
    ipv6_prefix = tfstate["outputs"]["ipv6_prefix"]["value"][:-2]

    for output_key in tfstate["outputs"]:
        match output_key:
            case "k8s_control_plane_ip_address":
                inventory_gp = inventory["control_plane"]
            case "k8s_worker_node_ip_address":
                inventory_gp = inventory["worker_node"]
            case _:
                continue

        for ip_address in tfstate["outputs"][output_key]["value"]:
            # not handle private ip address
            if (
                ip_address[:7] == "192.168"
                and output_key == "k8s_control_plane_ip_address"
            ):
                continue

            inventory_gp["hosts"].append(ip_address)

            match output_key:
                case "k8s_control_plane_ip_address":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip_address: {
                            "ipv6": f"{ipv6_prefix}::{format(control_plane + 4, 'x')}",
                            "internal_ip": f"192.168.100.{str(control_plane + 1)}",
                            "internal_ipv6": f"{ipv6_prefix}:1::{format(control_plane + 1, 'x')}",
                        }
                    }
                    control_plane += 1
                case "k8s_worker_node_ip_address":
                    inventory["_meta"]["hostvars"] = inventory["_meta"]["hostvars"] | {
                        ip_address: {
                            "internal_ip": f"192.168.100.{str(worker_node + 101)}",
                            "internal_ipv6": f"{ipv6_prefix}:1::{format(worker_node + 101, 'x')}",
                        }
                    }
                    worker_node += 1

    inventory["all"]["vars"] = {
        "ipv6_prefix": ipv6_prefix,
        "ipv6_prefix_len": tfstate["outputs"]["ipv6_prefix_len"]["value"],
    }
    inventory["control_plane"]["vars"] = {
        "VIP": tfstate["outputs"]["vip_address"]["value"],
    }
    inventory["delegate_plane"] = {
        "hosts": [inventory["control_plane"]["hosts"][0]],
        "vars": {
            "workspace": workspace,
            "min_ip_address": tfstate["outputs"]["min_ip_address"]["value"],
            "max_ip_address": tfstate["outputs"]["max_ip_address"]["value"],
            "dns_zone": tfstate["outputs"]["k8s_dns_zone"]["value"],
            "oidc_issuer_url": (
                "https://dex.drove.ictsc.net"
                if workspace == "prod"
                else "https://dex.drove-dev.ictsc.net"
            ),
        },
    }

    # SSH鍵が存在するかによって、認証情報を分ける
    #  Terraformによって作られたSSH鍵が存在しない場合、ictscユーザーに切り替えて
    #  GitHubに登録されているそれぞれのメンバーの公開鍵で認証するようにする
    if os.path.isfile(f"../id_rsa_{workspace}"):
        inventory["all"]["vars"] |= {
            "ansible_user": "ubuntu",
            "ansible_sudo_pass": os.environ.get("CLUSTER_PASS"),
            "ansible_ssh_private_key_file": f"../id_rsa_{workspace}",
        }
        inventory["worker_node"]["vars"] = {
            "ansible_ssh_common_args": (
                "-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
                f"-i ../id_rsa_{workspace} -W %h:%p ubuntu@{inventory['control_plane']['hosts'][0]}'"
            )
        }
    else:
        inventory["all"]["vars"] |= {
            "ansible_user": "ictsc",
        }
        inventory["worker_node"]["vars"] = {
            "ansible_ssh_common_args": (
                "-o ProxyCommand='ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "
                f"-W %h:%p ictsc@{inventory['control_plane']['hosts'][0]}'"
            )
        }

    print(json.dumps(inventory))


if __name__ == "__main__":
    main()
