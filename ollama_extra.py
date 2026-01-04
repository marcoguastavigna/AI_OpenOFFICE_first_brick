# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import uno
import json
import urllib2

# ==============================================================================
# OLLAMA EXTRA ACTIONS (Linguaggio Chiaro & Genera)
# Script separato per facilitare l'integrazione manuale.
# ==============================================================================

import os
import subprocess

# === CONFIGURAZIONE DEFAULT ===
DEFAULT_HOST = "http://127.0.0.1:11434"
TIMEOUT_SEC = 300 # 5 minuti per generazione testi lunghi
CONFIG_FILE = os.path.join(os.path.expanduser("~"), ".ollama_bridge_config.json")

# === GESTIONE CONFIGURAZIONE (Condivisa con bridge) ===
def load_config():
    if not os.path.exists(CONFIG_FILE):
        return {"host": DEFAULT_HOST, "model": ""}
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except:
        return {"host": DEFAULT_HOST, "model": ""}

# === FUNZIONI HELPER UNO (OpenOffice) ===
def get_current_doc():
    """Ottiene il documento corrente."""
    ctx = XSCRIPTCONTEXT.getComponentContext()
    smgr = ctx.ServiceManager
    desktop = smgr.createInstanceWithContext("com.sun.star.frame.Desktop", ctx)
    return desktop.getCurrentComponent()

def get_selection(doc):
    """Ottiene la selezione corrente."""
    selection = doc.getCurrentController().getSelection()
    try:
        return selection.getByIndex(0)
    except:
        return selection

def replace_text(new_text):
    """Sostituisce il testo selezionato con new_text."""
    doc = get_current_doc()
    if not doc:
        return

    selection = get_selection(doc)
    if not selection:
        return

    # Tenta inserimento diretto
    try:
        selection.setString(new_text)
    except:
        # Fallback su cursore di testo
        try:
            cursor = selection.getText().createTextCursorByRange(selection)
            selection.getText().insertString(cursor, new_text, True) # True = replace
        except:
            pass

def get_selected_text():
    """Legge il testo selezionato."""
    doc = get_current_doc()
    if not doc:
        return ""
    selection = get_selection(doc)
    try:
        return selection.getString()
    except:
        return ""

def show_message(message):
    """Mostra un messaggio a video (utile per errori)."""
    try:
        ctx = XSCRIPTCONTEXT.getComponentContext()
        smgr = ctx.ServiceManager
        toolkit = smgr.createInstanceWithContext("com.sun.star.awt.Toolkit", ctx)
        # Tenta di ottenere la finestra attiva
        parent = toolkit.getDesktopWindow()
        box = toolkit.createMessageBox(parent, "messagebox", 1, "Ollama Extra", message)
        box.execute()
    except:
        pass

# === CLIENT OLLAMA (Copia esatta per indipendenza) ===
def http_post(url, data_dict):
    try:
        data_json = json.dumps(data_dict)
        req = urllib2.Request(url, data_json, {'Content-Type': 'application/json'})
        resp = urllib2.urlopen(req, timeout=TIMEOUT_SEC)
        return json.load(resp)
    except urllib2.URLError as e:
        show_message("Errore connessione Ollama (" + url + "): " + str(e))
        return None
    except Exception as e:
        show_message("Errore generico: " + str(e))
        return None

def http_get(url):
    try:
        req = urllib2.Request(url)
        resp = urllib2.urlopen(req, timeout=5)
        return json.load(resp)
    except:
        return None

def get_config_host():
    cfg = load_config()
    return cfg.get("host", DEFAULT_HOST).rstrip('/')

def get_active_model():
    cfg = load_config()
    host = cfg.get("host", DEFAULT_HOST).rstrip('/')
    forced_model = cfg.get("model", "")

    if forced_model and len(forced_model) > 0:
        return forced_model

    # Auto-detect
    running = http_get(host + "/api/ps")
    if running and 'models' in running and len(running['models']) > 0:
        return running['models'][0]['name']

    installed = http_get(host + "/api/tags")
    if installed and 'models' in installed and len(installed['models']) > 0:
        names = [m['name'] for m in installed['models']]
        for favorite in ['gemma', 'llama3', 'mistral', 'mixtral']:
             for n in names:
                 if favorite in n:
                     return n
        return names[0]
    return "llama3"

def call_ollama_generate(prompt):
    model_name = get_active_model()
    host = get_config_host()
    url = host + "/api/generate"
    payload = {
        "model": model_name,
        "prompt": prompt,
        "stream": False
    }
    response = http_post(url, payload)
    if response and 'response' in response:
        return response['response']
    return None

# === NUOVE AZIONI (Linguaggio Chiaro e Genera) ===

def Ollama_LinguaggioChiaro(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Riscrivi il seguente testo applicando i principi del Linguaggio Chiaro (Plain Language) italiano: "
        "usa parole comuni, frasi brevi, forma attiva ed elimina il burocratese. "
        "Restituisci solo il testo riscritto.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_Genera(*args):
    text = get_selected_text()
    if not text:
        show_message("Scrivi prima un titolo o uno spunto e selezionalo!")
        return

    prompt = (
        "Genera un testo completo, ben strutturato e approfondito, basato sul seguente spunto o titolo. "
        "Scrivi in italiano.\n\n"
        "SPUNTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        # Per 'Genera', accodiamo al titolo invece di sostituirlo
        doc = get_current_doc()
        sel = get_selection(doc)
        cursor = sel.getText().createTextCursorByRange(sel)
        cursor.collapseToEnd()
        sel.getText().insertString(cursor, "\n\n" + result, False)

# === EXPORT ===
g_exportedScripts = (
    Ollama_LinguaggioChiaro,
    Ollama_Genera
)
