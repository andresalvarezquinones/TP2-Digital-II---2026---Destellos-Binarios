LIST P=16F887
        #INCLUDE <P16F887.INC>

        __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
        __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF

;====================================================
; TP5 - TECLADO MATRICIAL Y 4 DISPLAYS
; PIC16F887 - 4 MHz
;
; CONEXIONES:
;
; PORTB: SEGMENTOS
; RB7 = g
; RB6 = f
; RB5 = a
; RB4 = b
; RB3 = e
; RB2 = d
; RB1 = c
; RB0 = PUNTO DECIMAL
;
; RC0-RC3: HABILITACION DISPLAYS (ACTIVO ALTO)
;
; RD0-RD3: COLUMNAS DEL TECLADO
; RD4-RD7: FILAS CON PULL-UP EXTERNO
;
; FUNCIONES:
; # = ENTRAR EN EDICION
; A = CURSOR IZQUIERDA
; B = CURSOR DERECHA
; C = BORRAR
; D = CONFIRMAR
; * = CANCELAR
;====================================================

;====================================================
; VARIABLES DEL PROGRAMA PRINCIPAL
;====================================================

        CBLOCK 0x20

        CONF0
        CONF1
        CONF2
        CONF3

        EDIT0
        EDIT1
        EDIT2
        EDIT3

        MODO
        CURSOR

        TECLA
        TECLA_ANT
        CONT_REBOTE
        ESTADO_TECLA

        CONTADOR_SCAN
        TEMP

        ENDC

;====================================================
; VARIABLES EXCLUSIVAS DE INTERRUPCION
; MEMORIA COMUN 0x70-0x7F
;====================================================

        CBLOCK 0x70

        W_TEMP
        STATUS_TEMP
        PCLATH_TEMP

        POSICION
        ISR_DIGITO
        ISR_PATRON

        ENDC

;====================================================
; VECTORES
;====================================================

        ORG 0x0000
        GOTO INICIO

        ORG 0x0004
        GOTO INTERRUPCION

;====================================================
; INTERRUPCION TIMER0
;====================================================

INTERRUPCION:

        MOVWF W_TEMP

        SWAPF STATUS,W
        MOVWF STATUS_TEMP

        MOVF PCLATH,W
        MOVWF PCLATH_TEMP

        BCF STATUS,RP0
        BCF STATUS,RP1
        CLRF PCLATH

        BTFSS INTCON,T0IF
        GOTO FIN_INTERRUPCION

        BCF INTCON,T0IF

        MOVLW D'131'
        MOVWF TMR0

        CALL MULTIPLEXAR

        ; CONTADOR PARA ESCANEO DEL TECLADO

        MOVLW D'20'
        SUBWF CONTADOR_SCAN,W

        BTFSC STATUS,C
        GOTO FIN_INTERRUPCION

        INCF CONTADOR_SCAN,F

FIN_INTERRUPCION:

        MOVF PCLATH_TEMP,W
        MOVWF PCLATH

        SWAPF STATUS_TEMP,W
        MOVWF STATUS

        SWAPF W_TEMP,F
        SWAPF W_TEMP,W

        RETFIE

;====================================================
; INICIALIZACION
;====================================================

