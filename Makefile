# =====================================================================
#  Aubay VA/PT Demo Lab — comandi
#  Uso:  make help
# =====================================================================

TF := terraform -chdir=terraform

.DEFAULT_GOAL := help
.PHONY: help my-ip init plan provision configure deploy allow-ip status ssh destroy

help: ## Mostra questo aiuto
	@echo "Aubay VA/PT Demo Lab"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | \
	  awk 'BEGIN {FS = ":.*?## "}; {printf "  \033[36m%-12s\033[0m %s\n", $$1, $$2}'
	@echo ""
	@echo "Flusso tipico:  make my-ip  ->  compila terraform.tfvars  ->  make deploy"

my-ip: ## Stampa il tuo IP pubblico attuale in formato /32
	@echo "IP pubblico attuale:  $$(curl -fsS https://ipv4.icanhazip.com)/32"

init: ## Inizializza Terraform (prima volta / dopo cambi di provider)
	$(TF) init

plan: ## Anteprima delle modifiche
	$(TF) plan

provision: ## Crea/aggiorna l'infrastruttura (server, firewall, chiave SSH)
	$(TF) apply

configure: ## Configura l'host con Ansible (servizi + tool)
	@test -f ansible/playbook.yml || { \
	  echo ">> Playbook Ansible non ancora presente (prossimo deliverable)."; \
	  echo ">> Il server è comunque provisionato: usa 'make status' e 'make ssh'."; \
	  exit 0; }
	cd ansible && ansible-playbook -i inventory.ini playbook.yml

deploy: provision configure ## Deploy completo: infrastruttura + configurazione

allow-ip: ## Aggiorna al volo l'IP ammesso dal firewall. Uso: make allow-ip IP=1.2.3.4
	@test -n "$(IP)" || { echo "Uso: make allow-ip IP=1.2.3.4"; exit 1; }
	$(TF) apply -auto-approve -target=hcloud_firewall.lab \
	  -var='admin_source_ips=["$(IP)/32"]'
	@echo ">> Firewall aggiornato a $(IP)/32. Ricordati di aggiornare anche terraform.tfvars per renderlo stabile."

status: ## Mostra IP, URL Guacamole e stato
	@$(TF) output

ssh: ## Connessione SSH al server
	@eval "$$($(TF) output -raw ssh_command)"

destroy: ## DISTRUGGE tutto (stop costi Hetzner)
	$(TF) destroy
