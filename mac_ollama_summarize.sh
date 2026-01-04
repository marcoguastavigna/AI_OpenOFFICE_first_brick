#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: RIASSUMI (FIX UTF8)
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

# 2. Generazione e Invio (PIPELINE DIRETTA)
RESPONSE=$(printf '%s' "$INPUT_TEXT" | \
$PYTHON -c "import json, sys; raw_text = sys.stdin.read(); print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + raw_text, 'stream': False}))" | \
$CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

# 4. Verifica
if [ -z "$RESPONSE" ]; then
    echo "Errore: Risposta vuota da Ollama."
    exit 0
fi

# 5. Parsing con gestione Encoding esplicita
# PYTHONIOENCODING=utf-8 forza python a non usare ASCII
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
echo ""
echo "--- RIASSUNTO OLLAMA ---"
echo "$CLEAN_RESPONSE"
