#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: LINGUAGGIO CHIARO (DEBUG LOG)
#
# Scrive un log su /tmp/ollama_log.txt per capire cosa non va.
# ==============================================================================

LOGFILE="/tmp/ollama_log.txt"

# Funzione di log
log() {
    echo "$(date '+%H:%M:%S') - $1" >> "$LOGFILE"
}

log "=== AVVIO SCRIPT ==="

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Riscrivi il seguente testo applicando i principi del Linguaggio Chiaro (Plain Language) italiano: usa parole comuni, frasi brevi, forma attiva ed elimina il burocratese. Restituisci solo il testo riscritto:"

export PYTHONIOENCODING=utf-8
log "Configurazione caricata. Modello: $MODEL"

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    log "ERRORE: Nessun testo in input."
    echo "Errore: Nessun testo selezionato."
    exit 0
fi
log "Testo ricevuto (primi 20 car): ${INPUT_TEXT:0:20}..."

# 2. Escape JSON
log "Avvio escape JSON..."
JSON_PAYLOAD=$(printf '%s' "$INPUT_TEXT" | $PYTHON -c "import json, sys; raw_text = sys.stdin.read(); print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + raw_text, 'stream': False}))" 2>>"$LOGFILE")

if [ -z "$JSON_PAYLOAD" ]; then
    log "ERRORE: Creazione payload JSON fallita (output vuoto)."
    echo "Errore interno (Python JSON)."
    exit 0
fi
log "Payload creato. Lunghezza: ${#JSON_PAYLOAD}"

# 3. Chiamata Ollama
log "Chiamata CURL in corso verso $OLLAMA_URL ..."
RESPONSE=$(echo "$JSON_PAYLOAD" | $CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

log "Risposta CURL ricevuta. Lunghezza: ${#RESPONSE}"
log "CONTENUTO RISPOSTA: $RESPONSE"

# 4. Verifica risposta vuota
if [ -z "$RESPONSE" ]; then
    log "ERRORE: Risposta vuota da CURL."
    echo "Errore: Output completamente vuoto da curl."
    exit 0
fi

if [[ "$RESPONSE" == curl:* ]]; then
    log "ERRORE CURL: $RESPONSE"
    echo "ERRORE CONNESSIONE: $RESPONSE"
    exit 0
fi

# 5. Parsing
log "Avvio parsing risposta..."
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

log "Parsing completato."

# 6. Output
echo "$INPUT_TEXT"
echo ""
echo "--- VERSIONE LINGUAGGIO CHIARO ---"
echo "$CLEAN_RESPONSE"

log "=== FINE SCRIPT ==="
