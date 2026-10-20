# Aubay VA/PT Demo Lab — Documento di Architettura

> **Knowledge base del laboratorio.** Questo documento è la fonte di verità su
> *cosa* costruiamo, *come* è fatto e *perché* abbiamo preso ogni decisione.
> Il codice (Terraform / Ansible / Docker Compose) implementa quanto descritto qui.
>
> **Versione:** 0.1 — 2026-10-18 · **Owner:** Matteo (Aubay, Network & Security)
> **Scopo:** demo live di Vulnerability Assessment e Penetration Test per un
> partner di Digital Advisory.

---

## 1. Scopo e narrativa

L'obiettivo della demo è mostrare a un partner di Digital Advisory le capacità
Aubay in ambito **VA (Vulnerability Assessment)** e **PT (Penetration Test)**,
così da essere proposti come braccio tecnico durante le loro consulenze ai clienti.

**Posizionamento (filo conduttore di tutta la demo):**

> Usiamo **strumenti open** per costruire e mantenere competenza interna in modo
> **vendor-agnostic**. Sul singolo progetto reale, insieme al cliente, si sceglie
> il prodotto *paid* più adatto al contesto **oppure** si integra e si valorizza
> ciò che il cliente ha già in casa.

Questo messaggio è strategico: non mette Aubay in competizione frontale con i
prodotti del cliente o del partner, ma la rende il partner tecnico credibile che
sa *fare*, non solo rivendere.

## 2. Audience e formato della demo

| Aspetto | Scelta | Conseguenza di design |
|---|---|---|
| Formato | **Live, guidata da Matteo** | Ogni comando dev'essere **deterministico e ripetibile**: nessun esito incerto in sala. |
| Audience | **Mista business + tecnico** | Serve profondità tecnica *e* almeno un momento "wow" leggibile dal business (dashboard, numeri, prima/dopo). |
| Provider | **Hetzner Cloud CCX33** | vCPU dedicati → performance prevedibile durante la live; RAM abbondante per OpenVAS. |

**Principio guida n.1:** *in una demo live, la cosa più costosa è l'imprevisto.*
Tutto ciò che mostriamo è preparato per avere un esito noto. I target sono
vulnerabili **per costruzione**, le credenziali deboli sono **impostate da noi**,
i feed di sicurezza sono **pre-sincronizzati** in fase di build.

## 3. Decisioni architetturali chiave (e perché)

### 3.1 Container-first, non VM

I target "macchina" (workstation, host del datacenter) sono **container completi**
— con `systemd` e `sshd` reali — non VM KVM.

**Perché:** per una demo VA/PT tutto ciò che vogliamo mostrare (scan di rete,
brute force SSH, exploit di servizio, SQL injection, lateral movement) funziona in
modo identico contro un servizio esposto da un container. Gli unici attacchi che
richiederebbero VM vere sono gli **exploit a livello kernel / privilege escalation
kernel**, che *non* sono nel canovaccio della prima demo. In cambio otteniamo:
portabilità totale, ricostruzione rapida, footprint ridotto, IaC pulita.

**Opzione di riserva:** il CCX33 ha vCPU dedicati e nested-virt disponibile, quindi
se in futuro servisse un target che richiede una VM vera (es. un exploit kernel
specifico), possiamo aggiungere un nodo KVM senza cambiare provider.

> ⚠️ **Nota di onestà tecnica:** nella fase di brainstorming era emersa l'idea
> "VM realistiche". La rivalutazione ha portato al modello container-first perché
> offre lo stesso valore dimostrativo con molta meno fragilità. Il CCX33 resta la
> scelta corretta per il motivo della performance deterministica, non per la nested
> virtualization.

### 3.2 Host unico vs multi-host

Un **singolo host** (CCX33) ospita tutto. Le "3 aree" sono **reti Docker isolate**,
non macchine separate. Vantaggi: costo minimo, zero latenze di rete reali tra le
zone, deploy/destroy atomico. La segmentazione tra zone è reale a livello di rete
Docker e ci permette comunque di raccontare (e dimostrare) il **lateral movement**
e la **segmentazione**.

### 3.3 Infrastructure as Code su due livelli

