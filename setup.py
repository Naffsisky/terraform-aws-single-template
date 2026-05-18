#!/usr/bin/env python3
"""
Interactive setup helper for the Terraform single-EC2 project.

This script mirrors the behavior of setup.sh:
- asks for instance configuration,
- updates terraform.tfvars,
- optionally runs terraform init and terraform apply.
"""

from __future__ import annotations

import ipaddress
import re
import subprocess
import urllib.error
import urllib.request
from pathlib import Path


BASE_DIR = Path(__file__).resolve().parent
TFVARS_PATH = BASE_DIR / "terraform.tfvars"


class Style:
    RESET = "\033[0m"
    BOLD = "\033[1m"
    DIM = "\033[2m"
    CYAN = "\033[36m"
    GREEN = "\033[32m"
    YELLOW = "\033[33m"
    BLUE = "\033[34m"


def color(text: str, *styles: str) -> str:
    return "".join(styles) + text + Style.RESET


REGIONS = {
    "1": {
        "label": "Asia Pasifik",
        "options": {
            "1": ("Indonesia (Jakarta)", "ap-southeast-3"),
            "2": ("Singapura", "ap-southeast-1"),
            "3": ("Malaysia", "ap-southeast-5"),
            "4": ("Thailand", "ap-southeast-7"),
            "5": ("Jepang (Tokyo)", "ap-northeast-1"),
            "6": ("Korea Selatan (Seoul)", "ap-northeast-2"),
            "7": ("Australia (Sydney)", "ap-southeast-2"),
            "8": ("India (Mumbai)", "ap-south-1"),
        },
        "default": "ap-southeast-3",
    },
    "2": {
        "label": "Amerika",
        "options": {
            "1": ("AS Timur (N. Virginia)", "us-east-1"),
            "2": ("AS Timur (Ohio)", "us-east-2"),
            "3": ("AS Barat (Oregon)", "us-west-2"),
            "4": ("Kanada (Tengah)", "ca-central-1"),
            "5": ("Brasil (Sao Paulo)", "sa-east-1"),
        },
        "default": "us-east-1",
    },
    "3": {
        "label": "Eropa",
        "options": {
            "1": ("Jerman (Frankfurt)", "eu-central-1"),
            "2": ("Irlandia", "eu-west-1"),
            "3": ("Inggris (London)", "eu-west-2"),
            "4": ("Prancis (Paris)", "eu-west-3"),
            "5": ("Swedia (Stockholm)", "eu-north-1"),
        },
        "default": "eu-central-1",
    },
    "4": {
        "label": "Timur Tengah & Afrika",
        "options": {
            "1": ("Uni Emirat Arab", "me-central-1"),
            "2": ("Bahrain", "me-south-1"),
            "3": ("Israel (Tel Aviv)", "il-central-1"),
            "4": ("Afrika Selatan (Cape Town)", "af-south-1"),
        },
        "default": "me-central-1",
    },
}

INSTANCE_CATEGORIES = {
    "0": {
        "label": "Trial / Free Tier",
        "options": {
            "1": ("t2.micro", "t2.micro", "1 vCPU, 1 GiB RAM"),
            "2": ("t3.micro", "t3.micro", "2 vCPU, 1 GiB RAM"),
        },
        "default": "t3.micro",
    },
    "1": {
        "label": "Burstable Performance",
        "options": {
            "1": ("t3.nano", "t3.nano", "2 vCPU, 0.5 GiB RAM"),
            "2": ("t3.micro", "t3.micro", "2 vCPU, 1 GiB RAM"),
            "3": ("t3.small", "t3.small", "2 vCPU, 2 GiB RAM"),
            "4": ("t3.medium", "t3.medium", "2 vCPU, 4 GiB RAM"),
            "5": ("t3.large", "t3.large", "2 vCPU, 8 GiB RAM"),
        },
        "default": "t3.micro",
    },
    "2": {
        "label": "General Purpose",
        "options": {
            "1": ("m6i.large", "m6i.large", "2 vCPU, 8 GiB RAM"),
            "2": ("m6i.xlarge", "m6i.xlarge", "4 vCPU, 16 GiB RAM"),
            "3": ("m6i.2xlarge", "m6i.2xlarge", "8 vCPU, 32 GiB RAM"),
        },
        "default": "m6i.large",
    },
    "3": {
        "label": "Compute Optimized",
        "options": {
            "1": ("c6i.large", "c6i.large", "2 vCPU, 4 GiB RAM"),
            "2": ("c6i.xlarge", "c6i.xlarge", "4 vCPU, 8 GiB RAM"),
            "3": ("c6i.2xlarge", "c6i.2xlarge", "8 vCPU, 16 GiB RAM"),
        },
        "default": "c6i.large",
    },
    "4": {
        "label": "Memory Optimized",
        "options": {
            "1": ("r6i.large", "r6i.large", "2 vCPU, 16 GiB RAM"),
            "2": ("r6i.xlarge", "r6i.xlarge", "4 vCPU, 32 GiB RAM"),
            "3": ("r6i.2xlarge", "r6i.2xlarge", "8 vCPU, 64 GiB RAM"),
        },
        "default": "r6i.large",
    },
}

