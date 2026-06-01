#!/bin/bash
set -e

# ===============================================================
# KONFIGURASI
# ===============================================================
PROJECT_DIR="$(cd "$(dirname "$0")" && pwd)"
SSH_KEY_PATH="$HOME/.ssh/terraform-aws-key.pem"
SSH_PUB_PATH="$HOME/.ssh/terraform-aws-key.pub"
WORKSPACES_DIR="$PROJECT_DIR/workspaces"

cd "$PROJECT_DIR"

# ===============================================================
# FUNGSI: SSH KEY MANAGEMENT
# ===============================================================
ensure_ssh_key() {
  if [ -f "$SSH_KEY_PATH" ] && [ -f "$SSH_PUB_PATH" ]; then
    echo "✅ SSH key sudah ada: $SSH_KEY_PATH"
    echo "   (Menggunakan key yang sudah ada, tidak membuat baru)"
    return 0
  fi

  echo "🔑 SSH key belum ada. Membuat key baru..."
  mkdir -p "$HOME/.ssh"
  # ssh-keygen membuat pubkey sebagai {filename}.pub
  # Generate tanpa .pem dulu, lalu rename private key ke .pem
  local temp_key="$HOME/.ssh/terraform-aws-key"
  ssh-keygen -t rsa -b 4096 -f "$temp_key" -N "" -C "terraform-aws-deploy"
  # Rename private key ke .pem (public key sudah benar: terraform-aws-key.pub)
  mv "$temp_key" "$SSH_KEY_PATH"
  chmod 400 "$SSH_KEY_PATH"
  chmod 644 "$SSH_PUB_PATH"
  echo "✅ SSH key berhasil dibuat: $SSH_KEY_PATH"
}

# ===============================================================
# FUNGSI: PILIH REGION
# ===============================================================
pilih_region() {
  echo ""
  echo "==============================================="
  echo "       PILIH WILAYAH (REGION) AWS EC2          "
  echo "==============================================="
  echo "1. Asia Pasifik (Asia Pacific)"
  echo "2. Amerika Utara & Selatan (Americas)"
  echo "3. Eropa (Europe)"
  echo "4. Timur Tengah & Afrika (Middle East & Africa)"
  echo "-----------------------------------------------"
  read -p "Masukkan pilihan benua [1-4]: " region_choice
  echo ""

  case $region_choice in
    1)
      echo "--- Wilayah Asia Pasifik ---"
      echo "1. Indonesia (Jakarta) - ap-southeast-3"
      echo "2. Singapura - ap-southeast-1"
      echo "3. Malaysia - ap-southeast-5"
      echo "4. Thailand - ap-southeast-7"
      echo "5. Jepang (Tokyo) - ap-northeast-1"
      echo "6. Korea Selatan (Seoul) - ap-northeast-2"
      echo "7. Australia (Sydney) - ap-southeast-2"
      echo "8. India (Mumbai) - ap-south-1"
      echo "-----------------------------------------------"
      read -p "Pilih negara/kota [1-8]: " ap_choice
      case $ap_choice in
        1) aws_region="ap-southeast-3" ;;
        2) aws_region="ap-southeast-1" ;;
        3) aws_region="ap-southeast-5" ;;
        4) aws_region="ap-southeast-7" ;;
        5) aws_region="ap-northeast-1" ;;
        6) aws_region="ap-northeast-2" ;;
        7) aws_region="ap-southeast-2" ;;
        8) aws_region="ap-south-1" ;;
        *) echo "Pilihan tidak valid. Default ke Jakarta."; aws_region="ap-southeast-3" ;;
      esac
      ;;
    2)
      echo "--- Wilayah Amerika ---"
      echo "1. AS Timur (N. Virginia) - us-east-1"
      echo "2. AS Timur (Ohio) - us-east-2"
      echo "3. AS Barat (Oregon) - us-west-2"
      echo "4. Kanada (Tengah) - ca-central-1"
      echo "5. Brasil (São Paulo) - sa-east-1"
      echo "-----------------------------------------------"
      read -p "Pilih lokasi [1-5]: " am_choice
      case $am_choice in
        1) aws_region="us-east-1" ;;
        2) aws_region="us-east-2" ;;
        3) aws_region="us-west-2" ;;
        4) aws_region="ca-central-1" ;;
        5) aws_region="sa-east-1" ;;
        *) echo "Pilihan tidak valid. Default ke N. Virginia."; aws_region="us-east-1" ;;
      esac
      ;;
    3)
      echo "--- Wilayah Eropa ---"
      echo "1. Jerman (Frankfurt) - eu-central-1"
      echo "2. Irlandia - eu-west-1"
      echo "3. Inggris (London) - eu-west-2"
      echo "4. Prancis (Paris) - eu-west-3"
      echo "5. Swedia (Stockholm) - eu-north-1"
      echo "-----------------------------------------------"
      read -p "Pilih negara [1-5]: " eu_choice
      case $eu_choice in
        1) aws_region="eu-central-1" ;;
        2) aws_region="eu-west-1" ;;
        3) aws_region="eu-west-2" ;;
        4) aws_region="eu-west-3" ;;
        5) aws_region="eu-north-1" ;;
        *) echo "Pilihan tidak valid. Default ke Frankfurt."; aws_region="eu-central-1" ;;
      esac
      ;;
    4)
      echo "--- Wilayah Timur Tengah & Afrika ---"
      echo "1. Uni Emirat Arab - me-central-1"
      echo "2. Bahrain - me-south-1"
      echo "3. Israel (Tel Aviv) - il-central-1"
      echo "4. Afrika Selatan (Cape Town) - af-south-1"
      echo "-----------------------------------------------"
      read -p "Pilih negara [1-4]: " me_choice
      case $me_choice in
        1) aws_region="me-central-1" ;;
        2) aws_region="me-south-1" ;;
        3) aws_region="il-central-1" ;;
        4) aws_region="af-south-1" ;;
        *) echo "Pilihan tidak valid. Default ke UEA."; aws_region="me-central-1" ;;
      esac
      ;;
    *)
      echo "Pilihan benua tidak valid. Menggunakan default: Jakarta (ap-southeast-3)"
      aws_region="ap-southeast-3"
      ;;
  esac
}

