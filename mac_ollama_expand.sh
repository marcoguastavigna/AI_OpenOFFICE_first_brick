#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: ESTENDI
#
# Crea una Quick Action in Automator chiamata "Ollama Estendi"
# e incolla questo codice.
# ==============================================================================

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Espandi il seguente concetto o testo, aggiungendo dettagli, contesto e spiegazioni utili. Scrivi in italiano corretto:"

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    echo "Errore: Nessun testo selezionato."
    exit 0
fi

# 2. Escape JSON
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama
# 2>&1 cattura anche gli errori di connessione (stderr) nella variabile
# 3. Chiamata Ollama
# Usiamo PIPE per passare il payload (più sicuro per testi lunghi)
RESPONSE=$(echo "$JSON_PAYLOAD" | $CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

# 4. Verifica risposta vuota (o errore curl)
if [ -z "$RESPONSE" ]; then
    echo "Errore: Output completamente vuoto da curl."
    exit 0
fi

# Se response inizia con "curl:", è un errore di connessione
if [[ "$RESPONSE" == curl:* ]]; then
    echo "ERRORE CONNESSIONE: $RESPONSE"
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
