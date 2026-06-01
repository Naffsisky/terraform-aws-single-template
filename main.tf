terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ── SSH Key Pair (dari file lokal, dibuat oleh setup.sh) ─────
resource "aws_key_pair" "deploy_key" {
  key_name   = "terraform-${terraform.workspace}"
  public_key = file(var.ssh_public_key_path)
}

# ── AMI Lookup ───────────────────────────────────────────────
data "aws_ami" "selected_os" {
  most_recent = true
  owners      = length(regexall("^debian", var.os_version)) > 0 ? ["136693071363"] : ["099720109477"]

  filter {
    name = "name"
    values = [
      var.os_version == "ubuntu-20" ? "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*" :
      var.os_version == "ubuntu-22" ? "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*" :
      var.os_version == "ubuntu-24" ? "ubuntu/images/hvm-ssd/ubuntu-noble-24.04-amd64-server-*" :
      var.os_version == "debian-11" ? "debian-11-amd64-*" :
      var.os_version == "debian-12" ? "debian-12-amd64-*" :
      "ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"
    ]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

# ── Security Group ───────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "terraform-web-${terraform.workspace}"
  description = "Allow SSH and HTTP - ${terraform.workspace}"

  ingress {
    description = "SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.my_ip]
  }

  ingress {
    description = "HTTP from internet"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS from internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Open all tcp ports"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Open all udp ports"
    from_port   = 0
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.instance_name}-security-group"
  }
}

# ── EC2 Instance ─────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = data.aws_ami.selected_os.id
  instance_type          = var.instance_type
  key_name               = aws_key_pair.deploy_key.key_name
  vpc_security_group_ids = [aws_security_group.web.id]
  user_data              = file("${path.module}/userdata.sh.tpl")

  tags = {
    Name = var.instance_name
  }
}
