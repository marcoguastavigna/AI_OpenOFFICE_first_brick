# Manuale Istruzioni: Suite AI per macOS (Ollama)

Questa guida spiega come installare e usare gli script AI per integrare l'intelligenza artificiale (tramite Ollama) in **qualsiasi applicazione** del tuo Mac (Word, Pages, Safari, Mail, Note, ecc.).

## 1. Prerequisiti

Prima di iniziare, assicurati di avere:

1.  **Ollama Installato**: Scarica e installa Ollama da [ollama.com](https://ollama.com).
2.  **Ollama Attivo**: L'icona di Ollama (la lama) deve essere visibile nella barra dei menu in alto a destra.
3.  **Python 3 (Già incluso)**: Gli script usano Python 3 per "parlare" con Ollama. macOS lo ha quasi sempre di serie.
    *   Per verificare, apri il Terminale e scrivi: `/usr/bin/python3 --version`.
    *   Se ti chiede di installare i "Developer Tools", accetta (è veloce).
4.  **Modello Scaricato**: Gli script sono configurati per usare il modello `gemma3:4b` (veloce e potente).
    *   Apri il **Terminale** del Mac.
    *   Scrivi: `ollama pull gemma3:4b` e premi Invio.
    *   Attendi il download.

> **Nota**: Se vuoi usare un altro modello (es. `llama3`, `mistral`), devi aprire i file `.sh` con un editor di testo e cambiare la riga `MODEL="gemma3:4b"`.

---

## 2. Installazione (Creare le "Azioni Rapide")

Dobbiamo creare un'Azione Rapida per ogni funzione che vuoi attivare. La procedura è identica per tutti e 4 gli script.

### Esempio: Installare "Migliora Testo"

1.  Apri l'applicazione **Automator** (la trovi nella cartella Applicazioni o con Spotlight).
2.  Clicca su **Nuovo Documento**.
3.  Scegli il tipo **Azione Rapida** (o "Servizio" su vecchi macOS) e clicca **Scegli**.
4.  **Configurazione in alto**:
    *   "Il flusso di lavoro elabora l'elemento attuale": **Testo**.
    *   "in": **qualsiasi applicazione** (o "ogni applicazione").
    *   Spunta la casella: **L'output sostituisce il testo selezionato**.
5.  **Aggiungi l'azione**:
    *   Nella barra di ricerca a sinistra (vicino a "Libreria"), scrivi `shell`.
    *   Trascina l'azione **Esegui script shell** nello spazio vuoto a destra.
6.  **Configura lo script**:
    *   Shell: `/bin/bash` (default).
    *   Passa input: **come argomenti** (IMPORTANTE!).
7.  **Incolla il codice**:
    *   Apri il file `mac_ollama_improve.sh` che hai scaricato.
    *   Copia tutto il testo.
    *   Cancellare qualsiasi cosa ci sia nella finestra di Automator e **incolla il codice**.
8.  **Salva**:
    *   Premi `Cmd + S`.
    *   Dai il nome: `Ollama Migliora`.

### Ripeti per gli altri script
Ripeti i passaggi sopra per gli altri file, dando nomi diversi:
*   `mac_ollama_summarize.sh` -> Salva come **Ollama Riassumi**
*   `mac_ollama_expand.sh` -> Salva come **Ollama Estendi**
*   `mac_ollama_generate.sh` -> Salva come **Ollama Genera**
*   `mac_ollama_plain_language.sh` -> Salva come **Ollama Linguaggio Chiaro**

---

## 3. Come Usare

Ora l'AI è integrata nel sistema!

1.  Apri un qualsiasi programma (es. Word, TextEdit, una mail).
2.  Scrivi o seleziona del testo.
3.  Clicca col **Tasto Destro** sul testo selezionato.
4.  Vai nel menu **Servizi** (o a volte è direttamente nel menu principale).
5.  Clicca su **Ollama Migliora** (o Riassumi, ecc.).

*   **Migliora**: Sostituirà il testo con la versione migliorata.
*   **Tutti gli altri**: Lasceranno il testo originale e aggiungeranno il risultato sotto.

---

## 4. Risoluzione Problemi

*   **Errore "Ollama non risponde"**: Assicurati che l'app Ollama sia aperta sulla barra dei menu.
*   **Errore "Model not found"**: Hai dimenticato di scaricare il modello. Vai sul Terminale e scrivi `ollama pull gemma3:4b`.
*   **Lentezza**: Su Mac Intel la prima volta può volerci un po' (anche 30-60 secondi) per caricare il modello. Abbiamo impostato un timeout lungo (5 minuti) per evitare errori, quindi porta pazienza!
