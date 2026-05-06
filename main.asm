; =============================================================================
; main.asm - Main Entry Point  |  Morse Code Translator
; BIG PREMIUM TERMINAL UI - Restoration v2
; =============================================================================
INCLUDE Irvine32.inc
Beep              PROTO, dwFreq:DWORD, dwDuration:DWORD
CreateThread      PROTO, lpAttr:DWORD, dwStack:DWORD, lpStart:DWORD, lpParam:DWORD, dwFlags:DWORD, lpId:DWORD
WaitForSingleObject PROTO, hHandle:DWORD, dwMs:DWORD
CloseHandle       PROTO, hObject:DWORD
FreeConsole       PROTO
AllocConsole      PROTO
GetStdHandle      PROTO, nStdHandle:DWORD
FillConsoleOutputAttribute PROTO, hConsoleOutput:DWORD, wAttribute:DWORD, nLength:DWORD, dwWriteCoord:DWORD, lpNumberOfAttrsWritten:DWORD
WriteConsoleOutputAttribute PROTO, outHandle:DWORD, pAttribute:PTR WORD, nLength:DWORD, xyCoord:COORD, lpCount:PTR DWORD
LoadLibraryA      PROTO, lpLibFileName:DWORD
GetProcAddress    PROTO, hModule:DWORD, lpProcName:DWORD

; --- Global constants (timing, colours, layout) -----------------------------
INCLUDE morse_timing.asm

.DATA
; --- Double-line box strings (76 chars wide) --------------------------------
strTopBorder BYTE 0C9h, 74 DUP(0CDh), 0BBh, 0
strDivider   BYTE 0CCh, 74 DUP(0CDh), 0B9h, 0
strBotBorder BYTE 0C8h, 74 DUP(0CDh), 0BCh, 0
strWall      BYTE 0BAh, 0

; --- Full-width thin line (78 chars) ----------------------------------------
strSectionLine BYTE 78 DUP(0C4h), 0

; --- Title text -------------------------------------------------------------
strTitle1    BYTE "               - . -     M  O  R  S  E      -  .  -                ", 0
strTitle2    BYTE "                   C  O  D  E     T  R  A  N  S  L  A  T  O  R                   ", 0

; --- Main-menu items --------------------------------------------------------
strMenu1     BYTE "       [ 1 ]   TEXT  TO  MORSE  ENCODING   (VISUAL MODE)              ", 0
strMenu2     BYTE "       [ 2 ]   TEXT  TO  MORSE  ENCODING   (SOUND / AUDIO)            ", 0
strMenuDecode BYTE "       [ 3 ]   MORSE  TO  TEXT  DECODING   (TRANSLATION)              ", 0
strMenuBlink BYTE "       [ 4 ]   MORSE  CODE  VISUAL  BLINK  (FLASH MODE)                ", 0
strMenuExit  BYTE "       [ 5 ]   EXIT  PROGRAM                                          ", 0

; --- Prompt / status --------------------------------------------------------
strMenuPrompt BYTE "       SELECT OPTION  [ 1 - 5 ] :  ", 0
strInvalid    BYTE "  >> INVALID KEY. PLEASE USE 1-5.", 0

; --- Shared sub-screen labels -----------------------------------------------
strEnterText  BYTE "   ENTER TEXT   :  ", 0
strYourMorse  BYTE "   MORSE CODE   :  ", 0
strPlayingLabel BYTE "   STATUS       :  PLAYING TRANSMISSION ...", 0
strEnterMorse BYTE "   ENTER MORSE  :  ", 0
strYourText   BYTE "   DECODED TEXT :  ", 0
strPressAny   BYTE "   PRESS ANY KEY TO RETURN TO MENU ...", 0
strInvalidChar BYTE "   [SKIPPING INVALID CHARACTER]", 0
strNoInput    BYTE "  >> ERROR: NO DATA PROVIDED. PLEASE ENTER A VALID SEQUENCE.", 0
strEmptyMorse BYTE "  >> ERROR: NO DATA PROVIDED. PLEASE ENTER A VALID SEQUENCE.", 0
strHandleErr  BYTE "  >> CRITICAL ERROR: CONSOLE HANDLE ACQUISITION FAILED.", 0
strTextNotMorse BYTE "  >> FORMAT ERROR: EXPECTED TEXT (A-Z, 0-9), BUT DETECTED MORSE CODE.", 0
strMorseNotText BYTE "  >> FORMAT ERROR: EXPECTED MORSE CODE (., -, /), BUT DETECTED TEXT.", 0
strBlankLine  BYTE "                                                            ", 0

