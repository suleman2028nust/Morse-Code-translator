; =============================================================================
; morse_to_blink.asm  –  Morse Blink / Flash mode
; =============================================================================

STD_OUTPUT_HANDLE_VAL   EQU 0FFFFFFF5h
BLINK_COLOR_ON          EQU 0FFh
BLINK_COLOR_OFF         EQU 000h

BLINK_X                 EQU 10
BLINK_Y                 EQU 20
BLINK_WIDTH             EQU 60
BLINK_HEIGHT            EQU 5

.DATA
strModeBlink     BYTE "   MORSE  TO  BLINK  CODE  TRANSMISSION   |   FLASH MODE   ", 0
strBlinkingLabel BYTE "   STATUS  :   TRANSMITTING VISUAL PULSES ...", 0

.DATA?
hMainConsole   DWORD ?
dwCellsWritten DWORD ?
dwAttrsWritten DWORD ?
wHighlightAttr WORD  ?
wNormalAttr    WORD  ?

.CODE

BlinkOn PROC
    LOCAL row:DWORD
    mov  row, 0
BON_Loop:
    movzx eax, byte ptr row
    add   eax, BLINK_Y
    shl   eax, 16
    or    eax, BLINK_X
    push  OFFSET dwCellsWritten
    push  eax
    push  BLINK_WIDTH
    push  BLINK_COLOR_ON
    push  hMainConsole
    call  FillConsoleOutputAttribute
    inc   row
    cmp   row, BLINK_HEIGHT
    jl    BON_Loop
    ret
BlinkOn ENDP

BlinkOff PROC
    LOCAL row:DWORD
    mov  row, 0
BOFF_Loop:
    movzx eax, byte ptr row
    add   eax, BLINK_Y
    shl   eax, 16
    or    eax, BLINK_X
    push  OFFSET dwCellsWritten
    push  eax
    push  BLINK_WIDTH
    push  BLINK_COLOR_OFF
    push  hMainConsole
    call  FillConsoleOutputAttribute
    inc   row
    cmp   row, BLINK_HEIGHT
    jl    BOFF_Loop
    ret
BlinkOff ENDP

HighlightOn PROC
    movzx eax, bl
    mov   edx, MORSE_ROW
    shl   edx, 16
    or    eax, edx
    push  OFFSET dwAttrsWritten
    push  eax
    push  1
    push  OFFSET wHighlightAttr
    push  hMainConsole
    call  WriteConsoleOutputAttribute
    ret
HighlightOn ENDP

HighlightOff PROC
    movzx eax, bl
    mov   edx, MORSE_ROW
    shl   edx, 16
    or    eax, edx
    push  OFFSET dwAttrsWritten
    push  eax
    push  1
    push  OFFSET wNormalAttr
    push  hMainConsole
    call  WriteConsoleOutputAttribute
    ret
HighlightOff ENDP

EncodeBlink PROC
    mov  al, COLOR_MORSE
    call SetTextColor
    mov  dl, 0
    mov  dh, MORSE_ROW
    call Gotoxy

    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    cmp  ecx, 0
    je   EB_End

EB_C_Outer:
    mov  al, [esi]
    inc  esi
    cmp  al, 'a'
    jl   EB_C_Upper
    cmp  al, 'z'
    jg   EB_C_Upper
    sub  al, 32
EB_C_Upper:
    cmp  al, '0'
    jl   EB_C_NotAlpha
    cmp  al, '9'
    jle  EB_C_Digit
    cmp  al, 'A'
    jl   EB_C_NotAlpha
    cmp  al, 'Z'
    jle  EB_C_Letter

EB_C_NotAlpha:
    cmp  al, ' '
    je   EB_C_Word
    jmp  EB_C_Next
EB_C_Word:
    mov  edx, OFFSET strWordSep
    call WriteString
    jmp  EB_C_Next
EB_C_Letter:
    movzx edi, al
    sub   edi, 'A'
    mov   edx, MorseTableAlpha[edi*4]
    jmp   EB_C_Syms
EB_C_Digit:
    movzx edi, al
    sub   edi, '0'
    mov   edx, MorseTableDigit[edi*4]
EB_C_Syms:
    push  ecx
    push  esi
    mov   esi, edx
