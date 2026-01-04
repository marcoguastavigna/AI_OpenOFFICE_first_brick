#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: GENERA
#
# Crea una Quick Action in Automator chiamata "Ollama Genera"
# e incolla questo codice.
# ==============================================================================

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Usa il seguente testo come spunto (prompt) per generare un contenuto completo e creativo. Scrivi in italiano:"

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    echo "Errore: Nessun testo selezionato."
    exit 0
fi

# 2. Escape JSON
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama
# Timeout aumentato a 5 minuti (300s) per Mac Intel o modelli pesanti
RESPONSE=$($CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD" 2>&1)

# 4. Verifica risposta vuota
if [ -z "$RESPONSE" ]; then
    echo "Errore: Ollama non risponde."
    exit 0
fi

# 5. Parsing con gestione Encoding esplicita
export PYTHONIOENCODING=utf-8

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
" 2>&1)

# 6. Output
echo "$CLEAN_RESPONSE"
