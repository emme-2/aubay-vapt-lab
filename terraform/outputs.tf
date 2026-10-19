output "server_ipv4" {
  description = "IP pubblico del server."
  value       = hcloud_server.lab.ipv4_address
}

output "server_status" {
  description = "Stato del server."
  value       = hcloud_server.lab.status
}

output "guacamole_url" {
  description = "URL di accesso alla demo (raggiungibile solo da admin_source_ips)."
  value       = "https://${hcloud_server.lab.ipv4_address}/guacamole/"
}

output "dashboard_url" {
  description = "Dashboard VA/PT brandizzata (solo admin)."
  value       = "https://${hcloud_server.lab.ipv4_address}/dashboard/"
}

output "openvas_web_url" {
  description = "Console web OpenVAS per i colleghi (solo admin, cert self-signed)."
  value       = "https://${hcloud_server.lab.ipv4_address}:9443/"
}

output "ssh_command" {
  description = "Comando per connettersi al server."
  value       = "ssh -i ${var.ssh_private_key_path} root@${hcloud_server.lab.ipv4_address}"
}

output "allowed_admin_ips" {
  description = "IP attualmente autorizzati dal firewall."
  value       = var.admin_source_ips
}
