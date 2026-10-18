# Aubay VA/PT Demo Lab

Laboratorio didattico/dimostrativo per **Vulnerability Assessment** e
**Penetration Test** con strumenti open, su un singolo host Hetzner Cloud,
interamente definito come codice (Terraform + Ansible + Docker).

> Documentazione completa (scopo, topologia, scelte, sicurezza):
> **[`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md)** — la Knowledge del lab.

> ⚠️ **Ambiente deliberatamente vulnerabile.** Uso esclusivo nel lab isolato.
> Gli strumenti offensivi si puntano solo sui target fittizi interni.

---

## Prerequisiti (sul tuo PC)

- **Terraform** ≥ 1.5
- **Ansible** (serve per la fase di configurazione — prossimo deliverable)
- Una **coppia di chiavi SSH** (es. `~/.ssh/id_ed25519`)
- **curl** (per `make my-ip`)
- Un **token API Hetzner Cloud** (Read & Write) e account verificato con metodo di pagamento

> Su Windows usa **WSL** per avere `make`, `terraform`, `ansible` e `ssh`.

## Avvio rapido

```bash
# 1. Scopri il tuo IP pubblico
make my-ip

# 2. Prepara le variabili
cp terraform/terraform.tfvars.example terraform/terraform.tfvars
#    → incolla il token e l'IP (/32) ottenuto sopra

# 3. Inizializza e crea l'infrastruttura
make init
make provision        # crea server CCX33 + firewall + chiave SSH

# 4. Verifica
make status           # IP, URL Guacamole, stato
make ssh              # entra nel server
```

### Fase 2 — configurazione host + accesso Guacamole

Una volta provisionato il server:

```bash
make configure        # Ansible: Docker, le 3 reti, Guacamole dietro Nginx/TLS
```

Poi apri nel browser l'URL mostrato da `make status`
(`https://<IP>/guacamole/`) e fai login con `guacadmin` / `guacadmin`
(⚠ cambia la password al primo accesso). Accetta l'avviso del certificato
self-signed: è atteso.

> Requisito: **Ansible** installato in WSL (`sudo apt install -y ansible`).
> Non servono collection extra.

### Fase 3 — i target (azienda-cliente da attaccare)

```bash
make configure        # ora crea anche DVWA, Juice Shop, proxy, mail, ws01, ws02
make check-targets     # verifica che rispondano sulle reti interne
```

Target creati:

| Rete | Host | Servizio |
|---|---|---|
| datacenter | `proxy.corp.local` (172.20.10.10) | Nginx reverse proxy (bastione) |
| datacenter | `web.corp.local` (172.20.10.20) | DVWA |
| datacenter | `juice.corp.local` (172.20.10.21) | OWASP Juice Shop |
| datacenter | `mail.corp.local` (172.20.10.30) | Postfix (SMTP) |
| utenti | `ws01.corp.local` (172.20.20.11) | Workstation — SSH debole (`jdoe`/`Password1`) |
| utenti | `ws02.corp.local` (172.20.20.12) | Workstation — SSH debole (`mrossi`/`qwerty`) |

> **DVWA:** al primo uso va inizializzato una volta da `http://web.corp.local/setup.php`
> (login `admin`/`password`). Lo faremo nel runbook della demo.
> Le credenziali deboli sono **volute** e servono alla dimostrazione del PT.

I tool VA/PT (OpenVAS, Nuclei, Trivy, toolbox red team) arrivano con la Fase 4.

## Prima della demo: aggiornare l'IP ammesso

L'unico accesso pubblico è Guacamole/SSH, ristretto all'IP in `admin_source_ips`.
Quando conosci l'IP della sede:

```bash
# modo stabile: aggiorna admin_source_ips in terraform.tfvars, poi
make provision        # aggiorna solo il firewall, NON ricrea il server

# oppure al volo:
make allow-ip IP=203.0.113.7
```

## Fine demo: spegnere i costi

```bash
make destroy          # elimina il server (su Hetzner si paga finché esiste)
```

## Struttura

```
docs/ARCHITECTURE.md   Knowledge base del lab
terraform/             Provisioning Hetzner (server, firewall, SSH, inventario)
ansible/               Configurazione host (in arrivo)
docker/                Target e tool (in arrivo)
dashboard/             Dashboard demo (in arrivo)
Makefile               Comandi (make help)
```
