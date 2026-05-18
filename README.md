# Terraform AWS EC2 - Single Instance

Repositori ini berisi konfigurasi Terraform untuk membuat **1 instance EC2 di AWS** lengkap dengan:

- pemilihan image OS Ubuntu atau Debian secara otomatis,
- pembuatan SSH key pair baru,
- security group untuk akses SSH, HTTP, dan HTTPS,
- instalasi Nginx otomatis melalui `user_data`,
- output praktis seperti IP publik, DNS publik, dan command SSH siap pakai.

## Arsitektur Singkat

Saat dijalankan, Terraform akan membuat resource berikut:

| Resource | Fungsi |
| --- | --- |
| `tls_private_key.ssh_key` | Membuat private/public key SSH baru |
| `aws_key_pair.generated_key` | Mendaftarkan public key ke AWS EC2 |
| `local_sensitive_file.private_key` | Menyimpan private key sebagai file `.pem` lokal |
| `data.aws_ami.selected_os` | Memilih AMI Ubuntu atau Debian terbaru sesuai `os_version` |
| `aws_security_group.web` | Membuka akses SSH, HTTP, dan HTTPS |
| `aws_instance.web` | Membuat instance EC2 dan menjalankan bootstrap Nginx |

## Struktur File

| File | Kegunaan |
| --- | --- |
| `main.tf` | Definisi provider, AMI, key pair, security group, dan EC2 instance |
| `variable.tf` | Daftar variabel input Terraform |
| `output.tf` | Output setelah deployment selesai |
| `terraform.tfvars` | Nilai variabel yang digunakan saat ini |
| `userdata.sh.tpl` | Script bootstrap untuk install dan menjalankan Nginx |
| `setup.sh` | Wizard interaktif untuk mengubah konfigurasi lalu menjalankan deployment |

## Prasyarat

Pastikan sudah tersedia:

1. Akun AWS aktif
2. AWS CLI sudah terpasang dan dikonfigurasi:

   ```bash
   aws configure
   ```

3. Terraform sudah terpasang
4. Kredensial AWS yang digunakan memiliki izin untuk membuat:
   - EC2 instance
   - Security Group
   - Key Pair

## Konfigurasi

Nilai konfigurasi utama berada di `terraform.tfvars`.

Contoh:

```hcl
instance_name = "coba-nginx"
aws_region    = "ap-southeast-1"
instance_type = "t3.micro"
key_name      = "ubuntu-lab-key"
my_ip         = "0.0.0.0/0"
os_version    = "debian-11"
```

### Variabel yang Tersedia

| Variabel | Tipe | Default | Keterangan |
| --- | --- | --- | --- |
| `instance_name` | `string` | `terraform-web` | Nama instance untuk tag `Name` |
| `aws_region` | `string` | - | Region AWS target |
| `instance_type` | `string` | - | Tipe EC2 instance |
| `key_name` | `string` | `ubuntu-lab-key` | Nama key pair yang dibuat di AWS |
| `my_ip` | `string` | - | CIDR yang diizinkan mengakses SSH port 22 |
| `os_version` | `string` | `ubuntu` | Versi OS untuk AMI instance |

### Nilai `os_version` yang Didukung

| Nilai | Sistem Operasi |
| --- | --- |
| `ubuntu-20` | Ubuntu 20.04 LTS |
| `ubuntu-22` | Ubuntu 22.04 LTS |
| `ubuntu-24` | Ubuntu 24.04 LTS |
| `debian-11` | Debian 11 |
| `debian-12` | Debian 12 |

Jika nilai `os_version` tidak cocok dengan daftar di atas, konfigurasi akan fallback ke Ubuntu 22.04.

## Cara Deploy

### Opsi 1 - Langsung dengan Terraform

```bash
terraform init
terraform plan
terraform apply
```

Jika ingin menghapus semua resource:

```bash
terraform destroy
```

### Opsi 2 - Menggunakan Script Interaktif

Jalankan:

```bash
bash setup.sh
```

Script ini akan membantu memilih:

- nama instance,
- region AWS,
- instance type,
- OS dan versinya,
- lalu memperbarui `terraform.tfvars`.

Di akhir proses, script dapat langsung menjalankan `terraform init` dan `terraform apply`.

## Output Setelah Deployment

Setelah `terraform apply` berhasil, Terraform menampilkan:

| Output | Keterangan |
| --- | --- |
| `instance_id` | ID instance EC2 |
| `public_ip` | IP publik instance |
| `public_dns` | DNS publik instance |
| `instance_type` | Tipe EC2 yang digunakan |
| `availability_zone` | Availability Zone instance |
| `ssh_command` | Command SSH siap copy-paste |
| `private_key_path` | Lokasi file private key `.pem` |
| `website_url` | URL HTTP ke web server Nginx |

Contoh akses SSH:

```bash
ssh -i ./ubuntu-lab-key.pem admin@<public_ip>
```

Catatan:

- Untuk Debian, user default SSH adalah `admin`
- Untuk Ubuntu, user default SSH adalah `ubuntu`

## Web Server Otomatis

File `userdata.sh.tpl` akan dijalankan saat instance pertama kali dibuat.

Isi utamanya:

```bash
apt update -y
apt install nginx -y
systemctl enable nginx
systemctl start nginx
```

Setelah instance aktif, halaman default Nginx akan diganti menjadi:

```html
<h1>Hello from Terraform EC2</h1>
```

## Catatan Keamanan

Konfigurasi saat ini pada `terraform.tfvars` menggunakan:

```hcl
my_ip = "0.0.0.0/0"
```

Artinya akses SSH dibuka dari seluruh internet. Ini praktis untuk demo, tetapi **tidak disarankan untuk penggunaan nyata**.

Lebih aman jika diganti ke IP publik pribadi Anda, misalnya:

```hcl
my_ip = "203.0.113.10/32"
```

Selain itu:

- file private key `.pem` akan dibuat di direktori proyek,
- jangan commit file `.pem` ke Git,
- simpan state Terraform dengan aman karena dapat memuat informasi sensitif.

## Alur Kerja yang Disarankan

1. Ubah `terraform.tfvars`
2. Jalankan:

   ```bash
   terraform fmt
   terraform validate
   terraform plan
   terraform apply
   ```

3. Akses website melalui output `website_url`
4. Akses server melalui output `ssh_command`
5. Jika sudah tidak digunakan, jalankan:

   ```bash
   terraform destroy
   ```

## Hal yang Perlu Diperhatikan

- Security group dibuat dengan nama tetap `terraform-web`. Jika deploy paralel di region/VPC yang sama, nama ini bisa bentrok.
- `setup.sh` ditulis untuk shell Bash. Pada Windows, jalankan lewat Git Bash, WSL, atau lingkungan Bash lain.
- `key_name` pada variabel menjelaskan "existing AWS key pair name", tetapi konfigurasi sebenarnya membuat key pair baru dengan nama tersebut.

## Ringkasan

Repo ini cocok untuk:

- latihan Terraform,
- provisioning web server sederhana,
- demo deployment EC2 dengan bootstrap otomatis.

Untuk penggunaan production, pertimbangkan menambahkan:

- VPC dan subnet khusus,
- remote backend untuk state,
- Elastic IP atau load balancer,
- pembatasan akses SSH yang lebih ketat,
- monitoring dan logging tambahan.
