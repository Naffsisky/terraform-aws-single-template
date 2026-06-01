locals {
  ssh_user         = length(regexall("^debian", var.os_version)) > 0 ? "admin" : "ubuntu"
  private_key_path = "~/.ssh/terraform-aws-key.pem"
}

output "workspace_name" {
  description = "Nama workspace Terraform (identifier deployment)"
  value       = terraform.workspace
}

output "instance_id" {
  value = aws_instance.web.id
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "public_dns" {
  value = aws_instance.web.public_dns
}

output "instance_type" {
  value = aws_instance.web.instance_type
}

output "availability_zone" {
  value = aws_instance.web.availability_zone
}

output "ssh_user" {
  description = "SSH user sesuai OS"
  value       = local.ssh_user
}

output "ssh_command" {
  description = "Langsung copy-paste untuk SSH"
  value       = "ssh -i ${local.private_key_path} ${local.ssh_user}@${aws_instance.web.public_ip}"
}

output "private_key_path" {
  description = "Lokasi private key"
  value       = local.private_key_path
}

output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}