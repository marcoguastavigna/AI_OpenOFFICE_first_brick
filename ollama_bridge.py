# -*- coding: utf-8 -*-
from __future__ import unicode_literals
import uno
import json
import urllib2

import os
import subprocess

# === CONFIGURAZIONE DEFAULT ===
DEFAULT_HOST = "http://127.0.0.1:11434"
TIMEOUT_SEC = 180
CONFIG_FILE = os.path.join(os.path.expanduser("~"), ".ollama_bridge_config.json")

# === GESTIONE CONFIGURAZIONE ===
def load_config():
    """Carica la configurazione da file JSON."""
    if not os.path.exists(CONFIG_FILE):
        return {"host": DEFAULT_HOST, "model": ""}
    
    try:
        with open(CONFIG_FILE, "r") as f:
            return json.load(f)
    except:
        return {"host": DEFAULT_HOST, "model": ""}

def save_config(config):
    """Salva la configurazione su file JSON."""
    try:
        with open(CONFIG_FILE, "w") as f:
            json.dump(config, f, indent=4)
        return True
    except:
        return False

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
        box = toolkit.createMessageBox(parent, "messagebox", 1, "Ollama Bridge", message)
        box.execute()
    except:
        pass

# === CLIENT OLLAMA ===
def http_post(url, data_dict):
    """Esegue una chiamata POST robusta per Python 2.7."""
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
    """Esegue una chiamata GET."""
    try:
        req = urllib2.Request(url)
        resp = urllib2.urlopen(req, timeout=5) # Timeout breve per discovery
        return json.load(resp)
    except:
        return None

def get_config_host():
    cfg = load_config()
    return cfg.get("host", DEFAULT_HOST).rstrip('/')

def get_active_model():
    """
    Trova il modello migliore da usare.
    1. Se c'e' un modello forzato in config, usa quello.
    2. Se no, controlla /api/ps (modello attivo).
    3. Se no, controlla /api/tags (primo installato).
    """
    cfg = load_config()
    host = cfg.get("host", DEFAULT_HOST).rstrip('/')
    forced_model = cfg.get("model", "")

    if forced_model and len(forced_model) > 0:
        return forced_model

    # 2. Check running (Auto-detect)
    running = http_get(host + "/api/ps")
    if running and 'models' in running and len(running['models']) > 0:
        return running['models'][0]['name']

    # 3. Check installed
    installed = http_get(host + "/api/tags")
    if installed and 'models' in installed and len(installed['models']) > 0:
        # Preferisci modelli famosi se presenti
        names = [m['name'] for m in installed['models']]
        for favorite in ['gemma', 'llama3', 'mistral', 'mixtral']:
             for n in names:
                 if favorite in n:
                     return n
        return names[0]

    return "llama3" # Default speranza

def call_ollama_generate(prompt):
    """Chiama l'API generate di Ollama."""
    model_name = get_active_model()
    host = get_config_host()
    
    # show_message("Debug: Host=" + host + " Model=" + model_name)

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

# === CONFIGURATORE MACRO ===
def Ollama_Configurazione(*args):
    """Apre il file di configurazione per permettere all'utente di modificarlo."""
    cfg = load_config() # Crea il file se non esiste con i default
    if not os.path.exists(CONFIG_FILE):
        save_config(cfg) # Scrive i default fisicamente
    
    # Avvisa l'utente
    show_message(
        "Si aprira' il file di configurazione.\n"
        "Modifica 'host' (es. http://tuo-server:11434) e 'model'.\n"
        "Se lasci 'model' vuoto, usera' quello attivo.\n"
        "Salva e chiudi il file, poi riprova."
    )
    
    # Apre il file con l'editor predefinito di sistema
    try:
        if os.name == 'nt': # Windows
            os.startfile(CONFIG_FILE)
        else: # Mac/Linux fallback
            subprocess.call(('xdg-open', CONFIG_FILE))
    except Exception as e:
        show_message("Non riesco ad aprire il file: " + str(e) + "\nPercorso: " + CONFIG_FILE)

# === AZIONI MACRO (Che l'utente vede) ===
def Ollama_Migliora(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Sei un redattore esperto. Migliora il seguente testo italiano rendendolo piu fluido e corretto, "
        "senza cambiarne il significato. Non aggiungere commenti, restituisci solo il testo migliorato.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_Riassumi(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Riassumi il seguente testo in italiano in modo conciso. "
        "Non aggiungere introduzioni, solo il riassunto.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_Espandi(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Espandi il seguente concetto aggiungendo dettagli rilevanti ed esempi. "
        "Scrivi in italiano.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_AnalisiGrammaticale(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Analizza il seguente testo e elenca eventuali errori grammaticali o stilistici. "
        "Se e' corretto, scrivi 'Nessun errore rilevato'.\n\n"
        "TESTO:\n" + text
    )
    # Nota: qui potremmo voler mostrare un messaggio invece di sostituire
    result = call_ollama_generate(prompt)
    if result:
        show_message("Analisi:\n" + result)

def Ollama_ListaPuntata(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Trasforma il seguente testo in una lista puntata chiara e concisa in italiano.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_TraduciInglese(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Traslate the following text into English. Return only the translation.\n\n"
        "TEXT:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_Formale(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Riscrivi il seguente testo rendendolo più formale e professionale, "
        "mantenendo il significato originale.\n\n"
        "TESTO:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        replace_text(result)

def Ollama_PromptImmagine(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Based on the following text, write a detailed stable diffusion prompt to generate an image. "
        "Describe the subject, style, lighting, and mood. Return ONLY the prompt.\n\n"
        "TEXT:\n" + text
    )
    result = call_ollama_generate(prompt)
    if result:
        # Per il prompt immagine, accodiamo invece di sostituire, così l'utente conserva il testo fonte
        doc = get_current_doc()
        sel = get_selection(doc)
        cursor = sel.getText().createTextCursorByRange(sel)
        cursor.collapseToEnd()
        sel.getText().insertString(cursor, "\n\n[PROMPT IMMAGINE]:\n" + result + "\n", False)

def Ollama_AnalisiTono(*args):
    text = get_selected_text()
    if not text:
        show_message("Seleziona prima del testo!")
        return

    prompt = (
        "Analizza il tono del seguente testo (es. formale, aggressivo, diplomatico, insicuro). "
        "Se il tono potrebbe risultare offensivo o poco chiaro, suggerisci come migliorarlo. "
        "Rispondi brevemente in italiano.\n\n"
        "TESTO:\n" + text
    )
    # Mostriamo il risultato in una finestra invece di sostituire il testo
    result = call_ollama_generate(prompt)
    if result:
        show_message("Analisi Tono e Stile:\n\n" + result)

# Esporta le funzioni per OpenOffice
g_exportedScripts = (
    Ollama_Migliora, 
    Ollama_Riassumi, 
    Ollama_Espandi, 
    Ollama_AnalisiGrammaticale,
    Ollama_ListaPuntata,
    Ollama_TraduciInglese,
    Ollama_Formale,
    Ollama_PromptImmagine,
    Ollama_AnalisiTono,
    Ollama_Configurazione
)