- **Terraform** → provisiona l'infrastruttura *esterna*: il server su Hetzner, la
  chiave SSH, il firewall cloud. Output: l'IP pubblico e l'inventario per Ansible.
- **Ansible** → configura tutto *dentro* l'host: hardening base, Docker, le reti,
  Apache Guacamole, i servizi, i tool, i dati vulnerabili precaricati.
- **Docker Compose** → definisce i singoli container (target e tool), orchestrati
  da Ansible.

Un `make deploy` crea tutto da zero; un `make destroy` lo elimina. La ripetibilità
è essa stessa un argomento di vendita: *"guardate, ricreo l'intero ambiente da
codice in pochi minuti, nessun lock-in."*

## 4. Host e provider

| Parametro | Valore |
|---|---|
| Provider | Hetzner Cloud |
| Tipo | **CCX33** (vCPU dedicati) |
| Risorse | 8 vCPU dedicati · 32 GB RAM · 240 GB NVMe |
| Location | Falkenstein (DE), Norimberga (DE) o Helsinki (FI) — data residency UE |
| Costo | ~€138/mese di listino (IVA escl.), **fatturato a ore** (~€0,19/h) |
| Costo reale demo | ~€32 netti (~€39 IVA incl.) per una settimana di prep + demo day |
| OS | Ubuntu Server 26.04 LTS |

**Modello di costo (da capire bene):** su Hetzner Cloud un server **spento continua
a costare** finché *esiste*. Si smette di pagare solo con la **cancellazione**
(`terraform destroy`). Strategie:

1. **Semplice (consigliata per la demo):** crea il server, tienilo su per la
   settimana di lavoro, `destroy` alla fine. Costo ~€32 netti.
2. **Ricreazione veloce:** prima del `destroy`, crea uno **snapshot** (costo
   snapshot ~€0,0119/GB/mese, trascurabile). Al bisogno ricrei da snapshot invece
   che da zero — utile se devi replicare la demo a distanza di settimane.

## 5. Topologia di rete

Tre reti Docker isolate rappresentano le tre aree aziendali:

```
┌───────────────────────────────────────────────────────────────────────┐
│                       HOST — Hetzner CCX33 (Ubuntu 24.04)               │
│                                                                         │
│   ░░ Accesso: Apache Guacamole (HTTPS) ░░  ◀── unico ingresso per te   │
│                                                                         │
│   ┌─────────────────────── RETE DATACENTER (172.20.10.0/24) ─────────┐ │
│   │  proxy.corp.local   172.20.10.10   Nginx reverse proxy (target)  │ │
│   │  web.corp.local     172.20.10.20   DVWA + OWASP Juice Shop       │ │
│   │  mail.corp.local    172.20.10.30   Mailserver (SMTP/IMAP)        │ │
│   └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│   ┌─────────────────────── RETE UTENTI (172.20.20.0/24) ─────────────┐ │
│   │  ws01.corp.local    172.20.20.11   Workstation Linux + SSH       │ │
│   │  ws02.corp.local    172.20.20.12   Workstation + SSH debole      │ │
│   └──────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│   ┌─────────────────────── RETE CYBER (172.20.30.0/24) ──────────────┐ │
│   │  redteam   172.20.30.10   Toolbox offensiva (nmap, hydra, msf…)  │ │
│   │  blueteam  172.20.30.20   OpenVAS/GVM + Nuclei                   │ │
│   │  dashboard 172.20.30.30   Pagina web riassuntiva della demo      │ │
│   └──────────────────────────────────────────────────────────────────┘ │
└───────────────────────────────────────────────────────────────────────┘
```

**Raggiungibilità (routing tra zone):** la rete CYBER ha visibilità verso
DATACENTER e UTENTI (è il punto di osservazione di red/blue team). La narrativa di
segmentazione si mostra partendo da una workstation "compromessa" nella rete UTENTI
e pivotando verso il DATACENTER. I dettagli di routing (gateway/regole) sono
implementati in Ansible; il piano IP sopra è fisso e stabile.

> I nomi `*.corp.local` sono risolti internamente così da raccontare uno scenario
> aziendale realistico invece di lavorare su indirizzi IP nudi.

## 6. Componenti

### 6.1 Layer di accesso — Apache Guacamole

