' SoftMaker Basic Script for Ollama Integration
' Compatibile con TextMaker (SoftMaker Office)

Option Explicit

' === CONFIGURAZIONE ===
Const OLLAMA_BASE_URL As String = "http://127.0.0.1:11434"

' === MOTORE ===

Function GetActiveModel() As String
    Dim psJson As String, tagsJson As String, modelName As String
    
    psJson = HttpGet(OLLAMA_BASE_URL & "/api/ps")
    modelName = ExtractJSONValue(psJson, "name")
    
    If modelName <> "" Then
        GetActiveModel = modelName
        Exit Function
    End If
    
    tagsJson = HttpGet(OLLAMA_BASE_URL & "/api/tags")
    modelName = ExtractJSONValue(tagsJson, "name")
    
    If modelName <> "" Then
        GetActiveModel = modelName
    Else
        GetActiveModel = "llama3" ' Fallback
    End If
End Function

Function CallOllama(prompt As String) As String
    Dim objHTTP As Object, strJSON As String, responseText As String
    Dim activeModel As String
    
    activeModel = GetActiveModel()
    
    ' Escape caratteri per JSON
    prompt = Replace(prompt, "\", "\\")
    prompt = Replace(prompt, """", "\""")
    prompt = Replace(prompt, vbCrLf, "\n")
    
    strJSON = "{""model"": """ & activeModel & """, ""prompt"": """ & prompt & """, ""stream"": false}"
    
    Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP")
    
    ' TIMEOUT: 2 minuti (120000 ms) di attesa
    objHTTP.setTimeouts 5000, 5000, 10000, 120000
        
    objHTTP.Open "POST", OLLAMA_BASE_URL & "/api/generate", False
    objHTTP.setRequestHeader "Content-Type", "application/json"
    objHTTP.send strJSON
    
    If objHTTP.Status <> 200 Then
        CallOllama = "ERRORE: " & objHTTP.Status & " - " & objHTTP.statusText
        Exit Function
    End If
        
    responseText = objHTTP.responseText
    CallOllama = ExtractJSONValue(responseText, "response")
    Set objHTTP = Nothing
End Function

Function HttpGet(url As String) As String
    Dim objHTTP As Object
    On Error Resume Next
    Set objHTTP = CreateObject("MSXML2.ServerXMLHTTP")
    objHTTP.setTimeouts 2000, 2000, 2000, 2000
    objHTTP.Open "GET", url, False
    objHTTP.send
    If objHTTP.Status = 200 Then HttpGet = objHTTP.responseText
    Set objHTTP = Nothing
    On Error GoTo 0
End Function

Function ExtractJSONValue(jsonStr As String, key As String) As String
    Dim keyStr As String, startPos As Integer, extracted As String
    Dim i As Integer, isEscaped As Boolean, char As String
    
    keyStr = """" & key & """:"""
    startPos = InStr(jsonStr, keyStr)
    If startPos = 0 Then Exit Function
    
    startPos = startPos + Len(keyStr)
    isEscaped = False
    
    ' Parsing semplice manuale
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

' === FINEZZE PER TEXTMAKER ===

Sub Ollama_Action(actionType As String)
    Dim tm As Object
    Dim selText As String
    Dim prompt As String
    Dim result As String
    
    ' Connessione a TextMaker attivo
    Set tm = CreateObject("TextMaker.Application")
    If tm Is Nothing Then
        MsgBox "TextMaker non sembra essere aperto.", 16, "Errore"
        Exit Sub
    End If
    
    If tm.ActiveDocument Is Nothing Then
        MsgBox "Nessun documento aperto.", 48, "Attenzione"
        Exit Sub
    End If
    
    selText = tm.ActiveDocument.Selection.Text
    If Len(Trim(selText)) < 2 Then
        MsgBox "Seleziona prima del testo!", 48, "Attenzione"
        Exit Sub
    End If
    
    Select Case actionType
        Case "Migliora"
            prompt = "Sei un redattore esperto. Migliora il seguente testo italiano rendendolo più fluido e corretto. Restituisci SOLO il testo migliorato:\n\n" & selText
        Case "Riassumi"
            prompt = "Riassumi il seguente testo in italiano in modo conciso:\n\n" & selText
        Case "Lista"
            prompt = "Trasforma il seguente testo in una lista puntata chiara in italiano:\n\n" & selText
        Case "Tono"
            prompt = "Analizza il tono di questo testo (es. aggressivo, formale) e dai un breve consiglio in italiano:\n\n" & selText
    End Select
    
    result = CallOllama(prompt)
    
    If result <> "" Then
        If Left(result, 6) = "ERRORE" Then
            MsgBox result, 16, "Errore Ollama"
        Else
            If actionType = "Tono" Then
                MsgBox result, 64, "Analisi Tono"
            Else
                tm.ActiveDocument.Selection.Text = result
            End If
        End If
    End If
End Sub

' === PUNTI DI INGRESSO (Da lanciare da BasicMaker o Menu Script) ===

Sub Ollama_Migliora()
    Ollama_Action "Migliora"
End Sub

Sub Ollama_Riassumi()
    Ollama_Action "Riassumi"
End Sub

Sub Ollama_ListaPuntata()
    Ollama_Action "Lista"
End Sub

Sub Ollama_AnalisiTono()
    Ollama_Action "Tono"
End Sub
