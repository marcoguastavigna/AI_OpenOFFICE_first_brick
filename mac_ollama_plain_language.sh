#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: LINGUAGGIO CHIARO (PIPELINE FIX)
#
# Soluzione definitiva "Unexpected EOF": Pipeline diretta senza variabili intermedie.
# ==============================================================================

LOGFILE="/tmp/ollama_log.txt"

# Funzione di log
log() {
    echo "$(date '+%H:%M:%S') - $1" >> "$LOGFILE"
}

log "=== AVVIO SCRIPT (PIPELINE) ==="

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Riscrivi il seguente testo applicando i principi del Linguaggio Chiaro (Plain Language) italiano: usa parole comuni, frasi brevi, forma attiva ed elimina il burocratese. Restituisci solo il testo riscritto:"

export PYTHONIOENCODING=utf-8

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    log "ERRORE: Nessun testo in input."
    echo "Errore: Nessun testo selezionato."
    exit 0
fi

# 2. Generazione e Invio (TUTTO IN UNA PIPELINE)
# printf -> python (crea json) -> curl (invia) -> variabile RESPONSE
log "Avvio pipeline diretta..."

RESPONSE=$(printf '%s' "$INPUT_TEXT" | \
$PYTHON -c "import json, sys; raw_text = sys.stdin.read(); print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + raw_text, 'stream': False}))" | \
$CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

log "Risposta CURL ricevuta. Lunghezza: ${#RESPONSE}"
log "CONTENUTO RISPOSTA: $RESPONSE"

# 3. Verifica errori
if [ -z "$RESPONSE" ]; then
    log "ERRORE: Risposta vuota."
    echo "Errore: Output vuoto da Ollama."
    exit 0
fi

if [[ "$RESPONSE" == curl:* ]]; then
    log "ERRORE CURL: $RESPONSE"
    echo "ERRORE CONNESSIONE: $RESPONSE"
    exit 0
fi

# 4. Parsing pulito
CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json
raw_data = sys.stdin.read()
try:
    data = json.loads(raw_data, strict=False)
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        print(data['response'])
    else:
        print('ERRORE STRUTTURA: ' + str(data))
except Exception as e:
    print('ERRORE PYTHON: ' + str(e))
" 2>>"$LOGFILE")

# 5. Output Finale
# Costruiamo la stringa finale
FINAL_OUTPUT="$INPUT_TEXT

--- VERSIONE LINGUAGGIO CHIARO ---
$CLEAN_RESPONSE"

# A. Copia SOLO la risposta pulita negli Appunti (così incolli solo quello che serve)
echo "$CLEAN_RESPONSE" | pbcopy
log "Output (solo risposta) copiato negli appunti."

# B. Notifica Visiva (Fix: System Events)
osascript -e 'tell application "System Events" to display notification "Copiato negli appunti." with title "Ollama Completato"' 2>>"$LOGFILE"

# C. Output standard per Automator (Originale + Risposta)
# Automator userà questo se decide di funzionare, mostrando il confronto.
echo "$FINAL_OUTPUT"

log "=== FINE SCRIPT ==="
