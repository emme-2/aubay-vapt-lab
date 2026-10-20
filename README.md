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

### Fase 4 — motore VA/PT + connessioni Guacamole

```bash
make configure         # ora builda anche redteam (Kali) e avvia blueteam (OpenVAS)
make seed-guac         # crea in Guacamole le connessioni SSH (usa GUAC_PASS=... se l'hai cambiata)
```

Nodi aggiunti:

| Rete | Host | Cosa |
|---|---|---|
| cyber | `redteam.corp.local` (172.20.30.10) | Kali: nmap, hydra, sqlmap, ffuf, gobuster, Metasploit, Nuclei, Trivy |
| cyber | `blueteam.corp.local` (172.20.30.20) | OpenVAS/GVM |

**Collaudo:** apri Guacamole, connettiti a **redteam (Kali)** e prova:

```bash
nmap -sV web.corp.local
nuclei -u http://web.corp.local
hydra -L /opt/wordlists/users.txt -P /opt/wordlists/passwords.txt ws01.corp.local ssh
```

> **OpenVAS** sincronizza il feed NVT al primo avvio: **30-60+ minuti**.
> Segui l'avanzamento con `docker logs -f vapt-openvas`.

**Accesso a OpenVAS — due modi:**

| Chi | Come | Dettagli |
|---|---|---|
| Tu (serve la chiave SSH) | `make openvas` | Tunnel SSH → `http://localhost:9392` |
| Colleghi / spettatori | browser → `https://<IP>:9443/` | Reverse proxy TLS, ristretto agli IP del firewall |

> La porta **9443** va aperta nel firewall (lo fa `make provision` dopo questa
> modifica) ed è limitata agli stessi `admin_source_ips`. Certificato
> self-signed: il browser avvisa, si procede comunque. Login: `admin` /
> `LabOpenVAS-2026`. Perché i colleghi lo vedano, il loro IP dev'essere tra
> quelli autorizzati (`make allow-ip IP="...,..."`).

### Fase 5 — dashboard + runbook demo

```bash
make configure          # pubblica la dashboard sotto /dashboard/
make scan PHASE=before   # scansione VA → popola la baseline
make harden             # applica la remediation sul proxy
make scan PHASE=after    # ri-scansione → mostra il delta
make restore            # riporta il proxy allo stato vulnerabile (reset)
```

- **Dashboard** (business): `https://<IP>/dashboard/` — severità e confronto
  Prima/Dopo, si auto-aggiorna dopo ogni `make scan`.
- **Runbook della demo:** [`docs/DEMO-RUNBOOK.md`](docs/DEMO-RUNBOOK.md) — il
  copione passo-passo da seguire in sala, con i comandi pronti.

### Fase 6a — desktop grafico per il walk-through

```bash
make configure          # builda e avvia il desktop (vapt-desktop)
make seed-guac          # aggiunge la connessione VNC "Desktop utente" in Guacamole
```

In Guacamole trovi la connessione **"Desktop utente (walk-through)"**: è un
desktop XFCE con un browser già aperto sulla **pagina di lancio** (bottoni verso
il portale web e lo shop). Serve a mostrare l'ambiente a personale **non tecnico**,
senza terminali né codice.

### Fase 6b — posta: IMAP + client sul desktop

Il server `mail` ora ha anche **Dovecot (IMAP)** e caselle precaricate; il desktop
ha **Thunderbird** già configurato sulla casella `jdoe@corp.local`.

```bash
make configure         # ricostruisce mail (IMAP) e desktop (Thunderbird)
```

> **Una tantum in prep:** al primo avvio Thunderbird chiede la password della
> casella → inserisci `Password1` e spunta *ricorda password*. Resta salvata
> (volume `desktop_tb`), anche dopo un riavvio dei container.

Le 3 mail di `jdoe` includono una con credenziali in chiaro: gancio narrativo per
il tema "dove vivono i dati sensibili". Login IMAP: `jdoe` / `Password1`.

Con queste fasi il lab è completo per la parte tecnica e visiva.

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
