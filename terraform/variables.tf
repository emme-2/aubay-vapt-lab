# =====================================================================
#  Variabili del provisioning Hetzner — Aubay VA/PT Demo Lab
#  I valori si impostano in terraform.tfvars (copia da .example).
# =====================================================================

variable "hcloud_token" {
  description = "Token API Hetzner Cloud (permessi Read & Write)."
  type        = string
  sensitive   = true
}

variable "admin_source_ips" {
  description = <<-EOT
    Lista CIDR autorizzati a raggiungere SSH (22) e Guacamole HTTPS (443).
    È l'UNICO accesso esposto su Internet; i target vulnerabili NON sono
    mai pubblici. In prep: il tuo IP attuale (vedi `make my-ip`) come /32.
    Prima della demo: l'IP della sede. Aggiornarlo tocca solo il firewall,
    non ricrea il server.
  EOT
  type        = list(string)

  validation {
    condition     = length(var.admin_source_ips) > 0
    error_message = "Imposta almeno un IP/CIDR in admin_source_ips, altrimenti resti chiuso fuori."
  }
}

variable "ssh_public_key_path" {
  description = "Percorso della chiave SSH PUBBLICA locale da caricare su Hetzner."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

variable "ssh_private_key_path" {
  description = "Percorso della chiave SSH PRIVATA locale (usata da Ansible nell'inventario)."
  type        = string
  default     = "~/.ssh/id_ed25519"
}

variable "ssh_key_name" {
  description = "Nome con cui la chiave compare nel progetto Hetzner."
  type        = string
  default     = "aubay-vapt-lab"
}

variable "location" {
  description = "Location Hetzner: fsn1=Falkenstein(DE), nbg1=Norimberga(DE), hel1=Helsinki(FI)."
  type        = string
  default     = "fsn1"
}

variable "server_type" {
  description = "Tipo di server. CCX33 = 8 vCPU dedicati, 32 GB RAM, 240 GB NVMe."
  type        = string
  default     = "ccx33"
}

variable "image" {
  description = "Immagine base del sistema operativo (LTS più recente offerta da Hetzner)."
  type        = string
  default     = "ubuntu-26.04"
}

variable "server_name" {
  description = "Nome del server (e prefisso di firewall/label)."
  type        = string
  default     = "vapt-lab"
}
