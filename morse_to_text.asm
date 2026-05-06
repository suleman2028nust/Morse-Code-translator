; =============================================================================
; morse_to_text.asm  –  Morse → Text  (Decode mode)
; =============================================================================

.DATA
strModeDecode BYTE "   MORSE  TO  TEXT  DECODING   |   TRANSLATION  MODE   ", 0

.DATA?
tokenBuffer BYTE 20 DUP(?)
tokenLen    DWORD ?
decodedBuffer BYTE 100 DUP(?)

.CODE

CompareStrings PROC
    push eax
    push esi
    push edi
CS_Loop:
    mov  al, [esi]
    mov  ah, [edi]
    cmp  al, ah
    jne  CS_NotEqual
    cmp  al, 0
    je   CS_Equal
    inc  esi
    inc  edi
    jmp  CS_Loop
CS_NotEqual:
    or   al, 1
    pop  edi
    pop  esi
    pop  eax
    ret
CS_Equal:
    cmp  al, al
    pop  edi
    pop  esi
    pop  eax
    ret
CompareStrings ENDP

DoDecoding PROC
    call DrawTitleBar
    INVOKE DrawSubHeader, OFFSET strModeDecode
    
    ; Row 8 - Section
    mov  dh, 8
    call PrintSectionLine

    ; Row 11 - Input Prompt
    mov  dh, 11
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strEnterMorse
    call WriteString
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET inputBuffer
    mov  ecx, MAX_INPUT_LEN
    call ReadString
    mov  inputLen, eax
    ; --- Empty input guard ---
    cmp  eax, 0
    jne  Dec_CheckText
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strEmptyMorse
    call WriteString
    jmp  Dec_WaitKey
Dec_CheckText:
    call CheckIfTextInput
    cmp  eax, 1
    jne  Dec_HasInput
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strMorseNotText
    call WriteString
    jmp  Dec_WaitKey
Dec_HasInput:

    ; Row 13 - Output section
    mov  dh, 13
    call PrintSectionLine

    ; Row 15 - Result label
    mov  dh, 15
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strYourText
    call WriteString

    ; --- Decoding Logic ---
    mov  edi, OFFSET decodedBuffer
    mov  ecx, 100
    xor  al, al
    rep  stosb
    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    mov  ebp, OFFSET decodedBuffer
    cmp  ecx, 0
    je   DecodeEnd
ParseLoop:
    mov  edi, OFFSET tokenBuffer
    mov  tokenLen, 0
ExtractToken:
    cmp  ecx, 0
    je   EndToken
    mov  al, [esi]
    cmp  al, ' '
    je   SpaceFound
    ; --- Valid Morse char filter: only '.', '-', '/' are stored ---
    cmp  al, '.'
    je   MT_StoreChar
    cmp  al, '-'
    je   MT_StoreChar
    cmp  al, '/'
    je   MT_StoreChar
    ; Not a valid Morse character - skip it silently
    inc  esi
    dec  ecx
    jmp  ExtractToken
MT_StoreChar:
    mov  [edi], al
    inc  edi
    inc  tokenLen
    inc  esi
    dec  ecx
    ; --- Token overflow guard: cap at 19 chars to protect tokenBuffer ---
    cmp  tokenLen, 19
    jge  FindLookup
    jmp  ExtractToken
SpaceFound:
    inc  esi
    dec  ecx
    cmp  tokenLen, 0
    je   ParseLoop
    jmp  FindLookup
EndToken:
    cmp  tokenLen, 0
    je   PrintResult
FindLookup:
    mov  byte ptr [edi], 0
    mov  edi, OFFSET tokenBuffer
    cmp  byte ptr [edi], '/'
    jne  CheckAlpha
    mov  byte ptr [ebp], ' '
    inc  ebp
    jmp  ParseLoop
CheckAlpha:
    mov  ebx, 0
AlphaLoop:
    mov  edi, OFFSET tokenBuffer
    mov  edx, MorseTableAlpha[ebx*4]
    push esi
    mov  esi, edx
    call CompareStrings
    pop  esi
    je   FoundAlpha
    inc  ebx
    cmp  ebx, 26
    jl   AlphaLoop
    mov  ebx, 0
DigitLoop:
    mov  edi, OFFSET tokenBuffer
    mov  edx, MorseTableDigit[ebx*4]
    push esi
    mov  esi, edx
    call CompareStrings
    pop  esi
    je   FoundDigit
    inc  ebx
    cmp  ebx, 10
    jl   DigitLoop
    mov  byte ptr [ebp], '?'
    inc  ebp
    jmp  ParseLoop
FoundAlpha:
    mov  al, 'A'
    add  al, bl
    mov  [ebp], al
    inc  ebp
    jmp  ParseLoop
FoundDigit:
    mov  al, '0'
    add  al, bl
    mov  [ebp], al
    inc  ebp
    jmp  ParseLoop
PrintResult:
    mov  dl, 22
    mov  dh, 15
    call Gotoxy
    mov  al, COLOR_MORSE
    call SetTextColor
    mov  edx, OFFSET decodedBuffer
    call WriteString
DecodeEnd:
Dec_WaitKey:
    mov  dh, 24
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_DIM
    call SetTextColor
    mov  edx, OFFSET strPressAny
    call WriteString
    call ReadChar
    ret
DoDecoding ENDP
