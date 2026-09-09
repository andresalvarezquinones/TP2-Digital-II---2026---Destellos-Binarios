LIST P=16F887
2 #INCLUDE <P16F887.INC>
3 ; Configuracion del PIC
4 __CONFIG _CONFIG1, _FOSC_XT & _WDTE_OFF & _PWRTE_ON & _MCLRE_ON &
_CP_OFF & _CPD_OFF & _BOREN_OFF & _IESO_OFF & _FCMEN_OFF &
_LVP_OFF
5 __CONFIG _CONFIG2, _BOR4V_BOR21V & _WRT_OFF
6 ; Variables utilizadas
7 CBLOCK 0x20
8 CONTADOR ; Guarda el numero de 0 a 99
9 UNIDADES ; Guarda las unidades
10 DECENAS ; Guarda las decenas
11 AUX ; Variable auxiliar para la conversion
12 D1 ; Contador para demora
13 D2 ; Contador para demora
14 REB ; Contador para antirrebote
15 ENDC
16 ; Vector de reset
17 ORG 0x0000
18 GOTO INICIO
19 ORG 0x0005
20 INICIO:
21 ; Configurar entradas como digitales
22 BANKSEL ANSEL
23 CLRF ANSEL
24 CLRF ANSELH
25 ; PORTB como salida para los segmentos
26 BANKSEL TRISB
27 CLRF TRISB
28 ; RC0 y RC1 como salidas para seleccionar los displays
29 BANKSEL TRISC
30 BCF TRISC,0 ; RC0 = unidades
31 BCF TRISC,1 ; RC1 = decenas
32 ; PORTD como salida para los 8 LEDs
33 BANKSEL TRISD
34 CLRF TRISD
35 ; RE0 como entrada para el boton
36 BANKSEL TRISE
37 BSF TRISE,0
38 ; Comenzar con ambos displays desactivados
39 BANKSEL PORTC
40 BSF PORTC,0
41 BSF PORTC,1
42 ; Apagar los segmentos
43 BANKSEL PORTB
44 CLRF PORTB
45 ; Apagar los LEDs
46 BANKSEL PORTD
47 CLRF PORTD
48 ; Inicializar contador, unidades y decenas en cero
49 BANKSEL CONTADOR
50 CLRF CONTADOR
51 CLRF UNIDADES
52 CLRF DECENAS
53 ; =========================================
54 ; PROGRAMA PRINCIPAL ; Refresca displays y controla el boton
55 ; =========================================
56 PRINCIPAL:
57 CALL DISPLAYS ; Mostrar continuamente los dos numeros
58 BANKSEL PORTE
59 BTFSC PORTE,0 ; Preguntar si RE0 esta en 0
60 GOTO PRINCIPAL ; Si no se presiono, seguir esperando
61 CALL ANTIRREBOTE ; Evitar rebotes del pulsador
62 BANKSEL PORTE
63 BTFSC PORTE,0 ; Comprobar nuevamente el boton
64 GOTO PRINCIPAL ; Si fue un rebote, volver
65 CALL SUMAR ; Si sigue presionado, sumar uno
66 ; =========================================
67 ; ESPERAR A QUE SE SUELTE EL BOTON ; Evita contar repetida una pulsacion
68 ; =========================================
69 ESPERAR_SUELTA:
70 CALL DISPLAYS ; Seguir mostrando mientras se mantiene
pulsado
71 BANKSEL PORTE
72 BTFSS PORTE,0 ; Preguntar si RE0 volvio a 1
73 GOTO ESPERAR_SUELTA ; Si sigue apretado, esperar
74 CALL ANTIRREBOTE ; Comprobar que realmente se solto
75 BANKSEL PORTE
76 BTFSS PORTE,0
77 GOTO ESPERAR_SUELTA
78 GOTO PRINCIPAL ; Volver a esperar otra pulsacion
79 ; =========================================
80 ; INCREMENTAR CONTADOR ; Cuenta desde 00 hasta 99
81 ; =========================================
82 SUMAR:
83 BANKSEL CONTADOR
84 INCF CONTADOR,F ; CONTADOR = CONTADOR + 1
85 MOVLW D?100? ; Cargar 100 en W
86 SUBWF CONTADOR,W ; Comparar CONTADOR con 100
87 BTFSS STATUS,Z ; Si no llego a 100, continuar
88 GOTO MOSTRAR_BIN
89 CLRF CONTADOR ; Si llego a 100, volver a 00
90 ; =========================================
91 ; MOSTRAR VALOR BINARIO EN PORTD
92 ; =========================================
93 MOSTRAR_BIN:
94 MOVF CONTADOR,W ; Pasar contador a W
95 BANKSEL PORTD
96 MOVWF PORTD ; Mostrarlo en los 8 LEDs
97 CALL CONVERTIR ; Separar el numero en decenas y unidades
98 RETURN
99 ; =========================================
100 ; CONVERSION DECIMAL ; Separa CONTADOR en DECENAS y UNIDADES
101 ; =========================================
102 CONVERTIR:
103 BANKSEL CONTADOR
104 MOVF CONTADOR,W ; Copiar contador
105 MOVWF AUX ; Guardarlo en AUX
106 CLRF DECENAS ; Empezar decenas desde cero
107 CONV:
108 MOVLW D?10? ; Cargar 10
109 SUBWF AUX,W ; Comparar AUX con 10
110 BTFSS STATUS,C ; Si AUX es menor que 10, terminar
111 GOTO FIN_CONV
112 MOVLW D?10?
113 SUBWF AUX,F ; AUX = AUX-10
114 INCF DECENAS,F ; Sumar una decena
115 GOTO CONV ; Repetir
116 FIN_CONV:
117 MOVF AUX,W ; Lo que queda es la unidad
118 MOVWF UNIDADES
119 RETURN
120 ; =========================================
121 ; MULTIPLEXADO DE LOS DOS DISPLAYS ; RC0 = unidades ; RC1 = decenas
122 ; =========================================
123 DISPLAYS:
124 ; Desactivar los dos displays
125 BANKSEL PORTC
126 BSF PORTC,0
127 BSF PORTC,1
128 ; Buscar patron de las unidades
129 BANKSEL UNIDADES
130 MOVF UNIDADES,W
131 CALL TABLA
132 ; Mandar patron de segmentos a PORTB
133 BANKSEL PORTB
134 MOVWF PORTB
135 ; Encender display de unidades
136 BANKSEL PORTC
137 BCF PORTC,0
138 CALL DEMORA_MUX ; Mantenerlo encendido un instante
139 ; Apagar nuevamente los displays
140 BANKSEL PORTC
141 BSF PORTC,0
142 BSF PORTC,1
143 ; Buscar patron de las decenas
144 BANKSEL DECENAS
145 MOVF DECENAS,W
146 CALL TABLA
147 ; Mandar patron de segmentos a PORTB
148 BANKSEL PORTB
149 MOVWF PORTB
150 ; Encender display de decenas
151 BANKSEL PORTC
152 BCF PORTC,1
153 CALL DEMORA_MUX ; Mantenerlo encendido un instante
154 ; Apagar ambos antes de salir
155 BANKSEL PORTC
156 BSF PORTC,0
157 BSF PORTC,1
158 RETURN
159 ; =========================================
160 ; TABLA PARA LOS DISPLAYS DE 7 SEGMENTOS
161 ; Conexion utilizada:
162 ; RB7 = g ; RB6 = f ; RB5 = a ; RB4 = b ; RB3 = e
163 ; RB2 = d ; RB1 = c ; RB0 = punto decimal
164 ; =========================================
165 TABLA:
166 ADDWF PCL,F ; Saltar al patron correspondiente
167 RETLW B?01111110? ; Numero 0
168 RETLW B?00010010? ; Numero 1
169 RETLW B?10111100? ; Numero 2
170 RETLW B?10110110? ; Numero 3
171 RETLW B?11010010? ; Numero 4
172 RETLW B?11100110? ; Numero 5
173 RETLW B?11101110? ; Numero 6
174 RETLW B?00110010? ; Numero 7
175 RETLW B?11111110? ; Numero 8
176 RETLW B?11110110? ; Numero 9
177 ; =========================================
178 ; DEMORA DEL MULTIPLEXADO ; Cada display permanece encendido antes de
cambiar al otro
179 ; =========================================
180 DEMORA_MUX:
181 BANKSEL D1
182 MOVLW D?2?
183 MOVWF D1
184 MUX1:
185 MOVLW D?250?
186 MOVWF D2
187 MUX2:
188 DECFSZ D2,F ; Restar uno a D2
189 GOTO MUX2 ; Repetir hasta llegar a cero
190 DECFSZ D1,F ; Restar uno a D1
191 GOTO MUX1
192 RETURN
193 ; =========================================
194 ; ANTIRREBOTE DEL BOTON ; Es corto para que el cambio de numero sea rapido
195 ; Mientras espera sigue refrescando los displays
196 ; =========================================
197 ANTIRREBOTE:
198 BANKSEL REB
199 MOVLW D?2? ; Hacer solamente 2 refrescos
200 MOVWF REB
201 REBOTE_LOOP:
202 CALL DISPLAYS ; Mantener displays refrescandose
203 BANKSEL REB
204 DECFSZ REB,F ; Restar uno al contador de antirrebote
205 GOTO REBOTE_LOOP
206 RETURN
207 END


