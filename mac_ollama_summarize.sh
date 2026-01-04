#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: RIASSUMI
#
# Crea una Quick Action in Automator chiamata "Ollama Riassumi"
# e incolla questo codice.
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

# 2. Escape JSON
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama
RESPONSE=$($CURL --silent --show-error --max-time 120 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD")

# 4. Verifica risposta vuota
if [ -z "$RESPONSE" ]; then
    echo "Errore: Ollama non risponde."
    exit 0
fi

# 5. Estrazione Intelligente
CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        print(data['response'])
    else:
        print('ERRORE IMPREVISTO: ' + str(data))
except Exception as e:
    print('ERRORE DI PARSING: ' + sys.stdin.read())
" 2>&1)

# 6. Output
echo "$CLEAN_RESPONSE"