# ===============================================================
# FUNGSI: PILIH INSTANCE TYPE
# ===============================================================
pilih_instance_type() {
  echo ""
  echo "==============================================="
  echo "       PILIH KATEGORI INSTANCE TYPE EC2        "
  echo "==============================================="
  echo "0. Trial/Free Tier (T2.micro dan T3.micro, hanya untuk region tertentu)"
  echo "1. Burstable Performance (Murah/Hemat, cocok untuk Dev/Testing)"
  echo "2. General Purpose (Seimbang CPU & RAM, cocok untuk Web Server)"
  echo "3. Compute Optimized (Fokus Performa CPU, cocok untuk Aplikasi Berat)"
  echo "4. Memory Optimized (Fokus RAM Besar, cocok untuk Database/Cache)"
  echo "-----------------------------------------------"
  read -p "Masukkan pilihan kategori [0-4]: " instance_cat_choice
  echo ""

  case $instance_cat_choice in
    0)
      echo "--- Kategori: Trial/Free Tier (T2/T3) ---"
      echo "Cek di AWS EC2 describe-instance-types --region ap-southeast-1 --filters 'Name=free-tier-eligible,Values=true' --query 'InstanceTypes[*].InstanceType'"
      echo "1. t2.micro   (1 vCPU, 1 GiB RAM)   - Free Tier Eligible (hanya di beberapa region)"
      echo "2. t3.micro   (2 vCPU, 1 GiB RAM)   - Free Tier Eligible (hanya di beberapa region)"
      echo "-----------------------------------------------"
      read -p "Pilih ukuran instance [1-2]: " size_choice
      case $size_choice in
        1) aws_instance="t2.micro" ;;
        2) aws_instance="t3.micro" ;;
        *) echo "Pilihan tidak valid. Default ke t3.micro."; aws_instance="t3.micro" ;;
      esac
      ;;
    1)
      echo "--- Kategori: Burstable Performance (T3/T4g) ---"
      echo "1. t3.nano    (2 vCPU, 0.5 GiB RAM) - Sangat Ringan"
      echo "2. t3.micro   (2 vCPU, 1 GiB RAM)   - Free Tier Eligible"
      echo "3. t3.small   (2 vCPU, 2 GiB RAM)   - Standar Testing"
      echo "4. t3.medium  (2 vCPU, 4 GiB RAM)   - Dev Server Nyaman"
      echo "5. t3.large   (2 vCPU, 8 GiB RAM)"
      echo "-----------------------------------------------"
      read -p "Pilih ukuran instance [1-5]: " size_choice
      case $size_choice in
        1) aws_instance="t3.nano" ;;
        2) aws_instance="t3.micro" ;;
        3) aws_instance="t3.small" ;;
        4) aws_instance="t3.medium" ;;
        5) aws_instance="t3.large" ;;
        *) echo "Pilihan tidak valid. Default ke t3.micro."; aws_instance="t3.micro" ;;
      esac
      ;;
    2)
      echo "--- Kategori: General Purpose (M6i) ---"
      echo "1. m6i.large     (2 vCPU, 8 GiB RAM)"
      echo "2. m6i.xlarge    (4 vCPU, 16 GiB RAM)"
      echo "3. m6i.2xlarge   (8 vCPU, 32 GiB RAM)"
      echo "-----------------------------------------------"
      read -p "Pilih ukuran instance [1-3]: " size_choice
      case $size_choice in
        1) aws_instance="m6i.large" ;;
        2) aws_instance="m6i.xlarge" ;;
        3) aws_instance="m6i.2xlarge" ;;
        *) echo "Pilihan tidak valid. Default ke m6i.large."; aws_instance="m6i.large" ;;
      esac
      ;;
    3)
      echo "--- Kategori: Compute Optimized (C6i) ---"
      echo "1. c6i.large     (2 vCPU, 4 GiB RAM)"
      echo "2. c6i.xlarge    (4 vCPU, 8 GiB RAM)"
      echo "3. c6i.2xlarge   (8 vCPU, 16 GiB RAM)"
      echo "-----------------------------------------------"
      read -p "Pilih ukuran instance [1-3]: " size_choice
      case $size_choice in
        1) aws_instance="c6i.large" ;;
        2) aws_instance="c6i.xlarge" ;;
        3) aws_instance="c6i.2xlarge" ;;
        *) echo "Pilihan tidak valid. Default ke c6i.large."; aws_instance="c6i.large" ;;
      esac
      ;;
    4)
      echo "--- Kategori: Memory Optimized (R6i) ---"
      echo "1. r6i.large     (2 vCPU, 16 GiB RAM)"
      echo "2. r6i.xlarge    (4 vCPU, 32 GiB RAM)"
      echo "3. r6i.2xlarge   (8 vCPU, 64 GiB RAM)"
      echo "-----------------------------------------------"
      read -p "Pilih ukuran instance [1-3]: " size_choice
      case $size_choice in
        1) aws_instance="r6i.large" ;;
        2) aws_instance="r6i.xlarge" ;;
        3) aws_instance="r6i.2xlarge" ;;
        *) echo "Pilihan tidak valid. Default ke r6i.large."; aws_instance="r6i.large" ;;
      esac
      ;;
    *)
      echo "Pilihan kategori tidak valid. Menggunakan default: t3.micro"
      aws_instance="t3.micro"
      ;;
  esac
}

