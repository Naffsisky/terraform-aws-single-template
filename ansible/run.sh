#!/bin/bash
set -e

ANSIBLE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$ANSIBLE_DIR/.." && pwd)"

cd "$ANSIBLE_DIR"

echo "==============================================="
echo "        RUNNING ANSIBLE K3S SETUP"
echo "==============================================="

echo "[1/4] Fix SSH key permission..."

RAW_KEY_PATH=$(cd "$PROJECT_ROOT" && terraform output -raw private_key_path)

if [[ "$RAW_KEY_PATH" = /* ]]; then
  KEY_PATH="$RAW_KEY_PATH"
else
  KEY_PATH="$PROJECT_ROOT/$RAW_KEY_PATH"
fi

echo "SSH key path: $KEY_PATH"

if [ ! -f "$KEY_PATH" ]; then
  echo "ERROR: SSH key tidak ditemukan di: $KEY_PATH"
  exit 1
fi

chmod 600 "$KEY_PATH"

echo "[2/4] Show Terraform output..."
cd "$PROJECT_ROOT"
terraform output

echo ""
echo "[3/4] Test Ansible inventory..."
cd "$ANSIBLE_DIR"
ansible-inventory --list

echo ""
echo "[4/4] Run Ansible playbook..."
ansible-playbook playbook.yml

echo ""
echo "==============================================="
echo "        DONE"
echo "==============================================="
echo ""
echo "Gunakan kubeconfig:"
echo "export KUBECONFIG=\$HOME/.kube/k3s-aws.yaml"
echo ""
echo "Test:"
echo "kubectl get nodes"
