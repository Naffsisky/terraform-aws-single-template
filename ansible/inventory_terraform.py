#!/usr/bin/env python3

import json
import os
import subprocess
import sys
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parent.parent
SSH_KEY_PATH = Path.home() / ".ssh" / "terraform-aws-key.pem"


def terraform_output(workspace=None):
    """Baca terraform output. Jika workspace diberikan, select dulu."""
    env = os.environ.copy()
    if workspace:
        env["TF_WORKSPACE"] = workspace

    try:
        result = subprocess.run(
            ["terraform", "output", "-json"],
            cwd=PROJECT_ROOT,
            capture_output=True,
            text=True,
            check=True,
            env=env,
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


# Cek apakah workspace diberikan via env variable atau argument
workspace = os.environ.get("TF_WORKSPACE")
if len(sys.argv) > 1 and sys.argv[1] == "--list":
    pass  # Normal mode, lanjut
elif len(sys.argv) > 2 and sys.argv[1] == "--workspace":
    workspace = sys.argv[2]

outputs = terraform_output(workspace)

public_ip = get_output(outputs, "public_ip")
ssh_user = get_output(outputs, "ssh_user", "ubuntu")

if not public_ip:
    print("Output Terraform 'public_ip' tidak ditemukan.", file=sys.stderr)
    sys.exit(1)

# Gunakan SSH key dari lokasi terpusat
key_path = SSH_KEY_PATH.resolve()

if not key_path.exists():
    print(f"WARNING: SSH key tidak ditemukan di: {key_path}", file=sys.stderr)
    print("Jalankan setup.sh untuk generate SSH key.", file=sys.stderr)

# Nama host berdasarkan workspace
workspace_name = get_output(outputs, "workspace_name", "default")
host_alias = f"terraform-{workspace_name}"

inventory = {
    "_meta": {
        "hostvars": {
            host_alias: {
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
        "hosts": [host_alias]
    }
}

print(json.dumps(inventory, indent=2))
