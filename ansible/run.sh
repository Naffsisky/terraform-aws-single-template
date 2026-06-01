#!/bin/bash
set -e

ANSIBLE_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$ANSIBLE_DIR/.." && pwd)"
SSH_KEY_PATH="$HOME/.ssh/terraform-aws-key.pem"

cd "$ANSIBLE_DIR"

echo "==============================================="
echo "        RUNNING ANSIBLE K3S SETUP"
echo "==============================================="

# ── Pilih workspace jika ada banyak deployment ──
echo "[0/4] Checking Terraform workspaces..."
cd "$PROJECT_ROOT"
terraform init -input=false > /dev/null 2>&1 || true

WORKSPACES=$(terraform workspace list 2>/dev/null | grep -v "^[*]*\s*default$" | sed 's/^[* ]*//' | grep -v '^$')

if [ -z "$WORKSPACES" ]; then
  echo "ERROR: Tidak ada deployment aktif. Jalankan setup.sh terlebih dahulu."
  exit 1
fi

WS_COUNT=$(echo "$WORKSPACES" | wc -l)

if [ "$WS_COUNT" -eq 1 ]; then
  TARGET_WS="$WORKSPACES"
  echo "Menggunakan deployment: $TARGET_WS"
else
  echo ""
  echo "Ditemukan $WS_COUNT deployment aktif:"
  IDX=0
  declare -a WS_ARRAY
  while IFS= read -r ws; do
    IDX=$((IDX + 1))
    WS_ARRAY+=("$ws")
    echo "  [$IDX] $ws"
  done <<< "$WORKSPACES"

  echo ""
  read -p "Pilih deployment untuk Ansible [1-$IDX]: " ws_choice

  if ! [[ "$ws_choice" =~ ^[0-9]+$ ]] || [ "$ws_choice" -lt 1 ] || [ "$ws_choice" -gt "$IDX" ]; then
    echo "Pilihan tidak valid."
    exit 1
  fi

  TARGET_WS="${WS_ARRAY[$((ws_choice - 1))]}"
fi

echo "Target workspace: $TARGET_WS"
terraform workspace select "$TARGET_WS"

echo ""
echo "[1/4] Fix SSH key permission..."

if [ ! -f "$SSH_KEY_PATH" ]; then
  echo "ERROR: SSH key tidak ditemukan di: $SSH_KEY_PATH"
  echo "Jalankan setup.sh terlebih dahulu untuk generate SSH key."
  exit 1
fi

chmod 600 "$SSH_KEY_PATH"
echo "SSH key path: $SSH_KEY_PATH"

echo ""
echo "[2/4] Show Terraform output..."
terraform output

echo ""
echo "[3/4] Test Ansible inventory..."
cd "$ANSIBLE_DIR"
export TF_WORKSPACE="$TARGET_WS"
ansible-inventory --list

echo ""
echo "[4/4] Run Ansible playbook..."
ansible-playbook playbook.yml

echo ""
echo "==============================================="
echo "        DONE — Workspace: $TARGET_WS"
echo "==============================================="
echo ""
echo "Gunakan kubeconfig:"
echo "export KUBECONFIG=\$HOME/.kube/k3s-aws.yaml"
echo ""
echo "Test:"
echo "kubectl get nodes"
