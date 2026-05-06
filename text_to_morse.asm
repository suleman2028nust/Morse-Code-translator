; =============================================================================
; text_to_morse.asm  –  Text → Morse  (Visual / Silent mode)
; =============================================================================

.DATA
strModeVis   BYTE "   TEXT  TO  MORSE  ENCODING   |   VISUAL  MODE   ", 0

.CODE

; =============================================================================
; PROC: EncodeVisual (Left-Aligned Standard Characters)
; =============================================================================
EncodeVisual PROC
    mov  al, COLOR_MORSE
    call SetTextColor
    mov  dl, 0
    mov  dh, MORSE_ROW
    call Gotoxy

    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    cmp  ecx, 0
    je   EV_End

EV_Outer:
    mov  al, [esi]
    inc  esi
    cmp  al, 'a'
    jl   EV_CheckUpper
    cmp  al, 'z'
    jg   EV_CheckUpper
    sub  al, 32
EV_CheckUpper:
    cmp  al, '0'
    jl   EV_NotAlpha
    cmp  al, '9'
    jle  EV_IsDigit
    cmp  al, 'A'
    jl   EV_NotAlpha
    cmp  al, 'Z'
    jle  EV_IsLetter

EV_NotAlpha:
    cmp  al, ' '
    je   EV_WordSep
    ; --- Invalid character: show brief notice, then skip ---
    push ecx
    push esi
    mov  dh, 22
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strInvalidChar
    call WriteString
    mov  eax, 700
    call Delay
    mov  dh, 22
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_NORMAL
    call SetTextColor
    mov  edx, OFFSET strBlankLine
    call WriteString
    pop  esi
    pop  ecx
    jmp  EV_Next
EV_WordSep:
    mov  edx, OFFSET strWordSep
    call WriteString
    jmp  EV_Next
EV_IsLetter:
    movzx edi, al
    sub   edi, 'A'
    mov   edx, MorseTableAlpha[edi*4]
    jmp   EV_Symbols
EV_IsDigit:
    movzx edi, al
    sub   edi, '0'
    mov   edx, MorseTableDigit[edi*4]

EV_Symbols:
    push  ecx
    push  esi
    mov   esi, edx
EV_Inner:
    mov  al, [esi]
    cmp  al, 0
    je   EV_InnerDone
    call WriteChar
    mov  eax, SYMBOL_DELAY
    call Delay
    inc  esi
    jmp  EV_Inner
EV_InnerDone:
    mov  edx, OFFSET strLetterGap
    call WriteString
    mov  eax, LETTER_DELAY
    call Delay
    pop  esi
    pop  ecx

EV_Next:
    dec  ecx
    jnz  EV_Outer

EV_End:
    ret
EncodeVisual ENDP

DoEncodingVisual PROC
    call DrawTitleBar
    INVOKE DrawSubHeader, OFFSET strModeVis

    ; Row 8 - Section
    mov  dh, 8
    call PrintSectionLine

    ; Row 11 - Input Prompt
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
    cmp  inputLen, 0
    jne  DEV_CheckMorse
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strNoInput
    call WriteString
    jmp  DEV_WaitKey
DEV_CheckMorse:
    call CheckIfMorseInput
    cmp  eax, 1
    jne  DEV_HasInput
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strTextNotMorse
    call WriteString
    jmp  DEV_WaitKey
DEV_HasInput:
    ; Row 13 - Output section
    mov  dh, 13
    call PrintSectionLine
    
    ; Row 15 - Morse label
    mov  dh, 15
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strYourMorse
    call WriteString
    
    call EncodeVisual
DEV_WaitKey:
    mov  dh, 24
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_DIM
    call SetTextColor
    mov  edx, OFFSET strPressAny
    call WriteString
    call ReadChar
    ret
DoEncodingVisual ENDP