# ===============================================================
# FUNGSI: PILIH OS
# ===============================================================
pilih_os() {
  echo ""
  echo "==============================================="
  echo "         PILIH OPERATING SYSTEM (AMI)          "
  echo "==============================================="
  echo "1. Ubuntu Linux"
  echo "2. Debian GNU/Linux"
  echo "-----------------------------------------------"
  read -p "Masukkan pilihan OS [1-2]: " os_choice
  echo ""

  case $os_choice in
    1)
      echo "--- Pilih Versi Ubuntu ---"
      echo "1. Ubuntu 20.04 LTS (Focal Fossa)"
      echo "2. Ubuntu 22.04 LTS (Jammy Jellyfish)"
      echo "3. Ubuntu 24.04 LTS (Noble Numbat)"
      echo "-----------------------------------------------"
      read -p "Pilih versi [1-3]: " ver_choice
      case $ver_choice in
        1) aws_os_version="ubuntu-20" ;;
        2) aws_os_version="ubuntu-22" ;;
        3) aws_os_version="ubuntu-24" ;;
        *) echo "Pilihan salah. Menggunakan default Ubuntu 22.04"; aws_os_version="ubuntu-22" ;;
      esac
      ;;
    2)
      echo "--- Pilih Versi Debian ---"
      echo "1. Debian 11 (Bullseye)"
      echo "2. Debian 12 (Bookworm)"
      echo "-----------------------------------------------"
      read -p "Pilih versi [1-2]: " ver_choice
      case $ver_choice in
        1) aws_os_version="debian-11" ;;
        2) aws_os_version="debian-12" ;;
        *) echo "Pilihan salah. Menggunakan default Debian 12"; aws_os_version="debian-12" ;;
      esac
      ;;
    *)
      echo "Pilihan OS tidak valid. Menggunakan default: Ubuntu 22.04"
      aws_os_version="ubuntu-22"
      ;;
  esac
}

