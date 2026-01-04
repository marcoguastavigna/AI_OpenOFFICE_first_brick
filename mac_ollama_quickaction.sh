#!/bin/bash

# ==============================================================================
# OLLAMA MACOS QUICK ACTION (AUTOMATOR)
#
# Guida all'installazione:
# 1. Apri "Automator" su macOS.
# 2. Crea nuovo "Azione Rapida" (Quick Action).
# 3. Imposta: "Il flusso di lavoro riceve: Testo" in "ogni applicazione".
# 4. Spunta "Le opzioni di output sostituiscono il testo selezionato" (se vuoi sostituire).
# 5. Cerca l'azione "Esegui script shell" (Run Shell Script) e trascinala.
# 6. Imposta Shell: "/bin/bash" e Passa input: "come argomenti".
# 7. Incolla questo codice dentro.
# 8. Salva con nome "Ollama Migliora" (o quello che vuoi).
#
# Ora puoi selezionare testo in QUALSIASI app, Tasto Destro > Servizi > Ollama Migliora
# ==============================================================================

# Configurazione
OLLAMA_URL="http://localhost:11434/api/generate"
MODEL="llama3" # Cambia con il tuo modello (es. mistral, gemma)
PROMPT_PREFIX="Sei un assistente utile. Migliora e correggi il seguente testo in italiano, mantenendo il significato. Restituisci SOLO il testo migliorato senza preamboli:"

# Il testo selezionato arriva come primo argomento ($1)
INPUT_TEXT="$1"

# Escape del testo per JSON
# Nota: su macOS 'jq' potrebbe non essere installato di default, usiamo python per l'escape sicuro
JSON_PAYLOAD=$(python3 -c "import json, sys; print(json.dumps({'model': '$MODEL', 'prompt': '$PROMPT_PREFIX\n\n' + sys.argv[1], 'stream': False}))" "$INPUT_TEXT")

# Chiamata a Ollama via CURL
RESPONSE=$(curl -s -X POST "$OLLAMA_URL" -H "Content-Type: application/json" -d "$JSON_PAYLOAD")

# Estrazione della risposta (usando python per parsing JSON affidabile)
CLEAN_RESPONSE=$(echo "$RESPONSE" | python3 -c "import sys, json; print(json.load(sys.stdin)['response'])")

# Restituisce il risultato (che Automator userà per sostituire il testo selezionato)
echo "$CLEAN_RESPONSE"
