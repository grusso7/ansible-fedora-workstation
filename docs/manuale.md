# Manuale Ansible: Fedora Workstation Setup

Questo progetto è un sistema di **Infrastructure as Code (IaC)** personale basato su Ansible. Ti permette di ricostruire un intero ambiente desktop da zero in pochi minuti.

## 📂 Struttura del Progetto

Il progetto è suddiviso in "Ruoli", in modo da mantenere il codice modulare e ordinato:

- `inventory.ini`: Il file che indica ad Ansible *dove* lavorare. Nel nostro caso è impostato su `localhost`.
- `site.yml`: Il "Playbook" principale. È l'indice che richiama tutto.
- `group_vars/all.yml`: Contiene le variabili globali (es. l'utente principale, `$HOME`, ecc.).
- `roles/`: 
  - **`base`**: Aggiornamento cache `dnf` e software di base (`htop`, `zip`, `unzip`, `curl`, `wget`).
  - **`devtools`**: Strumenti da linea di comando e dev (`git`, `lazygit`, `ripgrep`, `fd-find`).
  - **`shell`**: Configurazione di `zsh` più plugin di completamento e highlighting tramite pacchetti ufficiali Fedora. Crea anche il template `.zshrc`.
  - **`nvim`**: Installa `neovim`, librerie di utilità e scarica autonomamente il template per **LazyVim**.
  - **`gnome`**: Software da desktop (`ptyxis`, manager di estensioni GNOME) e setting di sistema GSettings/dconf (posizionamento cursore, font, abilitazione estensioni e tema).
  - **`fonts`**: Download e installazione autogestita di "UbuntuMono Nerd Font".
  - **`themes`**: Gestione cursore Bibata da pacchetti Fedora.

## 🚀 Come avviare l'automazione

Qualsiasi modifica tu faccia a questo repository (ad esempio aggiungere nuovi pacchetti a un ruolo), il comando magico sarà sempre e solo uno:

```bash
ansible-playbook -i inventory.ini site.yml -K
```

- `-i inventory.ini`: Specifica l'inventario locale.
- `site.yml`: Specifica quale file eseguire.
- `-K` (oppure `--ask-become-pass`): Ti chiederà la password di **sudo** del tuo utente, fondamentale per usare `dnf` o modificare opzioni globali di sistema.

### Idempotenza

Ricorda la regola fondamentale di Ansible: **l'idempotenza**.
Puoi lanciare quel comando quante volte vuoi. Ansible analizzerà lo stato del computer e agirà *solo* se c'è qualcosa di cambiato (mostrando `changed` in giallo). Se è tutto come dovrebbe essere mostrerà semplicemente `ok` in verde.

## 🔧 Espandere il progetto

Questo layout è scalabile virtualmente all'infinito.
L'obiettivo ideale è smettere di usare "dnf install" nel terminale a mano: se ti serve un pacchetto permanente, aggiungilo qui.

Puoi creare nuovi ruoli (es. `docker`, `python`) creando una cartella col nome dentro a `roles/`, aggiungendoci un file `tasks/main.yml`, e poi aggiungendo il richiamo al ruolo dentro `site.yml`.

## 🧠 Fondamenti di Ansible: le Basi

Se sei nuovo nel mondo Ansible, ecco i concetti chiave che abbiamo utilizzato e che ti aiuteranno a capire cosa succede dietro le quinte:

### 1. I "Moduli"
Ansible non è uno script shell glorificato. Interagisce col sistema operativo utilizzando dei **moduli**. 
Nei file YAML che abbiamo scritto vedrai diciture come `ansible.builtin.dnf` o `community.general.dconf`. Questi sono moduli: il primo serve a parlare con il gestore pacchetti (DNF), il secondo serve a cambiare chiavi del desktop GNOME. Il bello dei moduli è che tu gli dici cosa vuoi ottenere, lui capire *come farlo*.

### 2. Differenza tra Task, Role e Playbook
- **Task**: È la singola azione. (Esempio: "Installa il pacchetto zip").
- **Role (Ruolo)**: È una collezione di task legati da un argomento in comune, spesso inseriti dentro una cartella dedicata (Es: tutti i task che c'entrano con GNOME vanno nel ruolo GNOME).
- **Playbook**: È il file principale (`site.yml` nel nostro caso) che unisce le due cose, decidendo **quando, dove e con che permessi** lanciare ogni ruolo.

### 3. Modificare file esistenti
Invece di lanciare un comando `echo` seguito da `>>`, Ansible consiglia due moduli per agire sui file di testo, file di configurazione ecc...:
- **`ansible.builtin.copy`**: copia un file così com'è. Utile, ma a volte poco flessibile.
- **`ansible.builtin.template`**: quello che abbiamo usato per `.zshrc`. Ti permette di iniettare variabili dinamiche (es. la path esatta dell'utente corrente) compilando il file "on-the-fly". 

### 4. Usare i "Tag"
Abbiamo inserito un campo `tags:` sotto ogni ruolo in `site.yml`. A cosa serve? 
Immagina di aver aggiunto tre nuovi pacchetti al ruolo `devtools` e di voler testare solo quello, senza che Ansible debba scorrersi per forza tutti gli step base o di GNOME e perdere secondi preziosi.

Puoi dire ad Ansible di eseguire *esclusivamente* i task taggati con `devtools`:

```bash
ansible-playbook -i inventory.ini site.yml -K --tags devtools
```
Così farai dei run velocissimi e molto mirati!

### 5. Comandi Essenziali per i Playbook
Ispirato alla [documentazione ufficiale Ansible](https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_intro.html), ecco i principali "trucchi del mestiere" da aggiungere al comando `ansible-playbook`:

- **Dry Run (Modalità di controllo):**
  Aggiungendo `-C` (o `--check`), Ansible simulerà l'esecuzione dicendoti cosa cambierebbe, ma **senza modificare nulla** nel sistema reale. Utile prima di applicare configurazioni rischiose.
  ```bash
  ansible-playbook -i inventory.ini site.yml -K --check
  ```

- **Vedere le differenze:**
  Aggiungendo `--diff` (spesso usato in combinazione con `--check`), Ansible ti mostrerà esattamente riga per riga cosa sta modificando dentro ai file, in formato stile `git diff`.
  ```bash
  ansible-playbook -i inventory.ini site.yml -K --check --diff
  ```

- **Controllo Sintassi:**
  Se hai appena scritto un ruolo e vuoi solo assicurarti che il file YAML sia valido e non abbia errori di indentazione:
  ```bash
  ansible-playbook site.yml --syntax-check
  ```

- **Esplorare il Playbook:**
  Puoi chiedere ad Ansible di stampare a schermo l'elenco dei task o degli host che verrebbero colpiti, senza eseguirli realmente:
  ```bash
  ansible-playbook -i inventory.ini site.yml --list-tasks
  ```

- **Aumentare il log (Verbosity):**
  Se qualcosa va storto e l'errore rosso non è chiaro, usa i flag di verbosità `-v`, `-vv` o `-vvv`. Più v metti, più Ansible snocciolerà dettagli e output dei comandi:
  ```bash
  ansible-playbook -i inventory.ini site.yml -K -vvv
  ```
