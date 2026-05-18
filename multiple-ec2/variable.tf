variable "instance_name" {
  description = "Nama EC2 instance"
  type        = string
  default     = "terraform-web"
}

variable "vm_count" {
  description = "Jumlah EC2 instance yang akan dibuat"
  type        = number
  default     = 1
}

variable "aws_region" {
  description = "AWS region"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Existing AWS key pair name"
  type        = string
  default     = "ubuntu-lab-key"
}

variable "my_ip" {
  description = "Your public IP address for SSH access"
  type        = string
}

variable "os_version" {
  type        = string
  description = "Operating system version for the EC2 instance"
  default     = "ubuntu"
}