**Ruolo: porta d'ingresso alla demo, NON un target.** Guacamole è un gateway
clientless (solo browser, HTTPS) che ti dà in un'unica scheda i desktop/terminali
di redteam, blueteam e delle macchine. In sala apri il browser e hai tutto, senza
distribuire chiavi SSH o client RDP.

> **Chiarimento rispetto al brainstorming:** nel primo scambio Guacamole era stato
> ipotizzato come "bastione/reverse proxy" dentro il datacenter da attaccare. Sono
> due cose diverse: Guacamole = *tuo* strumento di accesso; il "reverse proxy
> bersaglio" è invece **Nginx** (§6.2), che sì viene analizzato.

### 6.2 Area DATACENTER (i target "server")

| Host | Componente | Perché è lì / cosa si dimostra |
|---|---|---|
| `proxy` | **Nginx** reverse proxy davanti al web | Target di analisi: header di sicurezza, misconfig TLS, path traversal. Realismo del "bastione". |
| `web` | **DVWA** + **OWASP Juice Shop** | Cavallo di battaglia della demo. DVWA: livelli di sicurezza → arco "prima/dopo". Juice Shop: app moderna SPA/API, credibilità visiva. |
| `mail` | **docker-mailserver** (Postfix + Dovecot) | Target per enumerazione SMTP, check open-relay, user enumeration. |

### 6.3 Area UTENTI (le workstation "vittima")

Container Linux con `sshd` reale e credenziali deboli impostate da noi, più un paio
di servizi datati. Bersagli di **brute force SSH** e punto di partenza del
**lateral movement**.

### 6.4 Area CYBER (i nodi di lavoro)

- **redteam** — toolbox offensiva (vedi §7): è da qui che piloti gli attacchi.
- **blueteam** — scanner VA (OpenVAS/GVM + Nuclei): fotografa il rischio.
- **dashboard** — pagina web che traduce i risultati in linguaggio-rischio
  (numeri, severità, prima/dopo) per l'audience business.

## 7. Stack strumenti

### 7.1 Blue team / VA

| Tool | Ruolo | Note operative |
|---|---|---|
| **OpenVAS / GVM** | VA completo, "fa scena da tecnico" | Pesante; il feed NVT va **pre-sincronizzato in build** (30-60 min la prima volta) così in sala parte pronto. |
| **Nuclei** | VA rapido template-based | Risultati in secondi: ottimo "assaggio" live mentre OpenVAS macina. |
| **Trivy** *(opz.)* | Scan immagini container | Aggancia il tema supply-chain / container security, caldo lato advisory. |

### 7.2 Red team / PT (multilivello)

| Tool | Livello dimostrativo |
|---|---|
| **nmap** | Ricognizione, service/version detection, OS fingerprint. Primo step. |
| **hydra** / medusa | Brute force SSH/HTTP su credenziali deboli preparate (esito garantito). |
| **Metasploit Framework** | Exploit "vero" di un servizio vulnerabile noto. Il tool che il tecnico riconosce. |
| **sqlmap** | SQL injection su DVWA → esfiltrazione dati, molto leggibile anche dal business. |
| **ffuf** / gobuster | Directory/endpoint discovery, veloce e scenografico. |

### 7.3 Orchestrazione

Docker + Docker Compose per i container; Terraform + Ansible per il resto.

## 8. Ciclo di vita

```
make deploy
  ├─ terraform apply      → crea CCX33 + SSH key + firewall → output IP
  ├─ (genera inventory)   → IP passato ad Ansible
  └─ ansible-playbook     → host hardening, Docker, reti, Guacamole,
                            servizi, tool, dati vulnerabili, pre-sync OpenVAS

make status               → stato dei container / servizi
make snapshot             → snapshot Hetzner prima di distruggere (opz.)
make destroy
  └─ terraform destroy    → elimina il server (stop costi)
```

Tempo stimato di `make deploy` a freddo: dominato dal pre-sync del feed OpenVAS.
Si lancia una volta in fase di prep, non il giorno della demo.

## 9. Modello di sicurezza e isolamento

Questo è un ambiente **deliberatamente vulnerabile**. Regole non negoziabili:

1. **Uso esclusivo nel lab isolato.** Gli strumenti offensivi si puntano **solo**
   sui target fittizi interni. Mai verso sistemi esterni.