# ===============================================================
# FUNGSI: GET WORKSPACE LIST (selain default)
# ===============================================================
get_workspaces() {
  terraform workspace list 2>/dev/null | grep -v "^[*]*\s*default$" | sed 's/^[* ]*//' | grep -v '^$'
}

# ===============================================================
# ACTION: CREATE — Buat Instance Baru
# ===============================================================
action_create() {
  echo ""
  echo "==============================================="
  echo "        🚀 BUAT INSTANCE BARU                 "
  echo "==============================================="

  # 1) Pastikan SSH key ada
  ensure_ssh_key

  # 2) Input nama instance
  echo ""
  echo "-----------------------------------------------"
  echo "       Nama EC2 Instance Anda (untuk tag Name)       "
  echo "-----------------------------------------------"
  read -p "Masukkan nama instance (default: web-server-prod): " instance_name
  instance_name=${instance_name:-web-server-prod}

  # Cek apakah workspace dengan nama ini sudah ada
  if terraform workspace list 2>/dev/null | grep -q "^\s*${instance_name}$\|^\*\s*${instance_name}$"; then
    echo ""
    echo "⚠️  Workspace '${instance_name}' sudah ada!"
    echo "Gunakan nama lain atau destroy dulu yang lama."
    echo ""
    return 1
  fi

  # 3) Pilih konfigurasi
  pilih_region
  pilih_instance_type
  pilih_os

  # 4) Update terraform.tfvars
  sed -i "s/^\(aws_region\s*=\s*\).*/\1\"$aws_region\"/" terraform.tfvars
  sed -i "s/^\(instance_type\s*=\s*\).*/\1\"$aws_instance\"/" terraform.tfvars
  sed -i "s/^\(os_version\s*=\s*\).*/\1\"$aws_os_version\"/" terraform.tfvars
  sed -i "s/^\(instance_name\s*=\s*\).*/\1\"$instance_name\"/" terraform.tfvars

  # 5) Simpan salinan tfvars per-workspace (untuk destroy nanti)
  mkdir -p "$WORKSPACES_DIR"
  cp terraform.tfvars "$WORKSPACES_DIR/${instance_name}.tfvars"

  echo ""
  echo "==============================================="
  echo "       KONFIGURASI AWS EC2 ANDA TELAH SIAP     "
  echo "==============================================="
  echo "Instance Name   : $instance_name"
  echo "Region          : $aws_region"
  echo "Instance Type   : $aws_instance"
  echo "Operating System: $aws_os_version"
  echo "SSH Key         : $SSH_KEY_PATH"
  echo "Workspace       : $instance_name"
  echo "-----------------------------------------------"

  echo ""
  echo "1. Deploy Now!"
  echo "2. Exit (deploy nanti)"
  read -p "Pilih opsi [1-2]: " deploy_choice
  echo ""

  if [ "$deploy_choice" == "1" ]; then
    echo "📦 Initializing Terraform..."
    terraform init

    echo ""
    echo "📂 Membuat workspace: $instance_name"
    terraform workspace new "$instance_name"

    echo ""
    echo "🔍 Validating configuration..."
    terraform validate

    echo ""
    echo "🚀 Deploying with Terraform..."
    terraform apply

    echo ""
    echo "==============================================="
    echo "  ✅ DEPLOYMENT BERHASIL: $instance_name"
    echo "==============================================="
    terraform output
  else
    echo "Setup selesai. Untuk deploy nanti, jalankan:"
    echo "  terraform init"
    echo "  terraform workspace new $instance_name"
    echo "  terraform apply"
  fi
}

