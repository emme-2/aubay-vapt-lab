# =====================================================================
#  Aubay VA/PT Demo Lab — comandi
#  Uso:  make help
# =====================================================================

TF := terraform -chdir=terraform

.DEFAULT_GOAL := help
GUAC_USER ?= guacadmin
GUAC_PASS ?= guacadmin
DESKTOP_VNC ?= demo

.PHONY: help my-ip init plan provision configure deploy allow-ip status ssh check-targets seed-guac scan harden restore openvas destroy

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

allow-ip: ## Autorizza una o più sorgenti al volo. Uso: make allow-ip IP=1.2.3.4  oppure  IP="1.2.3.4, 5.6.7.8/32, 10.0.0.0/24"
	@test -n "$(IP)" || { echo 'Uso: make allow-ip IP="1.2.3.4, 5.6.7.8/32"'; exit 1; }
	@list=$$(echo "$(IP)" | tr ',' '\n' | tr -d ' ' | awk 'NF{ if ($$0 ~ /\//) printf "\"%s\",", $$0; else printf "\"%s/32\",", $$0 }' | sed 's/,$$//'); \
	echo ">> Autorizzo nel firewall: [$$list]"; \
	$(TF) apply -auto-approve -target=hcloud_firewall.lab -var="admin_source_ips=[$$list]"
	@echo ">> Nota: è una modifica temporanea. Per renderla stabile, aggiorna admin_source_ips in terraform.tfvars (è una lista) e usa 'make provision'."

status: ## Mostra IP, URL Guacamole e stato
	@$(TF) output

check-targets: ## Verifica che i target rispondano sulle reti interne (via SSH)
	@$$($(TF) output -raw ssh_command) 'bash -s' < scripts/check-targets.sh

seed-guac: ## Crea in Guacamole le connessioni SSH ai nodi (GUAC_PASS=... se cambiata)
	@$$($(TF) output -raw ssh_command) 'bash -s -- $(GUAC_USER) $(GUAC_PASS) $(DESKTOP_VNC)' < scripts/seed-guacamole.sh

openvas: ## Apre la console web OpenVAS via tunnel SSH su http://localhost:9392
	@ip=$$($(TF) output -raw server_ipv4); key=$$(grep -E 'ssh_private_key_path' terraform/terraform.tfvars 2>/dev/null | sed 's/.*=//; s/ *//g; s/\"//g'); key=$${key:-~/.ssh/id_ed25519}; \
	echo ">> Tunnel aperto. Apri nel browser:  http://localhost:9392"; \
	echo ">> Login OpenVAS: admin / LabOpenVAS-2026   (CTRL-C per chiudere il tunnel)"; \
	ssh -i $$key -N -L 9392:127.0.0.1:9392 root@$$ip

scan: ## Scansione VA e aggiornamento dashboard. Uso: make scan PHASE=before|after
	@$$($(TF) output -raw ssh_command) 'bash -s -- $(or $(PHASE),before)' < scripts/scan.sh

harden: ## Applica la remediation sul proxy (per la fase "dopo")
	@$$($(TF) output -raw ssh_command) 'cd /opt/vapt-lab/targets && \
	  [ -f proxy/nginx.conf.orig ] || cp proxy/nginx.conf proxy/nginx.conf.orig && \
	  cp proxy/nginx-hardened.conf proxy/nginx.conf && \
	  docker exec vapt-proxy nginx -s reload && echo ">> Proxy hardening applicato."'

restore: ## Ripristina il proxy vulnerabile (reset demo)
	@$$($(TF) output -raw ssh_command) 'cd /opt/vapt-lab/targets && \
	  [ -f proxy/nginx.conf.orig ] && cp proxy/nginx.conf.orig proxy/nginx.conf && \
	  docker exec vapt-proxy nginx -s reload && echo ">> Proxy ripristinato allo stato vulnerabile." || echo "Nessun backup: proxy già allo stato originale."'

ssh: ## Connessione SSH al server
	@eval "$$($(TF) output -raw ssh_command)"

destroy: ## DISTRUGGE tutto (stop costi Hetzner)
	$(TF) destroy