2. **Firewall cloud restrittivo.** Solo le porte strettamente necessarie sono
   esposte su Internet — idealmente **solo HTTPS di Guacamole**, limitato per IP
   sorgente (il tuo IP / quello della sede Aubay). I target vulnerabili **non**
   sono esposti pubblicamente: si raggiungono solo *dall'interno*, via Guacamole.
3. **Vita breve.** L'ambiente esiste per la prep e la demo, poi `destroy`.
4. **Nessun dato reale.** Solo dati fittizi precaricati.

## 10. Dashboard della demo

Pagina web statica (servita dall'host) che mostra, durante la demo:
vulnerabilità trovate, distribuzione per severità (grafico), stato
**prima → dopo remediation**. È il "wow" leggibile dal business e la traduzione in
linguaggio-rischio di ciò che i tecnici vedono a terminale. Si aggiorna dai
risultati degli scan (import da OpenVAS/Nuclei).

## 11. Mappa del repository

```
aubay-vapt-lab/
├── README.md                     Quickstart: make deploy / destroy
├── Makefile                      Entry point dei comandi
├── docs/
│   ├── ARCHITECTURE.md           ← questo documento (la Knowledge)
│   └── DEMO-RUNBOOK.md           Canovaccio operativo passo-passo (comandi pronti)
├── terraform/
│   ├── main.tf                   CCX33, SSH key, firewall cloud
│   ├── variables.tf
│   ├── outputs.tf                IP pubblico → inventario Ansible
│   └── terraform.tfvars.example  Token Hetzner e parametri (da copiare, NON committare)
├── ansible/
│   ├── playbook.yml
│   └── roles/                    hardening, docker, networks, guacamole, services, tools
├── docker/
│   ├── datacenter/               nginx, dvwa, juice-shop, mail
│   ├── users/                    ws01, ws02
│   └── cyber/                    redteam, blueteam
├── dashboard/
│   └── index.html
└── .gitignore                    esclude terraform.tfvars, chiavi, state
```

## 12. Roadmap

**Fase 1 (questa demo):** topologia a 3 aree, VA (OpenVAS + Nuclei), PT multilivello
(nmap → brute force → exploit → SQLi), remediation prima/dopo su DVWA, dashboard,
accesso via Guacamole.

**Fase 2 / roadmap (futura):**
- **SPA + Keycloak (attacchi IAM/SSO)** — una web app con login OIDC su Keycloak,
  per dimostrare attacchi sull'identità (user enumeration, credential stuffing,
  manipolazione token JWT, misconfig client/redirect). Forte differenziatore lato
  advisory. Da costruire con debolezze deterministiche scelte apposta (Keycloak
  moderno è robusto di default). Pianificata come **Fase 7**, dopo il dry-run del
  lab attuale.
- **Caldera (MITRE ATT&CK)** — attacchi mappati su framework ATT&CK, parla il
  linguaggio che i clienti del partner conoscono.
- **Trivy** integrato nel flusso come segmento container-security.
- Target su **VM KVM reali** se servirà un exploit a livello kernel.

---

## Appendice A — Checklist preparazione account Hetzner (a carico di Matteo)

1. Account su **Hetzner Cloud** (console.hetzner.cloud) + verifica completata.
2. Metodo di pagamento aggiunto.
3. Progetto `aubay-vapt-lab`.
4. API Token **Read & Write** (Security → API Tokens) → in `terraform.tfvars`.
5. Coppia SSH locale (`ssh-keygen -t ed25519`) → la pubblica va a Terraform.
6. Location scelta: Falkenstein (DE) o Helsinki (FI).

## Appendice B — Glossario rapido

- **VA** — Vulnerability Assessment: individuazione e classificazione delle
  vulnerabilità (fotografia del rischio).
- **PT** — Penetration Test: sfruttamento attivo delle vulnerabilità per dimostrare
  l'impatto reale.
- **IaC** — Infrastructure as Code: infrastruttura definita e riproducibile da
  codice versionato.
- **DVWA** — web app didattica vulnerabile, con livelli di sicurezza regolabili.
- **Juice Shop** — web app OWASP moderna (SPA/API) vulnerabile, stile e-commerce.
- **Guacamole** — gateway di accesso remoto clientless (solo browser).
