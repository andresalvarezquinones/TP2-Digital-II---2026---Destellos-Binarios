LIST P=16F887
        #INCLUDE <P16F887.INC>
        __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON & _CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF & _LVP_OFF
        __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
        CBLOCK 0x20
        CONTADOR
        TIEMPO
        D1
        D2
        D3
        EFECTO
        DIRECCION
        REP
        ENDC
        ORG 0x0000
        GOTO INICIO
        ORG 0x0005
INICIO:
        ; Todo digital
        BANKSEL ANSEL
        CLRF ANSEL
        CLRF ANSELH
        ; PORTD salida para los LEDs
        BANKSEL TRISD
        CLRF TRISD
        ; RE0 unico boton
        BANKSEL TRISE
        BSF TRISE,0
        ; Contador inicia en 0
        BANKSEL CONTADOR
        CLRF CONTADOR
        ; LEDs apagados
        BANKSEL PORTD
        CLRF PORTD
; =========================================
; MODO CONTADOR
; =========================================
CONTADOR_MODO:
        ; Mostrar contador
        BANKSEL CONTADOR
        MOVF CONTADOR,W
        BANKSEL PORTD
        MOVWF PORTD
; Esperar que se presione RE0
ESPERAR_PRESION:
        BANKSEL PORTE
        BTFSC PORTE,0
        GOTO ESPERAR_PRESION
        ; Antirrebote
        CALL DEMORA_50MS
        BANKSEL PORTE
        BTFSC PORTE,0
        GOTO ESPERAR_PRESION
        ; Empezar a medir cuanto dura la pulsacion
        BANKSEL TIEMPO
        CLRF TIEMPO
; =========================================
; MEDIR PULSACION
; =========================================
MEDIR:
        CALL DEMORA_50MS
        BANKSEL TIEMPO
        INCF TIEMPO,F
        ; 20 x 50 ms = aproximadamente 1 segundo
        MOVLW D'20'
        SUBWF TIEMPO,W
        BTFSC STATUS,Z
        GOTO MODO_SECUENCIA
        ; Ver si sigue apretado
        BANKSEL PORTE
        BTFSS PORTE,0
        GOTO MEDIR
        ; Si solto antes de 1 segundo fue toque corto
        CALL DEMORA_50MS
        BANKSEL CONTADOR
        INCF CONTADOR,F
        ; Si pasa de 255 vuelve a 1
        MOVF CONTADOR,F
        BTFSS STATUS,Z
        GOTO CONTADOR_MODO
        MOVLW D'1'
        MOVWF CONTADOR
        GOTO CONTADOR_MODO
; =========================================
; MODO SECUENCIA
; =========================================
MODO_SECUENCIA:
        ; Esperar que suelte RE0
ESPERAR_SUELTA:
        BANKSEL PORTE
        BTFSS PORTE,0
        GOTO ESPERAR_SUELTA
        CALL DEMORA_50MS
; Hacer RUNNING 3 veces
        BANKSEL REP
        MOVLW D'3'
        MOVWF REP
RUN3:
        CALL RUNNING
        BTFSC STATUS,C
        GOTO SALIR_SECUENCIA
        BANKSEL REP
        DECFSZ REP,F
        GOTO RUN3
; Hacer BRUNNING 3 veces
        MOVLW D'3'
        MOVWF REP
BRUN3:
        CALL BRUNNING
        BTFSC STATUS,C
        GOTO SALIR_SECUENCIA
        BANKSEL REP
        DECFSZ REP,F
        GOTO BRUN3
; Hacer CRAWLING 3 veces
        MOVLW D'3'
        MOVWF REP
CRAW3:
        CALL CRAWLING
        BTFSC STATUS,C
        GOTO SALIR_SECUENCIA
        BANKSEL REP
        DECFSZ REP,F
        GOTO CRAW3
        ; Repetir secuencias continuamente
        GOTO MODO_SECUENCIA
; =========================================
; RUNNING
; Un LED recorre de un lado al otro
; =========================================
RUNNING:
        BCF STATUS,C
        BANKSEL EFECTO
        MOVLW B'00000001'
        MOVWF EFECTO
RUN_LOOP:
        MOVF EFECTO,W
        BANKSEL PORTD
        MOVWF PORTD
        CALL DEMORA_200MS
        CALL REVISAR_BOTON
        BTFSC STATUS,C
        RETURN
        BCF STATUS,C
        BANKSEL EFECTO
        RLF EFECTO,F
        BTFSS STATUS,C
        GOTO RUN_LOOP
        BCF STATUS,C
        RETURN