INICIO:

        BANKSEL INTCON
        BCF INTCON,GIE
        BCF INTCON,T0IE

        BANKSEL ANSEL
        CLRF ANSEL
        CLRF ANSELH

        BANKSEL PORTB

        CLRF PORTB
        CLRF PORTC

        MOVLW B'00001111'
        MOVWF PORTD

        BANKSEL TRISB
        CLRF TRISB

        BANKSEL TRISC
        MOVLW B'11110000'
        MOVWF TRISC

        BANKSEL TRISD
        MOVLW B'11110000'
        MOVWF TRISD

        BANKSEL OPTION_REG

        ; TIMER0 PRESCALER 1:4

        MOVLW B'00000001'
        MOVWF OPTION_REG

        BANKSEL CONF0

        CLRF CONF0
        CLRF CONF1
        CLRF CONF2
        CLRF CONF3

        CLRF EDIT0
        CLRF EDIT1
        CLRF EDIT2
        CLRF EDIT3

        CLRF MODO
        CLRF CURSOR

        CLRF CONT_REBOTE
        CLRF ESTADO_TECLA
        CLRF CONTADOR_SCAN

        MOVLW 0xFF
        MOVWF TECLA
        MOVWF TECLA_ANT

        CLRF POSICION

        BANKSEL TMR0

        MOVLW D'131'
        MOVWF TMR0

        BANKSEL INTCON

        BCF INTCON,T0IF
        BSF INTCON,T0IE
        BSF INTCON,GIE

;====================================================
; PROGRAMA PRINCIPAL
;====================================================

PRINCIPAL:

        BANKSEL CONTADOR_SCAN

        MOVLW D'20'
        SUBWF CONTADOR_SCAN,W

        BTFSS STATUS,C
        GOTO PRINCIPAL

        ; REINICIAR CONTADOR SIN INTERRUPCIONES

        BCF INTCON,GIE
        CLRF CONTADOR_SCAN
        BSF INTCON,GIE

        CALL LEER_TECLADO

        CALL ANTIRREBOTE

        GOTO PRINCIPAL

;====================================================
; ANTIRREBOTE
;
; ESTADO_TECLA:
; 0 = ESPERANDO PULSACION
; 1 = ESPERANDO LIBERACION
;
; SE REQUIEREN 4 LECTURAS ESTABLES
;====================================================

ANTIRREBOTE:

        BANKSEL TECLA

        MOVF TECLA,W
        XORWF TECLA_ANT,W

        BTFSC STATUS,Z
        GOTO TECLA_REPETIDA

        ; CAMBIO DETECTADO

        MOVF TECLA,W
        MOVWF TECLA_ANT

        CLRF CONT_REBOTE

        RETURN

TECLA_REPETIDA:

        MOVLW D'4'
        SUBWF CONT_REBOTE,W

        BTFSC STATUS,C
        GOTO TECLA_ESTABLE

        INCF CONT_REBOTE,F

        RETURN

TECLA_ESTABLE:

        ; SI ESPERAMOS LIBERACION

        MOVF ESTADO_TECLA,F

        BTFSS STATUS,Z
        GOTO ESPERAR_LIBERACION

        ; ESTADO 0: ACEPTAR PULSACION

        MOVF TECLA,W
        XORLW 0xFF

        BTFSC STATUS,Z
        RETURN

        MOVLW D'1'
        MOVWF ESTADO_TECLA

        CALL PROCESAR_TECLA

        RETURN

ESPERAR_LIBERACION:

        MOVF TECLA,W
        XORLW 0xFF

        BTFSS STATUS,Z
        RETURN

        CLRF ESTADO_TECLA

        RETURN

;====================================================
; PROCESAMIENTO DE TECLAS
;====================================================

PROCESAR_TECLA:

        BANKSEL TECLA

        ; NUMERAL #

        MOVF TECLA,W
        XORLW D'15'

        BTFSC STATUS,Z
        GOTO ENTRAR_EDICION

        ; SI NO ESTA EN EDICION, IGNORAR

        MOVF MODO,F

        BTFSC STATUS,Z
        RETURN

        ; D = CONFIRMAR

        MOVF TECLA,W
        XORLW D'13'

        BTFSC STATUS,Z
        GOTO CONFIRMAR

        ; * = CANCELAR

        MOVF TECLA,W
        XORLW D'14'

        BTFSC STATUS,Z
        GOTO CANCELAR

        ; A = IZQUIERDA

        MOVF TECLA,W
        XORLW D'10'

        BTFSC STATUS,Z
        GOTO IZQUIERDA

        ; B = DERECHA

        MOVF TECLA,W
        XORLW D'11'

        BTFSC STATUS,Z
        GOTO DERECHA

        ; C = BORRAR

        MOVF TECLA,W
        XORLW D'12'

        BTFSC STATUS,Z
        GOTO BORRAR

        ; NUMEROS 0-9

        MOVLW D'10'
        SUBWF TECLA,W

        BTFSS STATUS,C
        GOTO ESCRIBIR_NUMERO

        RETURN

