# AI OpenOFFICE First Brick

Questo progetto contiene macro Python per integrare **Ollama** (AI locale) all'interno di **OpenOffice** (Apache OpenOffice) e LibreOffice.

## Funzionalità Disponibili
Questo pacchetto include due script Python per OpenOffice/LibreOffice:

### 1. `ollama_bridge.py` (Core)
Include le funzioni di base e la gestione della configurazione.
*   **Ollama_Migliora**: Riscrive il testo per renderlo più fluido.
*   **Ollama_Riassumi**: Crea un riassunto conciso.
*   **Ollama_Espandi**: Arricchisce il concetto selezionato.
*   **Ollama_AnalisiGrammaticale**: Trova errori e suggerisce correzioni.
*   **Ollama_ListaPuntata**: Trasforma il testo in elenco.
*   **Ollama_TraduciInglese**: Traduce in inglese.
*   **Ollama_Formale**: Riscrive con tono professionale.
*   **Ollama_AnalisiTono**: Valuta il tono del testo.
*   **Ollama_Configurazione**: **[NOVITÀ]** Apre il file di configurazione per impostare **Host** (es. server Cloud) e **Modello** personalizzato.

### 2. `ollama_extra.py` (Extra)
Funzioni avanzate che richiedono tempi di elaborazione più lunghi (Timeout: 5 minuti).
*   **Ollama_Genera**: Genera un testo completo partendo da un titolo/spunto.
*   **Ollama_LinguaggioChiaro**: Riscrive applicando i principi del Plain Language (anti-burocratese).

![Menu Ollama in OpenOffice](screenshot_menu.png)

## Funzioni Disponibili (OpenOffice/LibreOffice)
*   **Migliora Testo**: Rende più fluida la scrittura.
*   **Riassumi**: Sintetizza il testo selezionato.
*   **Analisi Tono**: Ti dice se il testo suona aggressivo, formale, etc. (Visualizza in finestra).
*   **Traduci**: Traduce in Inglese.
*   **Lista Puntata**: Trasforma paragrafi in elenchi puntati.

## Requisiti Tecnici
*   Lo script usa `urllib2` per compatibilità con il Python 2.7 spesso incluso nelle vecchie versioni di OpenOffice.
*   Non richiede librerie esterne complesse (`requests`, etc.) per facilitare l'uso "portatile".
