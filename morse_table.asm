; =============================================================================
; morse_table.asm - Morse Code Lookup Table
; =============================================================================

; --- Morse string constants -------------------------------------------------
strSpace        BYTE " ", 0
strDot          BYTE ".", 0
strDash         BYTE "-", 0
strLetterGap    BYTE " ", 0           
strWordSep      BYTE " / ", 0         

MorseA  BYTE ".-",   0
MorseB  BYTE "-...", 0
MorseC  BYTE "-.-.", 0
MorseD  BYTE "-..",  0
MorseE  BYTE ".",    0
MorseF  BYTE "..-.", 0
MorseG  BYTE "--.",  0
MorseH  BYTE "....", 0
MorseI  BYTE "..",   0
MorseJ  BYTE ".---", 0
MorseK  BYTE "-.-",  0
MorseL  BYTE ".-..", 0
MorseM  BYTE "--",   0
MorseN  BYTE "-.",   0
MorseO  BYTE "---",  0
MorseP  BYTE ".--.", 0
MorseQ  BYTE "--.-", 0
MorseR  BYTE ".-.",  0
MorseS  BYTE "...",  0
MorseT  BYTE "-",    0
MorseU  BYTE "..-",  0
MorseV  BYTE "...-", 0
MorseW  BYTE ".--",  0
MorseX  BYTE "-..-", 0
MorseY  BYTE "-.--", 0
MorseZ  BYTE "--..", 0

Morse0  BYTE "-----", 0
Morse1  BYTE ".----", 0
Morse2  BYTE "..---", 0
Morse3  BYTE "...--", 0
Morse4  BYTE "....-", 0
Morse5  BYTE ".....", 0
Morse6  BYTE "-....", 0
Morse7  BYTE "--...", 0
Morse8  BYTE "---..", 0
Morse9  BYTE "----.", 0

; Pointer table – 26 letters (A=0 … Z=25)
;[
; MorseA is stored at → 00401000
;which is a 32 bit no
;]

MorseTableAlpha DWORD OFFSET MorseA, OFFSET MorseB, OFFSET MorseC
                DWORD OFFSET MorseD, OFFSET MorseE, OFFSET MorseF
                DWORD OFFSET MorseG, OFFSET MorseH, OFFSET MorseI
                DWORD OFFSET MorseJ, OFFSET MorseK, OFFSET MorseL
                DWORD OFFSET MorseM, OFFSET MorseN, OFFSET MorseO
                DWORD OFFSET MorseP, OFFSET MorseQ, OFFSET MorseR
                DWORD OFFSET MorseS, OFFSET MorseT, OFFSET MorseU
                DWORD OFFSET MorseV, OFFSET MorseW, OFFSET MorseX
                DWORD OFFSET MorseY, OFFSET MorseZ

; Pointer table – 10 digits (0=0 … 9=9)
MorseTableDigit DWORD OFFSET Morse0, OFFSET Morse1, OFFSET Morse2
                DWORD OFFSET Morse3, OFFSET Morse4, OFFSET Morse5
                DWORD OFFSET Morse6, OFFSET Morse7, OFFSET Morse8
                DWORD OFFSET Morse9