;====================================================
; ENTRAR EN EDICION
;====================================================

ENTRAR_EDICION:

        MOVF MODO,F

        BTFSS STATUS,Z
        RETURN

        ; COPIAR ULTIMO NUMERO CONFIRMADO

        MOVF CONF0,W
        MOVWF EDIT0

        MOVF CONF1,W
        MOVWF EDIT1

        MOVF CONF2,W
        MOVWF EDIT2

        MOVF CONF3,W
        MOVWF EDIT3

        ; REINICIAR CURSOR AL PRIMER DISPLAY

        CLRF CURSOR

        MOVLW D'1'
        MOVWF MODO

        RETURN

;====================================================
; ESCRIBIR NUMERO
;====================================================

ESCRIBIR_NUMERO:

        MOVF CURSOR,W

        BTFSC STATUS,Z
        GOTO ESCRIBIR0

        MOVF CURSOR,W
        XORLW D'1'

        BTFSC STATUS,Z
        GOTO ESCRIBIR1

        MOVF CURSOR,W
        XORLW D'2'

        BTFSC STATUS,Z
        GOTO ESCRIBIR2

        GOTO ESCRIBIR3

ESCRIBIR0:

        MOVF TECLA,W
        MOVWF EDIT0

        GOTO AVANZAR_CURSOR

ESCRIBIR1:

        MOVF TECLA,W
        MOVWF EDIT1

        GOTO AVANZAR_CURSOR

ESCRIBIR2:

        MOVF TECLA,W
        MOVWF EDIT2

        GOTO AVANZAR_CURSOR

ESCRIBIR3:

        MOVF TECLA,W
        MOVWF EDIT3

AVANZAR_CURSOR:

        MOVLW D'3'
        SUBWF CURSOR,W

        BTFSS STATUS,C
        INCF CURSOR,F

        RETURN

;====================================================
; CURSOR IZQUIERDA
;====================================================

IZQUIERDA:

        MOVF CURSOR,F

        BTFSC STATUS,Z
        RETURN

        DECF CURSOR,F

        RETURN

;====================================================
; CURSOR DERECHA
;====================================================

DERECHA:

        MOVLW D'3'
        SUBWF CURSOR,W

        BTFSC STATUS,C
        RETURN

        INCF CURSOR,F

        RETURN

;====================================================
; BORRAR
;====================================================

BORRAR:

        CLRF EDIT0
        CLRF EDIT1
        CLRF EDIT2
        CLRF EDIT3

        CLRF CURSOR

        RETURN

;====================================================
; CONFIRMAR
;====================================================

CONFIRMAR:

        MOVF EDIT0,W
        MOVWF CONF0

        MOVF EDIT1,W
        MOVWF CONF1

        MOVF EDIT2,W
        MOVWF CONF2

        MOVF EDIT3,W
        MOVWF CONF3

        CLRF MODO

        RETURN

;====================================================
; CANCELAR
;====================================================

CANCELAR:

        CLRF MODO

        RETURN

;====================================================
; LECTURA DEL TECLADO MATRICIAL
;====================================================

LEER_TECLADO:

        BANKSEL TECLA

        MOVLW 0xFF
        MOVWF TECLA

;---------------------------
; COLUMNA RD0
;---------------------------

        BANKSEL PORTD

        MOVLW B'00001110'
        MOVWF PORTD

        CALL ESPERA_TECLADO

        BTFSS PORTD,4
        GOTO T1

        BTFSS PORTD,5
        GOTO T4

        BTFSS PORTD,6
        GOTO T7

        BTFSS PORTD,7
        GOTO TASTERISCO

