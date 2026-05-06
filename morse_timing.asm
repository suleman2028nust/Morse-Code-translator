; =============================================================================
; morse_timing.asm - Constants, Timing Definitions, and Layout Parameters
; =============================================================================

; --- Input / Timing Constants -----------------------------------------------
MAX_INPUT_LEN   EQU 60                  ; max characters user may type

DOT_FREQ        EQU 800                 ; Hz for both dot and dash beep
DOT_DURATION    EQU 150                 ; ms – short beep  (dot)
DASH_DURATION   EQU 400                 ; ms – long  beep  (dash)
SYMBOL_DELAY    EQU 80                  ; ms between symbols within one letter
LETTER_DELAY    EQU 250                 ; ms between letters
HIGHLIGHT_DURATION EQU 600             ; ms the colour-flash stays on
AUDIO_PRE_DELAY EQU 00                  ; ms latency compensation

; --- Screen Layout Parameters (BIG UI Edition) ------------------------------
; Target terminal width is 80 columns.
; BOX_WIDTH include walls. 2 walls + 74 inner = 76 total.
; BOX_LEFT=2 ... BOX_RIGHT=77
BOX_LEFT        EQU 2
BOX_WIDTH       EQU 76
BOX_RIGHT       EQU 77

; Row where Morse-code output is displayed
MORSE_ROW       EQU 16

; --- Colour Attributes ------------------------------------------------------
COLOR_TITLE     EQU 09h                 ; bright-blue on black
COLOR_TITLE_ACC EQU 0Bh                 ; bright-cyan on black
COLOR_NORMAL    EQU 07h                 ; gray on black
COLOR_INPUT     EQU 0Eh                 ; yellow on black
COLOR_MORSE     EQU 0Ah                 ; bright-green on black
COLOR_BORDER    EQU 09h                 ; bright-blue on black
COLOR_PROMPT    EQU 0Bh                 ; bright-cyan on black
COLOR_ERROR     EQU 0Ch                 ; bright-red on black
COLOR_HIGHLIGHT EQU 0E0h              ; black on bright-yellow
COLOR_MENU_KEY  EQU 0Fh                 ; bright-white on black
COLOR_STATUS    EQU 02h                 ; dark-green on black
COLOR_DIM       EQU 08h                 ; dark-gray on black