# ===============================================================
# ACTION: LIST — Lihat Semua Deployment
# ===============================================================
action_list() {
  echo ""
  echo "==============================================="
  echo "        📋 DAFTAR SEMUA DEPLOYMENT             "
  echo "==============================================="

  terraform init -input=false > /dev/null 2>&1 || true

  local workspaces
  workspaces=$(get_workspaces)

  if [ -z "$workspaces" ]; then
    echo ""
    echo "  (Belum ada deployment aktif)"
    echo ""
    return 0
  fi

  local current_ws
  current_ws=$(terraform workspace show)

  local idx=0
  while IFS= read -r ws; do
    idx=$((idx + 1))

    # Switch ke workspace ini untuk baca output
    terraform workspace select "$ws" > /dev/null 2>&1

    local ip region inst_type
    ip=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")
    region=$(terraform output -raw availability_zone 2>/dev/null || echo "N/A")
    inst_type=$(terraform output -raw instance_type 2>/dev/null || echo "N/A")

    echo ""
    echo "  [$idx] 🖥️  $ws"
    echo "      IP          : $ip"
    echo "      Region/AZ   : $region"
    echo "      Instance    : $inst_type"
    echo "      SSH         : ssh -i $SSH_KEY_PATH ubuntu@$ip"
  done <<< "$workspaces"

  # Kembali ke workspace sebelumnya
  terraform workspace select "$current_ws" > /dev/null 2>&1 || terraform workspace select default > /dev/null 2>&1

  echo ""
  echo "-----------------------------------------------"
  echo "  Total: $idx deployment(s)"
  echo "==============================================="
}

# ===============================================================
# ACTION: DESTROY — Hapus Deployment Tertentu
# ===============================================================
action_destroy() {
  echo ""
  echo "==============================================="
  echo "        🗑️  HAPUS DEPLOYMENT TERTENTU          "
  echo "==============================================="

  terraform init -input=false > /dev/null 2>&1 || true

  local workspaces
  workspaces=$(get_workspaces)

  if [ -z "$workspaces" ]; then
    echo ""
    echo "  (Tidak ada deployment yang bisa dihapus)"
    echo ""
    return 0
  fi

  # Tampilkan list
  local ws_array=()
  local idx=0
  while IFS= read -r ws; do
    idx=$((idx + 1))
    ws_array+=("$ws")

    terraform workspace select "$ws" > /dev/null 2>&1
    local ip
    ip=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")

    echo "  [$idx] $ws (IP: $ip)"
  done <<< "$workspaces"

  echo ""
  echo "  [0] Batal (kembali ke menu)"
  echo "-----------------------------------------------"
  read -p "Pilih nomor deployment yang akan dihapus [0-$idx]: " destroy_choice

  if [ "$destroy_choice" == "0" ] || [ -z "$destroy_choice" ]; then
    echo "Dibatalkan."
    terraform workspace select default > /dev/null 2>&1
    return 0
  fi

  # Validasi input
  if ! [[ "$destroy_choice" =~ ^[0-9]+$ ]] || [ "$destroy_choice" -lt 1 ] || [ "$destroy_choice" -gt "$idx" ]; then
    echo "❌ Pilihan tidak valid."
    terraform workspace select default > /dev/null 2>&1
    return 1
  fi

  local target_ws="${ws_array[$((destroy_choice - 1))]}"

  echo ""
  echo "⚠️  Anda akan menghapus deployment: $target_ws"
  read -p "Ketik 'yes' untuk konfirmasi: " confirm

  if [ "$confirm" != "yes" ]; then
    echo "Dibatalkan."
    terraform workspace select default > /dev/null 2>&1
    return 0
  fi

  echo ""
  echo "🗑️  Menghapus deployment: $target_ws ..."
  terraform workspace select "$target_ws"

  # Gunakan tfvars workspace agar region benar
  local ws_tfvars="$WORKSPACES_DIR/${target_ws}.tfvars"
  if [ -f "$ws_tfvars" ]; then
    echo "📄 Menggunakan config: $ws_tfvars"
    terraform destroy -auto-approve -var-file="$ws_tfvars"
  else
    echo "⚠️  Config workspace tidak ditemukan, menggunakan terraform.tfvars"
    terraform destroy -auto-approve
  fi

  echo ""
  echo "📂 Menghapus workspace: $target_ws ..."
  terraform workspace select default
  terraform workspace delete "$target_ws"
  rm -f "$ws_tfvars"

  echo ""
  echo "✅ Deployment '$target_ws' berhasil dihapus!"
}

