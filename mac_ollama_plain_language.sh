#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: LINGUAGGIO CHIARO (SAFE RESTORE)
# ==============================================================================

OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b"
PROMPT_PREFIX="Riscrivi il seguente testo applicando i principi del Linguaggio Chiaro (Plain Language) italiano: usa parole comuni, frasi brevi, forma attiva ed elimina il burocratese. Restituisci solo il testo riscritto:"

PYTHON="/usr/bin/python3"
CURL="/usr/bin/curl"
TMP_INPUT="/tmp/ollama_input.txt"
TMP_PAYLOAD="/tmp/ollama_payload.json"

export PYTHONIOENCODING=utf-8

# 1. Input Ibrido (Argomenti o Stdin)
if [ -n "$1" ]; then
    printf '%s' "$1" > "$TMP_INPUT"
else
    cat > "$TMP_INPUT"
fi

if [ ! -s "$TMP_INPUT" ]; then
    echo "ERRORE: Nessun testo selezionato (Ollama)"
    exit 0
fi

$PYTHON -c "
import json, sys
try:
    with open('$TMP_INPUT', 'r', encoding='utf-8') as f:
        text = f.read()
    payload = {
        'model': '$MODEL',
        'prompt': '$PROMPT_PREFIX\n\n' + text,
        'stream': False
    }
    with open('$TMP_PAYLOAD', 'w', encoding='utf-8') as f:
        json.dump(payload, f)
except Exception as e:
    print(f'Errore Python: {e}')
"

RESPONSE=$($CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @"$TMP_PAYLOAD")

CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if 'response' in data:
        print(data['response'])
    elif 'error' in data:
        print(f'ERRORE OLLAMA: {data['error']}')
    else:
        print(f'ERRORE RISPOSTA: {str(data)}')
except Exception:
    print('$RESPONSE')
")

# Output: Originale + Testo Semplificato
cat "$TMP_INPUT"
echo ""
echo ""
echo "--- VERSIONE LINGUAGGIO CHIARO ---"
echo "$CLEAN_RESPONSE"
