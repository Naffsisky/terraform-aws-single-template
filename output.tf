locals {
  ssh_user = length(regexall("^debian", var.os_version)) > 0 ? "admin" : "ubuntu"
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

output "ssh_command" {
  description = "Langsung copy-paste untuk SSH"
  value       = "ssh -i ${path.module}/${var.key_name}.pem ${local.ssh_user}@${aws_instance.web.public_ip}"
}

output "private_key_path" {
  description = "Lokasi private key"
  value       = "${path.module}/${var.key_name}.pem"
}

output "website_url" {
  value = "http://${aws_instance.web.public_ip}"
}