OPERATING_SYSTEMS = {
    "1": {
        "label": "Ubuntu Linux",
        "options": {
            "1": ("Ubuntu 20.04 LTS", "ubuntu-20"),
            "2": ("Ubuntu 22.04 LTS", "ubuntu-22"),
            "3": ("Ubuntu 24.04 LTS", "ubuntu-24"),
        },
        "default": "ubuntu-22",
    },
    "2": {
        "label": "Debian GNU/Linux",
        "options": {
            "1": ("Debian 11", "debian-11"),
            "2": ("Debian 12", "debian-12"),
        },
        "default": "debian-12",
    },
}


def print_banner() -> None:
    print()
    print(color("+" + "=" * 53 + "+", Style.CYAN))
    print(
        color("|", Style.CYAN)
        + color("SETUP AWS EC2 INSTANCE DENGAN TERRAFORM", Style.BOLD).center(53)
        + color("|", Style.CYAN)
    )
    print(color("+" + "=" * 53 + "+", Style.CYAN))


def print_section(title: str) -> None:
    print()
    print(color(f"> {title}", Style.BOLD, Style.CYAN))
    print(color("-" * 55, Style.DIM))


def print_info(message: str) -> None:
    print(color("i ", Style.BLUE) + message)


def print_warning(message: str) -> None:
    print(color("! ", Style.YELLOW) + message)


def print_success(message: str) -> None:
    print(color("+ ", Style.GREEN) + message)


def prompt_with_default(label: str, default: str) -> str:
    value = input(f"{label} {color(f'[{default}]', Style.DIM)}: ").strip()
    return value or default


def choose_from_group(group: dict, prompt: str) -> str:
    for key, option in group["options"].items():
        label, value, *extra = option
        suffix = f" - {extra[0]}" if extra else (f" - {value}" if value != label else "")
        print(f"  {color(key + '.', Style.CYAN)} {label}{suffix}")

    choice = input(prompt).strip()
    if choice in group["options"]:
        return group["options"][choice][1]

    print_warning(f"Pilihan tidak valid. Menggunakan default: {group['default']}")
    return group["default"]


def choose_region() -> str:
    print_section("Pilih wilayah AWS")
    for key, data in REGIONS.items():
        print(f"  {color(key + '.', Style.CYAN)} {data['label']}")

    continent_choice = input("Masukkan pilihan benua [1-4]: ").strip()
    group = REGIONS.get(continent_choice)
    if not group:
        print_warning("Pilihan benua tidak valid. Menggunakan default: ap-southeast-3")
        return "ap-southeast-3"

    print(color(f"\nWilayah {group['label']}", Style.BOLD))
    return choose_from_group(group, "Pilih lokasi: ")


def choose_instance_type() -> str:
    print_section("Pilih kategori instance type")
    for key, data in INSTANCE_CATEGORIES.items():
        print(f"  {color(key + '.', Style.CYAN)} {data['label']}")

    category_choice = input("Masukkan pilihan kategori [0-4]: ").strip()
    group = INSTANCE_CATEGORIES.get(category_choice)
    if not group:
        print_warning("Pilihan kategori tidak valid. Menggunakan default: t3.micro")
        return "t3.micro"

    print(color(f"\nKategori {group['label']}", Style.BOLD))
    return choose_from_group(group, "Pilih ukuran instance: ")


