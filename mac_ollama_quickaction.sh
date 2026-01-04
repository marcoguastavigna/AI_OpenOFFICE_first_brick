#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION (DEBUG VERSION)
#
# Versione migliorata per mostrare il VERO errore di Ollama (es. "Modello non trovato").
# ==============================================================================

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="llama3" 
PROMPT_PREFIX="Sei un assistente utile. Migliora il seguente testo in italiano. Restituisci SOLO il testo migliorato:"

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
    echo "Errore: Ollama non risponde. Assicurati che l'app Ollama sia aperta."
    exit 0
fi

# 5. Estrazione Intelligente (cerca 'response' O 'error')
CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        print(data['response'])
    else:
        print('ERRORE IMPREVISTO: Risposta JSON strana: ' + str(data))
except Exception as e:
    print('ERRORE DI PARSING: Il server ha restituito qualcosa che non è JSON.\n' + sys.stdin.read())
" 2>&1)

# 6. Output
echo "$CLEAN_RESPONSE"