;---------------------------
; COLUMNA RD1
;---------------------------

        MOVLW B'00001101'
        MOVWF PORTD

        CALL ESPERA_TECLADO

        BTFSS PORTD,4
        GOTO T2

        BTFSS PORTD,5
        GOTO T5

        BTFSS PORTD,6
        GOTO T8

        BTFSS PORTD,7
        GOTO T0

;---------------------------
; COLUMNA RD2
;---------------------------

        MOVLW B'00001011'
        MOVWF PORTD

        CALL ESPERA_TECLADO

        BTFSS PORTD,4
        GOTO T3

        BTFSS PORTD,5
        GOTO T6

        BTFSS PORTD,6
        GOTO T9

        BTFSS PORTD,7
        GOTO TNUMERAL

;---------------------------
; COLUMNA RD3
;---------------------------

        MOVLW B'00000111'
        MOVWF PORTD

        CALL ESPERA_TECLADO

        BTFSS PORTD,4
        GOTO TA

        BTFSS PORTD,5
        GOTO TB

        BTFSS PORTD,6
        GOTO TC

        BTFSS PORTD,7
        GOTO TD

        GOTO FIN_TECLADO

;====================================================
; CODIGOS DE TECLAS
;====================================================

T0:
        MOVLW D'0'
        GOTO GUARDAR_TECLA

T1:
        MOVLW D'1'
        GOTO GUARDAR_TECLA

T2:
        MOVLW D'2'
        GOTO GUARDAR_TECLA

T3:
        MOVLW D'3'
        GOTO GUARDAR_TECLA

T4:
        MOVLW D'4'
        GOTO GUARDAR_TECLA

T5:
        MOVLW D'5'
        GOTO GUARDAR_TECLA

T6:
        MOVLW D'6'
        GOTO GUARDAR_TECLA

T7:
        MOVLW D'7'
        GOTO GUARDAR_TECLA

T8:
        MOVLW D'8'
        GOTO GUARDAR_TECLA

T9:
        MOVLW D'9'
        GOTO GUARDAR_TECLA

TA:
        MOVLW D'10'
        GOTO GUARDAR_TECLA

TB:
        MOVLW D'11'
        GOTO GUARDAR_TECLA

TC:
        MOVLW D'12'
        GOTO GUARDAR_TECLA

TD:
        MOVLW D'13'
        GOTO GUARDAR_TECLA

TASTERISCO:
        MOVLW D'14'
        GOTO GUARDAR_TECLA

TNUMERAL:
        MOVLW D'15'

GUARDAR_TECLA:

        BANKSEL TECLA
        MOVWF TECLA

FIN_TECLADO:

        BANKSEL PORTD

        MOVLW B'00001111'
        MOVWF PORTD

        RETURN

;====================================================
; PEQUEÑA ESPERA DEL TECLADO
;====================================================

ESPERA_TECLADO:

        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP

        RETURN

;====================================================
; MULTIPLEXADO
;====================================================

MULTIPLEXAR:

        BANKSEL PORTC

        ; APAGAR LOS CUATRO DISPLAYS

        CLRF PORTC

        BANKSEL POSICION

        ; DETERMINAR SI MOSTRAMOS EDIT O CONF

        MOVF MODO,F

        BTFSC STATUS,Z
        GOTO MOSTRAR_CONFIRMADO

;---------------------------
; MODO EDICION
;---------------------------

MOSTRAR_EDITADO:

        MOVF POSICION,W

        BTFSC STATUS,Z
        GOTO EDIT_POS0

        MOVF POSICION,W
        XORLW D'1'

        BTFSC STATUS,Z
        GOTO EDIT_POS1

        MOVF POSICION,W
        XORLW D'2'

        BTFSC STATUS,Z
        GOTO EDIT_POS2

        MOVF EDIT3,W
        GOTO CONVERTIR_DISPLAY