# ===============================================================
# ACTION: DESTROY ALL — Hapus Semua Deployment
# ===============================================================
action_destroy_all() {
  echo ""
  echo "==============================================="
  echo "        💣 HAPUS SEMUA DEPLOYMENT              "
  echo "==============================================="

  terraform init -input=false > /dev/null 2>&1 || true

  local workspaces
  workspaces=$(get_workspaces)

  if [ -z "$workspaces" ]; then
    echo ""
    echo "  (Tidak ada deployment yang bisa dihapus)"
    echo ""
    return 0
  fi

  # Tampilkan semua yang akan dihapus
  echo ""
  echo "Deployment yang akan DIHAPUS SEMUA:"
  local total=0
  while IFS= read -r ws; do
    total=$((total + 1))
    terraform workspace select "$ws" > /dev/null 2>&1
    local ip
    ip=$(terraform output -raw public_ip 2>/dev/null || echo "N/A")
    echo "  ❌ $ws (IP: $ip)"
  done <<< "$workspaces"

  echo ""
  echo "⚠️  PERINGATAN: Anda akan menghapus $total deployment!"
  echo "⚠️  Tindakan ini TIDAK BISA DIBATALKAN!"
  read -p "Ketik 'destroy all' untuk konfirmasi: " confirm

  if [ "$confirm" != "destroy all" ]; then
    echo "Dibatalkan."
    terraform workspace select default > /dev/null 2>&1
    return 0
  fi

  echo ""
  local success=0
  local failed=0
  while IFS= read -r ws; do
    echo "-----------------------------------------------"
    echo "🗑️  [$((success + failed + 1))/$total] Menghapus: $ws ..."
    terraform workspace select "$ws" > /dev/null 2>&1

    # Gunakan tfvars workspace agar region benar
    local ws_tfvars="$WORKSPACES_DIR/${ws}.tfvars"
    local destroy_cmd="terraform destroy -auto-approve"
    if [ -f "$ws_tfvars" ]; then
      echo "📄 Config: $ws_tfvars"
      destroy_cmd="terraform destroy -auto-approve -var-file=$ws_tfvars"
    else
      echo "⚠️  Config workspace tidak ditemukan, menggunakan terraform.tfvars"
    fi

    if $destroy_cmd; then
      terraform workspace select default > /dev/null 2>&1
      terraform workspace delete "$ws" > /dev/null 2>&1
      rm -f "$ws_tfvars"
      echo "✅ $ws berhasil dihapus"
      success=$((success + 1))
    else
      echo "❌ Gagal menghapus $ws"
      terraform workspace select default > /dev/null 2>&1
      failed=$((failed + 1))
    fi
  done <<< "$workspaces"

  echo ""
  echo "==============================================="
  echo "  HASIL DESTROY ALL"
  echo "  ✅ Berhasil: $success"
  echo "  ❌ Gagal   : $failed"
  echo "==============================================="
}

# ===============================================================
# MAIN MENU
# ===============================================================
echo "==============================================="
echo "   SELAMAT DATANG DI SETUP AWS EC2 INSTANCE   "
echo "==============================================="
echo "Sebelum memulai, pastikan Anda sudah menginstal Terraform dan AWS CLI"
echo "Juga pastikan Anda sudah mengkonfigurasi kredensial AWS CLI dengan 'aws configure'"
echo "==============================================="
echo ""
echo "  1. 🚀 Buat Instance Baru (Create)"
echo "  2. 📋 Lihat Semua Instance (List)"
echo "  3. 🗑️  Hapus Instance Tertentu (Destroy)"
echo "  4. 💣 Hapus Semua Instance (Destroy All)"
echo "  5. ❌ Keluar (Exit)"
echo ""
echo "-----------------------------------------------"
read -p "Pilih menu [1-5]: " menu_choice
echo ""

case $menu_choice in
  1) action_create ;;
  2) action_list ;;
  3) action_destroy ;;
  4) action_destroy_all ;;
  5) echo "Sampai jumpa! 👋"; exit 0 ;;
  *) echo "❌ Pilihan tidak valid."; exit 1 ;;
esac