LIST P=16F887
        #INCLUDE <P16F887.INC>

        __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
        __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

; ==============================================================================
; VARIABLES EN RAM (BANCO 0)
; ==============================================================================
        CBLOCK 0x20
        CENT
        SEG
        U_CENT
        D_CENT
        U_SEG
        D_SEG
        DISPLAY
        AUX
        ENDC

; VARIABLES DE CONTEXTO (BANCO COMÚN 0x70)
        CBLOCK 0x70
        W_TEMP
        STATUS_TEMP
        PCLATH_TEMP
        ENDC

; ==============================================================================
; VECTORES
; ==============================================================================
        ORG 0x0000
        GOTO INICIO

        ORG 0x0004
ISR:
        MOVWF W_TEMP
        SWAPF STATUS,W
        MOVWF STATUS_TEMP
        BCF STATUS,RP0
        BCF STATUS,RP1
        MOVF PCLATH,W
        MOVWF PCLATH_TEMP
        CLRF PCLATH

; Refresco de pantallas
        CALL MULTIPLEXAR

FIN_ISR:
        BCF STATUS,RP0
        BCF STATUS,RP1
        MOVF PCLATH_TEMP,W
        MOVWF PCLATH
        SWAPF STATUS_TEMP,W
        MOVWF STATUS
        SWAPF W_TEMP,F
        SWAPF W_TEMP,W
        RETFIE

; ==============================================================================
; CONFIGURACIÓN INICIAL
; ==============================================================================
INICIO:
; Todo digital
        BANKSEL ANSEL
        CLRF ANSEL
        CLRF ANSELH

; PORTB como salidas (Segmentos a-g del display)
        BANKSEL TRISB
        CLRF TRISB

; RC0..RC3 como salidas (Selección de dígitos)
        BANKSEL TRISC
        BCF TRISC,0
        BCF TRISC,1
        BCF TRISC,2
        BCF TRISC,3

; RE0 como entrada (Pulsador)
        BANKSEL TRISE
        BSF TRISE,0

        BANKSEL PORTC
        CLRF PORTC
        BANKSEL PORTB
        CLRF PORTB

; Inicializar variables de pantalla
        BANKSEL CENT
        CLRF CENT
        CLRF SEG
        CLRF U_CENT
        CLRF D_CENT
        CLRF U_SEG
        CLRF D_SEG
        CLRF DISPLAY

; ==============================================================================
; BUCLE PRINCIPAL
; ==============================================================================
PRINCIPAL:
        CALL MULTIPLEXAR
        GOTO PRINCIPAL

; ==============================================================================
; RUTINA DE MULTIPLEXADO DE PANTALLAS
; ==============================================================================
MULTIPLEXAR:
        BANKSEL PORTC
        CLRF PORTC              ; Apagar todos los dígitos antes de cambiar

        BANKSEL DISPLAY
        MOVF DISPLAY,W
        BTFSC STATUS,Z
        GOTO DISP0

        MOVF DISPLAY,W
        XORLW D'1'
        BTFSC STATUS,Z
        GOTO DISP1

        MOVF DISPLAY,W
        XORLW D'2'
        BTFSC STATUS,Z
        GOTO DISP2

        GOTO DISP3

DISP0:
        BANKSEL D_SEG
        MOVLW HIGH TABLA
        MOVWF PCLATH
        MOVF D_SEG,W
        CALL TABLA
        BANKSEL PORTB
        MOVWF PORTB
        BANKSEL PORTC
        BSF PORTC,0
        GOTO SIG_DISPLAY

DISP1:
        BANKSEL U_SEG
        MOVLW HIGH TABLA
        MOVWF PCLATH
        MOVF U_SEG,W
        CALL TABLA
        BANKSEL PORTB
        MOVWF PORTB
        BANKSEL PORTC
        BSF PORTC,1
        GOTO SIG_DISPLAY

DISP2:
        BANKSEL D_CENT
        MOVLW HIGH TABLA
        MOVWF PCLATH
        MOVF D_CENT,W
        CALL TABLA
        BANKSEL PORTB
        MOVWF PORTB
        BANKSEL PORTC
        BSF PORTC,2
        GOTO SIG_DISPLAY

DISP3:
        BANKSEL U_CENT
        MOVLW HIGH TABLA
        MOVWF PCLATH
        MOVF U_CENT,W
        CALL TABLA
        BANKSEL PORTB
        MOVWF PORTB
        BANKSEL PORTC
        BSF PORTC,3

SIG_DISPLAY:
        BANKSEL DISPLAY
        INCF DISPLAY,F
        MOVLW D'4'
        SUBWF DISPLAY,W
        BTFSC STATUS,Z
        CLRF DISPLAY
        RETURN

; ==============================================================================
; TABLA DE DECODIFICACIÓN 7 SEGMENTOS (Fija en 0x0700)
; ==============================================================================
        ORG 0x0700

TABLA:
        ADDWF PCL,F
        RETLW B'01111110'       ; 0
        RETLW B'00010010'       ; 1
        RETLW B'10111100'       ; 2
        RETLW B'10110110'       ; 3
        RETLW B'11010010'       ; 4
        RETLW B'11100110'       ; 5
        RETLW B'11101110'       ; 6
        RETLW B'00110010'       ; 7
        RETLW B'11111110'       ; 8
        RETLW B'11110110'       ; 9

        END


