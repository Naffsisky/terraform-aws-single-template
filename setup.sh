#!/bin/bash

echo "==============================================="
echo "   SELAMAT DATANG DI SETUP AWS EC2 INSTANCE   "
echo "==============================================="
echo "Sebelum memulai, pastikan Anda sudah menginstal Terraform dan AWS CLI"
echo "Juga pastikan Anda sudah mengkonfigurasi kredensial AWS CLI dengan 'aws configure'"
echo "-----------------------------------------------"
echo "       Nama EC2 Instance Anda (untuk tag Name)       "
echo "-----------------------------------------------"
read -p "Masukkan nama instance (default: web-server-prod): " instance_name
instance_name=${instance_name:-web-server-prod}

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
            *) 
                echo "Pilihan tidak valid. Default ke Jakarta."
                aws_region="ap-southeast-3" 
                ;;
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
            *) 
                echo "Pilihan tidak valid. Default ke N. Virginia."
                aws_region="us-east-1" 
                ;;
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
            *) 
                echo "Pilihan tidak valid. Default ke Frankfurt."
                aws_region="eu-central-1" 
                ;;
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
            *) 
                echo "Pilihan tidak valid. Default ke UEA."
                aws_region="me-central-1" 
                ;;
        esac
        ;;
        
    *)
        echo "Pilihan benua tidak valid. Menggunakan default: Jakarta (ap-southeast-3)"
        aws_region="ap-southeast-3"
        ;;
esac

# ===============================================================
# PART 2: PILIH INSTANCE TYPE AWS EC2
# ===============================================================

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

# ===============================================================
# PART 3: PILIH OPERATING SYSTEM & VERSI (AMI IMAGE)
# ===============================================================

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

# ===============================================================
sed -i "s/^\(aws_region\s*=\s*\).*/\1\"$aws_region\"/" terraform.tfvars
sed -i "s/^\(instance_type\s*=\s*\).*/\1\"$aws_instance\"/" terraform.tfvars
sed -i "s/^\(os_version\s*=\s*\).*/\1\"$aws_os_version\"/" terraform.tfvars
sed -i "s/^\(instance_name\s*=\s*\).*/\1\"$instance_name\"/" terraform.tfvars

echo ""
echo "==============================================="
echo "       KONFIGURASI AWS EC2 ANDA TELAH SIAP     "
echo "==============================================="
echo "Region yang dipilih: $aws_region"
echo "Instance Type yang dipilih: $aws_instance"
echo "Operating System yang dipilih: $aws_os_version"
echo "Instance Name: $instance_name"
echo "-----------------------------------------------"

echo "Ready for Deploy!"
echo "1. Deploy Now!"
echo "2. Exit"
read -p "Pilih opsi [1-2]: " deploy_choice
echo ""

if [ "$deploy_choice" == "1" ]; then
    echo "Deploying with Terraform..."
    terraform validate
    terraform init
    terraform apply
else
    echo "Exiting setup. You can run 'terraform apply' later to deploy."
fi