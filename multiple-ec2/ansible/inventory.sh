#!/bin/bash
ANSIBLE_DIR="$(dirname "$(realpath "$0")")"
TERRAFORM_DIR="$(dirname "$ANSIBLE_DIR")"

cd "$TERRAFORM_DIR"

SSH_USER=$(terraform output -raw ssh_user)
KEY_PATH="$TERRAFORM_DIR/$(terraform output -raw key_name).pem"
IPS=$(terraform output -json public_ips | jq '[.[]]')

cat <<EOF
{
  "_meta": {
    "hostvars": {}
  },
  "webservers": {
    "hosts": $IPS,
    "vars": {
      "ansible_user": "$SSH_USER",
      "ansible_ssh_private_key_file": "$KEY_PATH",
      "ansible_ssh_common_args": "-o StrictHostKeyChecking=no"
    }
  }
}
EOF