; =========================================
; BRUNNING
; LED va y vuelve
; =========================================
BRUNNING:
        BCF STATUS,C
        BANKSEL EFECTO
        MOVLW B'00000001'
        MOVWF EFECTO
        CLRF DIRECCION
BRUN_LOOP:
        MOVF EFECTO,W
        BANKSEL PORTD
        MOVWF PORTD
        CALL DEMORA_200MS
        CALL REVISAR_BOTON
        BTFSC STATUS,C
        RETURN
        BANKSEL DIRECCION
        BTFSC DIRECCION,0
        GOTO DERECHA
        BCF STATUS,C
        BANKSEL EFECTO
        RLF EFECTO,F
        BTFSS STATUS,C
        GOTO BRUN_LOOP
        MOVLW B'01000000'
        MOVWF EFECTO
        BANKSEL DIRECCION
        COMF DIRECCION,F
        GOTO BRUN_LOOP
DERECHA:
        BCF STATUS,C
        BANKSEL EFECTO
        RRF EFECTO,F
        BTFSS STATUS,C
        GOTO BRUN_LOOP
        BCF STATUS,C
        RETURN
; =========================================
; CRAWLING
; Enciende y apaga progresivamente
; =========================================
CRAWLING:
        BCF STATUS,C
        BANKSEL EFECTO
        CLRF EFECTO
ENCENDER:
        BCF STATUS,C
        RLF EFECTO,F
        BSF EFECTO,0
        MOVF EFECTO,W
        BANKSEL PORTD
        MOVWF PORTD
        CALL DEMORA_100MS
        CALL REVISAR_BOTON
        BTFSC STATUS,C
        RETURN
        BANKSEL EFECTO
        MOVF EFECTO,W
        XORLW 0xFF
        BTFSS STATUS,Z
        GOTO ENCENDER
APAGAR:
        BCF STATUS,C
        BANKSEL EFECTO
        RRF EFECTO,F
        MOVF EFECTO,W
        BANKSEL PORTD
        MOVWF PORTD
        CALL DEMORA_100MS
        CALL REVISAR_BOTON
        BTFSC STATUS,C
        RETURN
        BANKSEL EFECTO
        MOVF EFECTO,W
        BTFSS STATUS,Z
        GOTO APAGAR
        BCF STATUS,C
        RETURN
; =========================================
; REVISAR BOTON DURANTE SECUENCIA
; C=1 si se presiono RE0
; =========================================
REVISAR_BOTON:
        BANKSEL PORTE
        BTFSC PORTE,0
        GOTO NO_PRESION
        CALL DEMORA_50MS
        BANKSEL PORTE
        BTFSC PORTE,0
        GOTO NO_PRESION
        BSF STATUS,C
        RETURN
NO_PRESION:
        BCF STATUS,C
        RETURN
; =========================================
; SALIR DE SECUENCIA
; =========================================
SALIR_SECUENCIA:
        ; Esperar que suelte RE0
        BANKSEL PORTE
        BTFSS PORTE,0
        GOTO SALIR_SECUENCIA
        CALL DEMORA_50MS
        ; Volver a mostrar contador
        BANKSEL CONTADOR
        MOVF CONTADOR,W
        BANKSEL PORTD
        MOVWF PORTD
        GOTO CONTADOR_MODO
; =========================================
; DEMORA 50 ms
; =========================================
DEMORA_50MS:
        BANKSEL D1
        MOVLW D'100'
        MOVWF D1
D50_1:
        MOVLW D'166'
        MOVWF D2
D50_2:
        DECFSZ D2,F
        GOTO D50_2
        DECFSZ D1,F
        GOTO D50_1
        RETURN
; =========================================
; DEMORA 200 ms
; =========================================
DEMORA_200MS:
        BANKSEL D1
        MOVLW D'255'
        MOVWF D1
D200_1:
        MOVLW D'255'
        MOVWF D2
D200_2:
        DECFSZ D2,F
        GOTO D200_2
        DECFSZ D1,F
        GOTO D200_1
        RETURN
; =========================================
; DEMORA 100 ms
; =========================================
DEMORA_100MS:
        BANKSEL D1
        MOVLW D'250'
        MOVWF D1
D100_1:
        MOVLW D'16'
        MOVWF D2
D100_2:
        MOVLW D'7'
        MOVWF D3
D100_3:
        DECFSZ D3,F
        GOTO D100_3
        DECFSZ D2,F
        GOTO D100_2
        DECFSZ D1,F
        GOTO D100_1
        RETURN
        END