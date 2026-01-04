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
MODEL="gemma3:4b" 
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
# Timeout aumentato a 5 minuti (300s) per Mac Intel o modelli pesanti
RESPONSE=$($CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD" 2>&1)

# 4. Verifica risposta vuota
if [ -z "$RESPONSE" ]; then
    echo "Errore: Ollama non risponde. Assicurati che l'app Ollama sia aperta."
    exit 0
fi

# 5. Parsing con gestione Encoding esplicita
# PYTHONIOENCODING=utf-8 forza python a non usare ASCII
export PYTHONIOENCODING=utf-8

CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "
import sys, json

# Leggiamo tutto lo stream
raw_data = sys.stdin.read()

try:
    # Tenta il parsing con strict=False per accettare caratteri di controllo (es. \n reali)
    data = json.loads(raw_data, strict=False)
    
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        # Tutto ok
        print(data['response'])
    else:
        print('ERRORE STRUTTURA: ' + str(data))

except Exception as e:
    # Se fallisce, stampiamo l'errore Python e un pezzo del dato
    print('ERRORE PYTHON: ' + str(e))
    # print('--- INIZIO DATI RICEVUTI ---')
    # print(raw_data[:200]) 
    # print('--- FINE DATI ---')
" 2>&1)

# 6. Output
echo "$CLEAN_RESPONSE"
