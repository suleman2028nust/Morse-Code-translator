; =============================================================================
; morse_to_sound.asm  –  Text → Morse  (Sound / Audio mode)
; =============================================================================

.DATA
strModeSound BYTE "   TEXT  TO  MORSE  ENCODING   |   SOUND  MODE   ", 0

.DATA?
beepFreq    DWORD ?
beepDur     DWORD ?
hBeepThread DWORD ?
dwThreadId  DWORD ?

.Code

BeepThreadProc PROC lpParam:DWORD
    INVOKE Beep, beepFreq, beepDur
    xor    eax, eax
    ret
BeepThreadProc ENDP

EncodeSound PROC
    mov  al, COLOR_MORSE
    call SetTextColor
    mov  dl, 0
    mov  dh, MORSE_ROW
    call Gotoxy

    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    cmp  ecx, 0
    je   ES_End

ES_C_Outer:
    mov  al, [esi]
    inc  esi
    cmp  al, 'a'
    jl   ES_C_Upper
    cmp  al, 'z'
    jg   ES_C_Upper
    sub  al, 32
ES_C_Upper:
    cmp  al, '0'
    jl   ES_C_NotAlpha
    cmp  al, '9'
    jle  ES_C_Digit
    cmp  al, 'A'
    jl   ES_C_NotAlpha
    cmp  al, 'Z'
    jle  ES_C_Letter

ES_C_NotAlpha:
    cmp  al, ' '
    je   ES_C_Word
    jmp  ES_C_Next
ES_C_Word:
    mov  edx, OFFSET strWordSep
    call WriteString
    jmp  ES_C_Next
ES_C_Letter:
    movzx edi, al
    sub   edi, 'A'
    mov   edx, MorseTableAlpha[edi*4]
    jmp   ES_C_Syms
ES_C_Digit:
    movzx edi, al
    sub   edi, '0'
    mov   edx, MorseTableDigit[edi*4]
ES_C_Syms:
    push  ecx
    push  esi
    mov   esi, edx
ES_C_Inner:
    mov  al, [esi]
    cmp  al, 0
    je   ES_C_InDone
    call WriteChar
    inc  esi
    jmp  ES_C_Inner
ES_C_InDone:
    mov  edx, OFFSET strLetterGap
    call WriteString
    pop  esi
    pop  ecx
ES_C_Next:
    dec  ecx
    jnz  ES_C_Outer

    mov  dh, 18
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strPlayingLabel
    call WriteString
    mov  eax, 500
    call Delay
    
    xor  ebx, ebx
    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
ES_A_Outer:
    mov  al, [esi]
    inc  esi
    cmp  al, 'a'
    jl   ES_A_Upper
    cmp  al, 'z'
    jg   ES_A_Upper
    sub  al, 32
ES_A_Upper:
    cmp  al, '0'
    jl   ES_A_NotAlpha
    cmp  al, '9'
    jle  ES_A_Digit
    cmp  al, 'A'
    jl   ES_A_NotAlpha
    cmp  al, 'Z'
    jle  ES_A_Letter

ES_A_NotAlpha:
    cmp  al, ' '
    je   ES_A_Word
    jmp  ES_A_Next
ES_A_Word:
    add  ebx, 3
    mov  eax, LETTER_DELAY
    call Delay
    jmp  ES_A_Next
ES_A_Letter:
    movzx edi, al
    sub   edi, 'A'
    mov   edx, MorseTableAlpha[edi*4]
    jmp   ES_A_Syms
ES_A_Digit:
    movzx edi, al
    sub   edi, '0'
    mov   edx, MorseTableDigit[edi*4]
ES_A_Syms:
    push  ecx
    push  esi
    mov   esi, edx
ES_A_Inner:
    mov  al, [esi]
    cmp  al, 0
    je   ES_A_InDone
    mov  dl, bl
    mov  dh, MORSE_ROW
    call Gotoxy
    mov  al, COLOR_HIGHLIGHT
    call SetTextColor
    mov  al, [esi]
    call WriteChar
    cmp  al, '.'
    je   ES_A_Dot
    mov  beepFreq, DOT_FREQ
    mov  beepDur,  DASH_DURATION
    jmp  ES_A_Launch
ES_A_Dot:
    mov  beepFreq, DOT_FREQ
    mov  beepDur,  DOT_DURATION
ES_A_Launch:
    INVOKE CreateThread, NULL, 0, OFFSET BeepThreadProc, NULL, 0, ADDR dwThreadId
    mov  hBeepThread, eax
    mov  eax, HIGHLIGHT_DURATION
    call Delay
    mov  dl, bl
    mov  dh, MORSE_ROW
    call Gotoxy
    mov  al, COLOR_MORSE
    call SetTextColor
    mov  al, [esi]
    call WriteChar
    ; --- CreateThread NULL-handle guard: only wait/close if thread was created ---
    cmp  hBeepThread, 0
    je   ES_A_ThreadDone
    INVOKE WaitForSingleObject, hBeepThread, 0FFFFFFFFh
    INVOKE CloseHandle, hBeepThread
ES_A_ThreadDone:
    mov  eax, SYMBOL_DELAY
    call Delay
    inc  ebx
    inc  esi
    jmp  ES_A_Inner
ES_A_InDone:
    inc  ebx
    mov  eax, LETTER_DELAY
    call Delay
    pop  esi
    pop  ecx
ES_A_Next:
    dec  ecx
    jnz  ES_A_Outer
ES_End:
    ret
EncodeSound ENDP

DoEncodingSound PROC
    call DrawTitleBar
    INVOKE DrawSubHeader, OFFSET strModeSound
    mov  dh, 8
    call PrintSectionLine

    mov  dh, 11
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strEnterText
    call WriteString
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET inputBuffer
    mov  ecx, MAX_INPUT_LEN
    call ReadString
    mov  inputLen, eax
    ; --- Empty input guard ---
    cmp  eax, 0
    jne  ES_CheckMorse
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strNoInput
    call WriteString
    jmp  ES_WaitKey
ES_CheckMorse:
    call CheckIfMorseInput
    cmp  eax, 1
    jne  ES_HasInput
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strTextNotMorse
    call WriteString
    jmp  ES_WaitKey
ES_HasInput:
    mov  dh, 13
    call PrintSectionLine

    mov  dh, 15
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strYourMorse
    call WriteString
    call EncodeSound
ES_WaitKey:
    mov  dh, 24
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_DIM
    call SetTextColor
    mov  edx, OFFSET strPressAny
    call WriteString
    call ReadChar
    ret
DoEncodingSound ENDP
