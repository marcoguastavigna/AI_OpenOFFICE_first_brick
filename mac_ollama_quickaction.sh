#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION (ROBUST VERSION)
#
# Se Automator dà errore "Dati non validi", usa questo script.
# Usa percorsi assoluti per evitare problemi di PATH.
# ==============================================================================

# Percorsi assoluti (su macOS standard)
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

# 2. Escape JSON sicuro con Python
JSON_PAYLOAD=$($PYTHON -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# 3. Chiamata Ollama
# --max-time 120 imposta un timeout di 2 minuti
RESPONSE=$($CURL --silent --show-error --max-time 120 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD")

# 4. Verifica se c'è stata risposta
if [ -z "$RESPONSE" ]; then
    echo "Errore: Nessuna risposta da Ollama. Verifica che Ollama sia aperto."
    exit 0
fi

# 5. Estrazione pulita
CLEAN_RESPONSE=$(echo "$RESPONSE" | $PYTHON -c "import sys, json; data=json.load(sys.stdin); print(data.get('response', 'Errore: Risposta JSON non valida'))" 2>&1)

# 6. Output finale
if [ -z "$CLEAN_RESPONSE" ]; then
    echo "Errore: Risposta vuota dal modello."
else
    echo "$CLEAN_RESPONSE"
fi
