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

# 2. Generazione e Invio (PIPELINE DIRETTA)
RESPONSE=$(printf '%s' "$INPUT_TEXT" | \
$PYTHON -c "import json, sys; raw_text = sys.stdin.read(); print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + raw_text, 'stream': False}))" | \
$CURL --silent --show-error --max-time 300 -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d @- 2>&1)

# 4. Parsing pulito
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
" 2>>"$LOGFILE")

# 5. Output Finale
FINAL_OUTPUT="$INPUT_TEXT

--- TESTO GENERATO ---
$CLEAN_RESPONSE"

# A. Copia SOLO la risposta pulita negli Appunti
echo "$CLEAN_RESPONSE" | pbcopy
log "Output (solo risposta) copiato negli appunti."

# B. Notifica
osascript -e 'tell application "System Events" to display notification "Generazione completata e copiata." with title "Ollama Finito"' 2>>"$LOGFILE"

# C. Output per Automator
echo "$FINAL_OUTPUT"

log "=== FINE SCRIPT ==="
