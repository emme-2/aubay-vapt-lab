# =====================================================================
#  Infrastruttura Hetzner — Aubay VA/PT Demo Lab
#
#  Crea: chiave SSH, firewall cloud (solo admin), server CCX33.
#  Genera inoltre l'inventario Ansible con l'IP pubblico assegnato.
#
#  ⚠  Ambiente DELIBERATAMENTE vulnerabile: l'unico accesso pubblico è
#     Guacamole/SSH ristretto ad admin_source_ips. Nessun target esposto.
# =====================================================================

# --- Chiave SSH: carica la pubblica locale nel progetto Hetzner ---
resource "hcloud_ssh_key" "admin" {
  name       = var.ssh_key_name
  public_key = file(pathexpand(var.ssh_public_key_path))
}

# --- Firewall cloud: default-deny in ingresso, solo admin passa ---
resource "hcloud_firewall" "lab" {
  name = "${var.server_name}-fw"

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "443"
    source_ips  = var.admin_source_ips
    description = "Guacamole HTTPS (solo admin)"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "22"
    source_ips  = var.admin_source_ips
    description = "SSH admin/Ansible (solo admin)"
  }

  rule {
    direction   = "in"
    protocol    = "tcp"
    port        = "9443"
    source_ips  = var.admin_source_ips
    description = "OpenVAS console web via reverse proxy TLS (solo admin)"
  }

  rule {
    direction   = "in"
    protocol    = "icmp"
    source_ips  = var.admin_source_ips
    description = "ICMP ping (solo admin)"
  }
  # Tutto il resto in ingresso è scartato di default dal firewall Hetzner.
  # L'uscita è libera: il server deve scaricare immagini Docker e feed NVT.
}

# --- Il server del lab ---
resource "hcloud_server" "lab" {
  name         = var.server_name
  server_type  = var.server_type
  image        = var.image
  location     = var.location
  ssh_keys     = [hcloud_ssh_key.admin.id]
  firewall_ids = [hcloud_firewall.lab.id]
  user_data    = file("${path.module}/cloud-init.yaml")

  labels = {
    project = "aubay-vapt-lab"
    purpose = "demo"
  }
}

# --- Inventario Ansible generato con l'IP assegnato ---
resource "local_file" "ansible_inventory" {
  filename        = "${path.module}/../ansible/inventory.ini"
  file_permission = "0644"
  content         = <<-EOT
    # File generato da Terraform — non modificare a mano.
    [lab]
    ${hcloud_server.lab.ipv4_address}

    [lab:vars]
    ansible_user=root
    ansible_ssh_private_key_file=${var.ssh_private_key_path}
    ansible_python_interpreter=/usr/bin/python3
  EOT
}