; --- Morse table ------------------------------------------------------------
INCLUDE morse_table.asm

.DATA?
inputBuffer   BYTE MAX_INPUT_LEN+1 DUP(?)
inputLen      DWORD ?

.CODE

; =============================================================================
; Shared UI procedures
; =============================================================================

PrintWall PROC
    push eax
    push edx
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strWall
    call WriteString
    pop  edx
    pop  eax
    ret
PrintWall ENDP

PrintRightWall PROC
    push eax
    push edx
    mov  dl, BOX_RIGHT
    call Gotoxy
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strWall
    call WriteString
    pop  edx
    pop  eax
    ret
PrintRightWall ENDP

PrintTopBorder PROC
    mov  dl, BOX_LEFT
    call Gotoxy
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strTopBorder
    call WriteString
    ret
PrintTopBorder ENDP

PrintDivider PROC
    mov  dl, BOX_LEFT
    call Gotoxy
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strDivider
    call WriteString
    ret
PrintDivider ENDP

PrintBotBorder PROC
    mov  dl, BOX_LEFT
    call Gotoxy
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strBotBorder
    call WriteString
    ret
PrintBotBorder ENDP

PrintSectionLine PROC
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_BORDER
    call SetTextColor
    mov  edx, OFFSET strSectionLine
    call WriteString
    ret
PrintSectionLine ENDP

DrawTitleBar PROC
    mov  al, COLOR_NORMAL
    call SetTextColor
    call Clrscr
    mov  dh, 1
    call PrintTopBorder
    mov  dh, 2
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_TITLE
    call SetTextColor
    mov  edx, OFFSET strTitle1
    call WriteString
    mov  dh, 2
    call PrintRightWall
    mov  dh, 3
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_TITLE_ACC
    call SetTextColor
    mov  edx, OFFSET strTitle2
    call WriteString
    mov  dh, 3
    call PrintRightWall
    mov  dh, 4
    call PrintDivider
    ret
DrawTitleBar ENDP

DrawSubHeader PROC pMode:DWORD
    mov  dh, 5
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, pMode
    call WriteString
    mov  dh, 5
    call PrintRightWall
    mov  dh, 6
    call PrintBotBorder
    ret
DrawSubHeader ENDP

DrawMainMenu PROC
    call ClearLowerDisplay
    call DrawTitleBar
    mov  dh, 5
    call PrintTopBorder
    mov  dh, 6
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET strMenu1
    call WriteString
    mov  dh, 6
    call PrintRightWall
    mov  dh, 7
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET strMenu2
    call WriteString
    mov  dh, 7
    call PrintRightWall
    mov  dh, 8
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET strMenuDecode
    call WriteString
    mov  dh, 8
    call PrintRightWall
    mov  dh, 9
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_INPUT
    call SetTextColor
    mov  edx, OFFSET strMenuBlink
    call WriteString
    mov  dh, 9
    call PrintRightWall
    mov  dh, 10
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strMenuExit
    call WriteString
    mov  dh, 10
    call PrintRightWall
    mov  dh, 11
    call PrintDivider
    mov  dh, 12
    mov  dl, BOX_LEFT
    call Gotoxy
    call PrintWall
    mov  al, COLOR_PROMPT
    call SetTextColor
    mov  edx, OFFSET strMenuPrompt
    call WriteString
    mov  dh, 13
    call PrintBotBorder
    mov  dh, 12
    mov  dl, 40
    call Gotoxy
    mov  al, COLOR_INPUT
    call SetTextColor
    ret
DrawMainMenu ENDP

