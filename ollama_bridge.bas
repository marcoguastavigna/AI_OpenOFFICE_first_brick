Attribute VB_Name = "OllamaBridge"
Option Explicit

' === CONFIGURAZIONE ===
Const OLLAMA_BASE_URL As String = "http://127.0.0.1:11434"

' === MOTORE (Non toccare) ===

' Trova il modello attivo (quello caricato in memoria o il primo disponibile)
Private Function GetActiveModel() As String
    Dim psJson As String, tagsJson As String
    Dim modelName As String
    
    ' 1. Prova a vedere se c'è un modello già in esecuzione (/api/ps)
    psJson = HttpGet(OLLAMA_BASE_URL & "/api/ps")
    modelName = ExtractJSONValue(psJson, "name")
    
    If modelName <> "" Then
        GetActiveModel = modelName
        Exit Function
    End If
    
    ' 2. Se nessuno è attivo, prendi il primo installato (/api/tags)
    tagsJson = HttpGet(OLLAMA_BASE_URL & "/api/tags")
    modelName = ExtractJSONValue(tagsJson, "name")
    
    If modelName <> "" Then
        GetActiveModel = modelName
    Else
        GetActiveModel = "llama3" ' Fallback estremo
    End If
End Function

Private Function CallOllama(prompt As String, systemMsg As String) As String
    Dim objHTTP As Object
    Dim strJSON As String, responseText As String
    Dim activeModel As String
    
    activeModel = GetActiveModel()
    
    ' Pulisci caratteri speciali
    prompt = Replace(prompt, "\", "\\")
    prompt = Replace(prompt, """", "\""")
    prompt = Replace(prompt, vbCrLf, "\n")
    prompt = Replace(prompt, vbCr, "\n")
    prompt = Replace(prompt, vbLf, "\n")
    
    strJSON = "{""model"": """ & activeModel & """, ""prompt"": """ & prompt & """, ""stream"": false}"
    
    Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP")
    With objHTTP
        ' Imposta timeout (Resolve, Connect, Send, Receive) in millisecondi
        ' Qui diamo 2 minuti (120000 ms) per la risposta, utile se il modello deve caricarsi
        .setTimeouts 5000, 5000, 10000, 120000
        
        .Open "POST", OLLAMA_BASE_URL & "/api/generate", False
        .setRequestHeader "Content-Type", "application/json"
        
        On Error Resume Next ' Gestione errore timeout
        .send strJSON
        If Err.Number <> 0 Then
            CallOllama = "Errore: Timeout o connessione fallita. Ollama è acceso?"
            Set objHTTP = Nothing
            Exit Function
        End If
        On Error GoTo 0
        
        responseText = .responseText
    End With
    
    CallOllama = ExtractJSONValue(responseText, "response")
    Set objHTTP = Nothing
End Function

Private Function HttpGet(url As String) As String
    Dim objHTTP As Object
    On Error Resume Next ' Evita crash se offline
    Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP")
    With objHTTP
        .Open "GET", url, False
        .send
        If .Status = 200 Then
            HttpGet = .responseText
        End If
    End With
    Set objHTTP = Nothing
    On Error GoTo 0
End Function

Private Function ExtractJSONValue(jsonStr As String, key As String) As String
    Dim keyStr As String, startPos As Long, extracted As String
    Dim i As Long, isEscaped As Boolean, char As String
    
    keyStr = """" & key & """:"""
    startPos = InStr(jsonStr, keyStr)
    If startPos = 0 Then Exit Function
    
    startPos = startPos + Len(keyStr)
    isEscaped = False
    
    For i = startPos To Len(jsonStr)
        char = Mid(jsonStr, i, 1)
        If isEscaped Then
            extracted = extracted & char
            isEscaped = False
        Else
            If char = "\" Then
                isEscaped = True
            ElseIf char = """" Then
                Exit For
            Else
                extracted = extracted & char
            End If
        End If
    Next i
    
    extracted = Replace(extracted, "\n", vbCrLf)
    extracted = Replace(extracted, "\""", """")
    extracted = Replace(extracted, "\\", "\")
    ExtractJSONValue = extracted
End Function

' === MACRO (Da usare) ===

Sub Ollama_Migliora()
    Dim txt As String
    txt = Selection.Text
    If Len(Trim(txt)) < 2 Then MsgBox "Seleziona del testo!": Exit Sub
    Selection.Text = CallOllama("Migliora questo testo italiano rendendolo fluido: " & txt, "")
End Sub

Sub Ollama_Riassumi()
    Dim txt As String
    txt = Selection.Text
    If Len(Trim(txt)) < 2 Then MsgBox "Seleziona del testo!": Exit Sub
    Selection.Text = CallOllama("Riassumi in italiano: " & txt, "")
End Sub

Sub Ollama_ListaPuntata()
    Dim txt As String
    txt = Selection.Text
    If Len(Trim(txt)) < 2 Then MsgBox "Seleziona del testo!": Exit Sub
    Selection.Text = CallOllama("Trasforma in lista puntata: " & txt, "")
End Sub

Sub Ollama_AnalisiTono()
    Dim txt As String
    txt = Selection.Text
    If Len(Trim(txt)) < 2 Then MsgBox "Seleziona del testo!": Exit Sub
    MsgBox CallOllama("Analizza il tono (brevemente): " & txt, ""), vbInformation, "Ollama"
End Sub
