locals {
  ssh_user = length(regexall("^debian", var.os_version)) > 0 ? "admin" : "ubuntu"
}

output "instance_ids" {
  value = aws_instance.web[*].id
}

output "public_ips" {
  value = aws_instance.web[*].public_ip
}

output "public_dns" {
  value = aws_instance.web[*].public_dns
}

output "instance_type" {
  value = var.instance_type
}

output "availability_zones" {
  value = aws_instance.web[*].availability_zone
}

output "ssh_user" {
  description = "SSH user sesuai OS"
  value       = length(regexall("^debian", var.os_version)) > 0 ? "admin" : "ubuntu"
}

output "ssh_commands" {
  description = "SSH command untuk setiap instance"
  value = [
    for i, instance in aws_instance.web :
    "ssh -i ${var.key_name}.pem ${local.ssh_user}@${instance.public_ip}  # ${var.instance_name}-${i + 1}"
  ]
}

output "key_name" {
  description = "Nama key pair"
  value       = var.key_name
}

output "website_urls" {
  value = [for instance in aws_instance.web : "http://${instance.public_ip}"]
}