; =============================================================================
; PROCEDURE: ClearLowerDisplay
;   Clears potential ghosting text in rows 14-29
; =============================================================================
ClearLowerDisplay PROC
    pushad
    mov  al, COLOR_NORMAL
    call SetTextColor
    mov  dh, 14
CLD_Loop:
    mov  dl, 0
    call Gotoxy
    push edx
    mov  edx, OFFSET strBlankLine
    call WriteString
    call WriteString  ; 50 + 50 = 100 chars (overflow is fine)
    pop  edx
    inc  dh
    cmp  dh, 29
    jl   CLD_Loop
    popad
    ret
ClearLowerDisplay ENDP

; =============================================================================
; Input Validation Helpers
; =============================================================================
CheckIfMorseInput PROC
    push esi
    push ecx
    push edx
    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    cmp  ecx, 0
    je   CMI_False
    mov  edx, 0
CMI_Loop:
    mov  al, [esi]
    cmp  al, '.'
    je   CMI_IsMorseChar
    cmp  al, '-'
    je   CMI_IsMorseChar
    cmp  al, '/'
    je   CMI_IsMorseChar
    cmp  al, ' '
    je   CMI_Next
    jmp  CMI_False
CMI_IsMorseChar:
    inc  edx
CMI_Next:
    inc  esi
    dec  ecx
    jnz  CMI_Loop
    cmp  edx, 0
    jg   CMI_True
CMI_False:
    mov  eax, 0
    jmp  CMI_End
CMI_True:
    mov  eax, 1
CMI_End:
    pop  edx
    pop  ecx
    pop  esi
    ret
CheckIfMorseInput ENDP

CheckIfTextInput PROC
    push esi
    push ecx
    push edx
    mov  esi, OFFSET inputBuffer
    mov  ecx, inputLen
    cmp  ecx, 0
    je   CTI_False
    mov  edx, 0
CTI_Loop:
    mov  al, [esi]
    cmp  al, 'A'
    jl   CTI_CheckDigit
    cmp  al, 'Z'
    jle  CTI_IsAlphaNum
    cmp  al, 'a'
    jl   CTI_Next
    cmp  al, 'z'
    jle  CTI_IsAlphaNum
    jmp  CTI_Next
CTI_CheckDigit:
    cmp  al, '0'
    jl   CTI_Next
    cmp  al, '9'
    jle  CTI_IsAlphaNum
    jmp  CTI_Next
CTI_IsAlphaNum:
    inc  edx
CTI_Next:
    inc  esi
    dec  ecx
    jnz  CTI_Loop
    cmp  edx, 0
    jg   CTI_True
CTI_False:
    mov  eax, 0
    jmp  CTI_End
CTI_True:
    mov  eax, 1
CTI_End:
    pop  edx
    pop  ecx
    pop  esi
    ret
CheckIfTextInput ENDP

; --- Main Entry Point ---
main PROC
MenuLoop:
    call DrawMainMenu
    call ReadChar
    cmp  al, '1'
    je   Main_DoVisual
    cmp  al, '2'
    je   Main_DoSound
    cmp  al, '3'
    je   Main_DoDecode
    cmp  al, '4'
    je   Main_DoBlink
    cmp  al, '5'
    je   Main_ExitProg
    mov  dh, 15
    mov  dl, 0
    call Gotoxy
    mov  al, COLOR_ERROR
    call SetTextColor
    mov  edx, OFFSET strInvalid
    call WriteString
    mov  eax, 1000
    call Delay
    jmp  MenuLoop
Main_DoVisual:
    call DoEncodingVisual
    jmp  MenuLoop
Main_DoSound:
    call DoEncodingSound
    jmp  MenuLoop
Main_DoDecode:
    call DoDecoding
    jmp  MenuLoop
Main_DoBlink:
    call DoEncodingBlink
    jmp  MenuLoop
Main_ExitProg:
    mov  al, COLOR_NORMAL
    call SetTextColor
    call Clrscr
    exit
main ENDP

; --- Include sub-modules AFTER procedures to avoid undefined symbols ---
INCLUDE morse_to_sound.asm
INCLUDE text_to_morse.asm
INCLUDE morse_to_text.asm
INCLUDE morse_to_blink.asm

END main