EDIT_POS0:

        MOVF EDIT0,W
        GOTO CONVERTIR_DISPLAY

EDIT_POS1:

        MOVF EDIT1,W
        GOTO CONVERTIR_DISPLAY

EDIT_POS2:

        MOVF EDIT2,W
        GOTO CONVERTIR_DISPLAY

;---------------------------
; MODO VISUALIZACION
;---------------------------

MOSTRAR_CONFIRMADO:

        MOVF POSICION,W

        BTFSC STATUS,Z
        GOTO CONF_POS0

        MOVF POSICION,W
        XORLW D'1'

        BTFSC STATUS,Z
        GOTO CONF_POS1

        MOVF POSICION,W
        XORLW D'2'

        BTFSC STATUS,Z
        GOTO CONF_POS2

        MOVF CONF3,W
        GOTO CONVERTIR_DISPLAY

CONF_POS0:

        MOVF CONF0,W
        GOTO CONVERTIR_DISPLAY

CONF_POS1:

        MOVF CONF1,W
        GOTO CONVERTIR_DISPLAY

CONF_POS2:

        MOVF CONF2,W

;---------------------------
; CONVERTIR A SEGMENTOS
;---------------------------

CONVERTIR_DISPLAY:

        MOVWF ISR_DIGITO

        MOVLW HIGH TABLA
        MOVWF PCLATH

        MOVF ISR_DIGITO,W
        CALL TABLA

        CLRF PCLATH

        MOVWF ISR_PATRON

;---------------------------
; PUNTO DECIMAL
;---------------------------

        MOVF MODO,F

        BTFSC STATUS,Z
        GOTO MOSTRAR_SEGMENTOS

        MOVF POSICION,W
        XORWF CURSOR,W

        BTFSC STATUS,Z
        BSF ISR_PATRON,0

;---------------------------
; MOSTRAR SEGMENTOS
;---------------------------

MOSTRAR_SEGMENTOS:

        MOVF ISR_PATRON,W

        BANKSEL PORTB
        MOVWF PORTB

        BANKSEL POSICION

        MOVF POSICION,W

        BTFSC STATUS,Z
        GOTO ENCENDER0

        MOVF POSICION,W
        XORLW D'1'

        BTFSC STATUS,Z
        GOTO ENCENDER1

        MOVF POSICION,W
        XORLW D'2'

        BTFSC STATUS,Z
        GOTO ENCENDER2

        GOTO ENCENDER3

ENCENDER0:

        BANKSEL PORTC
        BSF PORTC,0

        GOTO SIGUIENTE_DISPLAY

ENCENDER1:

        BANKSEL PORTC
        BSF PORTC,1

        GOTO SIGUIENTE_DISPLAY

ENCENDER2:

        BANKSEL PORTC
        BSF PORTC,2

        GOTO SIGUIENTE_DISPLAY

ENCENDER3:

        BANKSEL PORTC
        BSF PORTC,3

;---------------------------
; SIGUIENTE DISPLAY
;---------------------------

SIGUIENTE_DISPLAY:

        BANKSEL POSICION

        INCF POSICION,F

        MOVLW D'4'
        SUBWF POSICION,W

        BTFSC STATUS,Z
        CLRF POSICION

        RETURN

;====================================================
; TABLA DE 7 SEGMENTOS
;====================================================

        ORG 0x0700

TABLA:

        ADDWF PCL,F

        RETLW B'01111110' ; 0
        RETLW B'00010010' ; 1
        RETLW B'10111100' ; 2
        RETLW B'10110110' ; 3
        RETLW B'11010010' ; 4
        RETLW B'11100110' ; 5
        RETLW B'11101110' ; 6
        RETLW B'00110010' ; 7
        RETLW B'11111110' ; 8
        RETLW B'11110110' ; 9

        END
