#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION: LINGUAGGIO CHIARO
#
# Crea una Quick Action in Automator chiamata "Ollama Linguaggio Chiaro"
# e incolla questo codice.
# ==============================================================================

# Percorsi assoluti
CURL="/usr/bin/curl"
PYTHON="/usr/bin/python3"

# Configurazione
OLLAMA_URL="http://127.0.0.1:11434/api/generate"
MODEL="gemma3:4b" 
PROMPT_PREFIX="Riscrivi il seguente testo applicando i principi del Linguaggio Chiaro (Plain Language) italiano: usa parole comuni, frasi brevi, forma attiva ed elimina il burocratese. Restituisci solo il testo riscritto:"

# 1. Controllo Input
INPUT_TEXT="$1"
if [ -z "$INPUT_TEXT" ]; then
    echo "Errore: Nessun testo selezionato."
    exit 0
fi

# 2. Escape JSON (Python)
# Nota: La variabile INPUT_TEXT qui serve solo per riferimento locale, il payload vero lo costruiamo dopo
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama
# Usiamo PIPE per passare il payload (sicuro per testi lunghi) e catturiamo stderr (2>&1)
# Timeout 5 minuti
RESPONSE=$(echo "$JSON_PAYLOAD" | $CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

# 4. Verifica risposta vuota
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

# Leggiamo tutto lo stream
raw_data = sys.stdin.read()

try:
    # Tenta il parsing con strict=False per accettare caratteri di controllo
    data = json.loads(raw_data, strict=False)
    
    if 'error' in data:
        print('ERRORE OLLAMA: ' + data['error'])
    elif 'response' in data:
        # Tutto ok
        print(data['response'])
    else:
        print('ERRORE STRUTTURA: ' + str(data))

except Exception as e:
    # Se fallisce, stampiamo l'errore Python
    print('ERRORE PYTHON: ' + str(e))
" 2>&1)

# 6. Output (APPEND al testo originale per confronto)
echo "$INPUT_TEXT"
echo ""
echo "--- VERSIONE LINGUAGGIO CHIARO ---"
echo "$CLEAN_RESPONSE"
