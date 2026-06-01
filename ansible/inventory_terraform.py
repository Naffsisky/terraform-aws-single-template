#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent


def terraform_output():
    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True,
        )
        return json.loads(result.stdout)
    except subprocess.CalledProcessError as e:
        print("Gagal membaca terraform output.", file=sys.stderr)
        print(e.stderr, file=sys.stderr)
        sys.exit(1)


def get_output(outputs, key, default=None):
    item = outputs.get(key)
    if not item:
        return default
    return item.get("value", default)


outputs = terraform_output()

public_ip = get_output(outputs, "public_ip")
private_key_path = get_output(outputs, "private_key_path")
ssh_command = get_output(outputs, "ssh_command", "")

if not public_ip:
    print("Output Terraform 'public_ip' tidak ditemukan.", file=sys.stderr)
    sys.exit(1)

if not private_key_path:
    print("Output Terraform 'private_key_path' tidak ditemukan.", file=sys.stderr)
    sys.exit(1)

# Ambil user dari ssh_command Terraform
# contoh: ssh -i ./ubuntu-lab-key.pem ubuntu@16.78.102.61
ssh_user = "ubuntu"
if " admin@" in ssh_command:
    ssh_user = "admin"
elif " ubuntu@" in ssh_command:
    ssh_user = "ubuntu"

key_path = Path(private_key_path).expanduser()

if not key_path.is_absolute():
    key_path = PROJECT_ROOT / key_path

key_path = key_path.resolve()

inventory = {
    "_meta": {
        "hostvars": {
            "k3s-main": {
                "ansible_host": public_ip,
                "ansible_user": ssh_user,
                "ansible_ssh_private_key_file": str(key_path),
                "ansible_python_interpreter": "/usr/bin/python3",
            }
        }
    },
    "all": {
        "children": ["k3s_servers"]
    },
    "k3s_servers": {
        "hosts": ["k3s-main"]
    }
}

print(json.dumps(inventory, indent=2))
