# MANUALE DI INSTALLAZIONE (MAC OS) - OLLAMA QUICK ACTIONS

Questo manuale ti guida nell'installazione delle Azioni Rapide per macOS.
Queste azioni ti permettono di usare l'IA di Ollama in qualsiasi programma (Word, Safari, Mail, Note, ecc.) semplicemente selezionando il testo.

## 1. Prerequisiti

1.  **Ollama installato e attivo**: Assicurati che Ollama sia in esecuzione (icona nella barra dei menu).
2.  **Modello scaricato**: L'installazione predefinita usa il modello `gemma3:4b`. Se non ce l'hai, scaricalo con il terminale:
    `ollama pull gemma3:4b`
    *(Puoi cambiare modello modificando la riga `MODEL="..."` negli script).*
3.  **Python 3**: macOS lo include di base.

## 2. Creazione dell'Azione Rapida (Automator)

Ripeti questi passaggi per ogni script che vuoi installare (`Migliora`, `Riassumi`, `Espandi`, etc.).

1.  Apri l'app **Automator** (cmd+spazio e scrivi "Automator").
2.  Scegli **Nuovo Documento**.
3.  Seleziona **Azione rapida** (Quick Action) e clicca **Scegli**.
4.  In alto, imposta:
    *   **Il flusso di lavoro riceve**: `testo`
    *   **In**: `ogni applicazione`
    *   Metti la spunta su: `L'output sostituisce il testo selezionato` (IMPORTANTE!).
5.  Nella colonna di sinistra, cerca **"Esegui script shell"**.
6.  Trascina l'azione "Esegui script shell" nello spazio di destra.
7.  Configura l'azione:
    *   **Shell**: `/bin/bash`
    *   **Pass input**: `to stdin` (IMPORTANTE!)
8.  Apri il file `.sh` corrispondente (es. `mac_ollama_improve.sh`) con un editor di testo, copia tutto il contenuto e incollalo nella finestra dello script in Automator (cancella eventuali `cat` o altro testo preesistente).
9.  Salva con **Cmd+S** e dai un nome chiaro, es: `Ollama - Migliora`.

## 3. Come Usare

1.  Seleziona del testo in qualsiasi app.
2.  Fai **Tasto Destro** (o Ctrl+Click).
3.  Vai su **Servizi** (o Quick Actions).
4.  Clicca su **Ollama - Migliora** (o il nome che hai dato).
5.  Attendi qualche secondo. Il testo verrà sostituito o integrato con la risposta dell'IA.

## 4. Risoluzione Problemi

*   **Non succede nulla**: Probabilmente Ollama non è avviato o il modello non è stato scaricato.
*   **Errore "Python"**: Assicurati di avere Python 3 installato.
*   **Testo non sostituito**: Controlla di aver messo la spunta su "L'output sostituisce il testo selezionato" in Automator.