EB_C_Inner:
    mov  al, [esi]
    cmp  al, 0
    je   EB_C_InDone
    call WriteChar
    inc  esi
    jmp  EB_C_Inner
EB_C_InDone:
    mov  edx, OFFSET strLetterGap
    call WriteString
    pop  esi
    pop  ecx
EB_C_Next:
    dec  ecx
    jnz  EB_C_Outer

    mov  dh, 18
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strBlinkingLabel
    call WriteString
    mov  eax, 500
    call Delay
    INVOKE GetStdHandle, STD_OUTPUT_HANDLE_VAL
    mov   hMainConsole, eax
    ; --- GetStdHandle failure guard ---
    test  eax, eax
    jz    EB_HandleError
    cmp   eax, 0FFFFFFFFh
    je    EB_HandleError
    jmp   EB_HandleOk
EB_HandleError:
    mov  dh, 22
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strHandleErr
    call WriteString
    jmp  EB_End
EB_HandleOk:
    mov   WORD PTR wHighlightAttr, COLOR_HIGHLIGHT
    mov   WORD PTR wNormalAttr,    COLOR_MORSE

    xor  ebx, ebx
    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
EB_A_Outer:
    mov  al, [esi]
    inc  esi
    cmp  al, 'a'
    jl   EB_A_Upper
    cmp  al, 'z'
    jg   EB_A_Upper
    sub  al, 32
EB_A_Upper:
    cmp  al, '0'
    jl   EB_A_NotAlpha
    cmp  al, '9'
    jle  EB_A_Digit
    cmp  al, 'A'
    jl   EB_A_NotAlpha
    cmp  al, 'Z'
    jle  EB_A_Letter

EB_A_NotAlpha:
    cmp  al, ' '
    je   EB_A_Word
    jmp  EB_A_Next
EB_A_Word:
    add  ebx, 3
    push ecx
    mov  eax, LETTER_DELAY
    call Delay
    pop  ecx
    jmp  EB_A_Next
EB_A_Letter:
    movzx edi, al
    sub   edi, 'A'
    mov   edx, MorseTableAlpha[edi*4]
    jmp   EB_A_Syms
EB_A_Digit:
    movzx edi, al
    sub   edi, '0'
    mov   edx, MorseTableDigit[edi*4]
EB_A_Syms:
    push  ecx
    push  esi
    mov   esi, edx
EB_A_Inner:
    mov  al, [esi]
    cmp  al, 0
    je   EB_A_InDone
    call HighlightOn
    mov  al, [esi]
    cmp  al, '.'
    je   EB_A_Dot
    call BlinkOn
    mov  eax, DASH_DURATION
    call Delay
    call BlinkOff
    jmp  EB_A_AfterPulse
EB_A_Dot:
    call BlinkOn
    mov  eax, DOT_DURATION
    call Delay
    call BlinkOff
EB_A_AfterPulse:
    call HighlightOff
    mov  eax, SYMBOL_DELAY
    call Delay
    inc  ebx
    inc  esi
    jmp  EB_A_Inner
EB_A_InDone:
    inc  ebx
    mov  eax, LETTER_DELAY
    call Delay
    pop  esi
    pop  ecx
EB_A_Next:
    dec  ecx
    jnz  EB_A_Outer
EB_End:
    ret
EncodeBlink ENDP

DoEncodingBlink PROC
    call DrawTitleBar
    INVOKE DrawSubHeader, OFFSET strModeBlink
    
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
    jne  EB_CheckMorse
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strNoInput
    call WriteString
    jmp  EB_WaitKey
EB_CheckMorse:
    call CheckIfMorseInput
    cmp  eax, 1
    jne  EB_HasInput
    mov  dh, 20
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strTextNotMorse
    call WriteString
    jmp  EB_WaitKey
EB_HasInput:

    mov  dh, 13
    call PrintSectionLine

    mov  dh, 15
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strYourMorse
    call WriteString
    
    call EncodeBlink
    
EB_WaitKey:
    mov  dh, 27
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_DIM
    call SetTextColor
    mov  edx, OFFSET strPressAny
    call WriteString
    call ReadChar
    ret
DoEncodingBlink ENDP
