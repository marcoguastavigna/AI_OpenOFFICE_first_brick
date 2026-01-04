#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: RIASSUMI (DEBUG)
# ==============================================================================

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Sei un assistente editoriale esperto. Riassumi il seguente testo in italiano in modo chiaro e conciso, evidenziando i punti chiave:"

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    echo "Errore: Nessun testo selezionato."
    exit 0
fi

# 2. Escape JSON (Python gestisce meglio i caratteri speciali)
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama (timeout 2 minuti)
# --fail non lo mettiamo per poter leggere il corpo dell'errore (es. 404 message)
RESPONSE=$($CURL --silent --show-error --max-time 120 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD")

# 4. Verifica se curl ha fallito completamente (stringa vuota)
if [ -z "$RESPONSE" ]; then
    echo "Errore: Connessione fallita. Ollama è acceso?"
    exit 0
fi

# 5. Estrazione Intelligente & Debug
CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json
raw_data = sys.stdin.read()
try:
    data = json.loads(raw_data)
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        print(data['response'])
    else:
        print('ERRORE STRUTTURA JSON: ' + str(data))
except Exception as e:
    # Se non è JSON, mostriamo i primi 200 caratteri di cosa abbiamo ricevuto
    print('ERRORE DI COMUNICAZIONE.')
    print('Non ho ricevuto JSON valido. Ecco cosa è arrivato (primi 100 car):')
    print(raw_data[:100])
" 2>&1)

# 6. Output
echo "$CLEAN_RESPONSE"
