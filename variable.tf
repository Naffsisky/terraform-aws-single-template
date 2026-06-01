variable "instance_name" {
  description = "Nama EC2 instance (juga dipakai sebagai workspace name)"
  type        = string
  default     = "terraform-web"
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "ssh_public_key_path" {
  description = "Path ke SSH public key (shared untuk semua deployment)"
  type        = string
  default     = "~/.ssh/terraform-aws-key.pub"
}

variable "my_ip" {
  description = "Your public IP address for SSH access"
  type        = string
}

variable "os_version" {
  type        = string
  description = "Operating system version for the EC2 instance"
  default     = "ubuntu-22"
}