def choose_os_version() -> str:
    print_section("Pilih operating system")
    for key, data in OPERATING_SYSTEMS.items():
        print(f"  {color(key + '.', Style.CYAN)} {data['label']}")

    os_choice = input("Masukkan pilihan OS [1-2]: ").strip()
    group = OPERATING_SYSTEMS.get(os_choice)
    if not group:
        print_warning("Pilihan OS tidak valid. Menggunakan default: ubuntu-22")
        return "ubuntu-22"

    print(color(f"\nVersi {group['label']}", Style.BOLD))
    return choose_from_group(group, "Pilih versi: ")


def update_tfvars(values: dict[str, str]) -> None:
    if not TFVARS_PATH.exists():
        raise FileNotFoundError(f"File tidak ditemukan: {TFVARS_PATH}")

    content = TFVARS_PATH.read_text(encoding="utf-8")

    for key, value in values.items():
        pattern = rf'^{re.escape(key)}\s*=\s*".*"$'
        replacement = f'{key} = "{value}"'
        content, count = re.subn(pattern, replacement, content, flags=re.MULTILINE)

        if count == 0:
            content += f'\n{replacement}'

    TFVARS_PATH.write_text(content.rstrip() + "\n", encoding="utf-8")


def detect_public_ip() -> str | None:
    services = (
        "https://checkip.amazonaws.com",
        "https://api.ipify.org",
    )

    for service in services:
        try:
            with urllib.request.urlopen(service, timeout=5) as response:
                ip = response.read().decode("utf-8").strip()
            if re.fullmatch(r"\d{1,3}(?:\.\d{1,3}){3}", ip):
                return ip
        except (urllib.error.URLError, TimeoutError, ValueError):
            continue

    return None


def choose_my_ip() -> str:
    print_section("Konfigurasi akses SSH")
    detected_ip = detect_public_ip()

    if detected_ip:
        default_cidr = f"{detected_ip}/32"
        print_info(f"IP publik terdeteksi: {detected_ip}")
        while True:
            value = input(
                f"Masukkan CIDR akses SSH {color(f'[{default_cidr}]', Style.DIM)}: "
            ).strip() or default_cidr
            try:
                ipaddress.ip_network(value, strict=False)
                return value
            except ValueError:
                print_warning("Format CIDR tidak valid. Contoh: 203.0.113.10/32")

    print_warning("IP publik tidak berhasil dideteksi otomatis.")
    print_info("Contoh aman: 203.0.113.10/32")
    while True:
        value = input("Masukkan CIDR untuk akses SSH: ").strip()
        if not value:
            print_warning("Nilai tidak boleh kosong jika deteksi otomatis gagal.")
            continue
        try:
            ipaddress.ip_network(value, strict=False)
            return value
        except ValueError:
            print_warning("Format CIDR tidak valid. Contoh: 203.0.113.10/32")


def run_terraform() -> None:
    print()
    print_success("Menjalankan Terraform...")
    subprocess.run(["terraform", "init"], cwd=BASE_DIR, check=True)
    subprocess.run(["terraform", "apply"], cwd=BASE_DIR, check=True)


def main() -> None:
    print_banner()
    print_info("Pastikan Terraform dan AWS CLI sudah terinstal.")
    print_info("Pastikan kredensial AWS CLI sudah dikonfigurasi dengan 'aws configure'.")

    print_section("Identitas instance")
    instance_name = prompt_with_default("Nama instance", "web-server-prod")
    aws_region = choose_region()
    instance_type = choose_instance_type()
    os_version = choose_os_version()
    my_ip = choose_my_ip()

    update_tfvars(
        {
            "instance_name": instance_name,
            "aws_region": aws_region,
            "instance_type": instance_type,
            "os_version": os_version,
            "my_ip": my_ip,
        }
    )

    print_section("Ringkasan konfigurasi")
    summary_rows = (
        ("Instance name", instance_name),
        ("AWS region", aws_region),
        ("Instance type", instance_type),
        ("Operating system", os_version),
        ("SSH source CIDR", my_ip),
    )
    label_width = max(len(label) for label, _ in summary_rows)
    for label, value in summary_rows:
        print(f"  {color(label.ljust(label_width), Style.DIM)} : {value}")

    print_section("Langkah berikutnya")
    print(f"  {color('1.', Style.CYAN)} Deploy sekarang")
    print(f"  {color('2.', Style.CYAN)} Keluar")
    deploy_choice = input("Pilih opsi [1-2]: ").strip()

    if deploy_choice == "1":
        run_terraform()
    else:
        print_info("Setup selesai. Anda bisa menjalankan 'terraform apply' nanti.")


if __name__ == "__main__":
    main()
