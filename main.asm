.include "m328Pdef.inc"   ; Используем ATMega16

.def tmpI = R20
.def delay = R21
.def adc_res = R22

; RAM ========================================================
			.DSEG


; FLASH ======================================================
			.CSEG
			.ORG	0x0000       ; (RESET) 
			JMP		Reset
			.ORG	0x0002		 ; (INT0)
			JMP		EXT_INT0
			.ORG	0x0004
			JMP		EXT_INT1
			.ORG	0x000C		 ; (watchdog timer)
			JMP		Watchdog 
			.ORG	ADCCaddr	 ; (ADC)
			JMP		ADC_conversion
	 		.ORG	INT_VECTORS_SIZE      	; Конец таблицы прерываний

; Interrupts ==============================================
EXT_INT0:	CLI
			
			CPI		delay, 7
			BREQ	EXT_INT0_Vix
			INC		delay
			CALL	WDT_init
EXT_INT0_Vix:

			SEI
			RETI	
;---
EXT_INT1:
			CLI

			CPI		delay, 0
			BREQ	EXT_INT1_Vix
			DEC		delay
			CALL	WDT_init

EXT_INT1_Vix:

			SEI
			RETI
;---
ADC_conversion:
			CLI

			LDS adc_res, ADCL ;use for random
			LDS R23, ADCH 
			
			SEI
			RETI
;---
Watchdog:
			CLI

			;start adc
			LDS		tmpI, ADMUX
			ORI		tmpI, 1 << REFS0 | 0 << ADLAR | 1 << MUX2; выставляю AVCC with external capacitor at AREF pin. Также 4 канал.
			STS		ADMUX, tmpI
			LDS		tmpI, ADCSRA
			ORI		tmpI, 1 << ADEN | 1 << ADSC | 1 << ADIF | 1 << ADIE | 1 << ADPS2 | 1 << ADPS1 ; включаю и настраиваю
			STS		ADCSRA, tmpI

			SEI
			RETI
;---

; End Interrupts ==========================================


Reset:   	;Инициализация стека
			LDI 	R16,Low(RAMEND)	
		    OUT 	SPL,R16			
			
		 	LDI 	R16,High(RAMEND)
		 	OUT 	SPH,R16
			;---
			;Настройка прерывания по INT0 (pin2, pin3)
			LDI		R16, 1 << ISC01 | 1 << ISC00 | 1 << ISC11 | 1 << ISC10	;The rising edge of INT0 generates an interrupt request
			STS		EICRA, R16
	
			LDI		R16, 1 << INT0 | 1 << INT1
			OUT		EIMSK, R16
			;---
			;Настройка ADC
			LDS		R16, ADMUX
			ORI		R16, 1 << REFS0 ; Выставляю AVCC with external capacitor at AREF pin. Также 0 канал.  ????? 0 или 1???? что лучше
			STS		ADMUX, R16
			LDS		R16, ADCSRA
			ORI		R16, 1 << ADEN | 1 << ADSC | 1 << ADIF | 1 << ADIE | 1 << ADPS2 | 1 << ADPS1 ; включаю и настраиваю
			STS		ADCSRA, R16
			;---


			
			LDI		delay, 0

			RCALL	WDT_init ;start WDT

			SEI

; Internal Hardware Init  ======================================

; End Internal Hardware Init ===================================



; External Hardware Init  ======================================

; End Internal Hardware Init ===================================



; Run ==========================================================

; End Run ======================================================



; Main =========================================================
Main:
			LDI		R16, 0b00011111
			OUT		DDRB, R16
			OUT		PORTB, adc_res
			

			JMP		Main
; End Main =====================================================


; Procedure ====================================================
WDT_init:
		CLI

		CPI		delay, 0
		BREQ	WDT0064
		CPI		delay, 1
		BREQ	WDT0125
		CPI		delay, 2
		BREQ	WDT0250
		CPI		delay, 3
		BREQ	WDT0500
		CPI		delay, 4
		BREQ	WDT1000
		CPI		delay, 5
		BREQ	WDT2000
		CPI		delay, 6
		BREQ	WDT4000
		CPI		delay, 7
		BREQ	WDT8000

WDT0064:
		LDI		R18, (0 << WDP3) | (0 << WDP2) | (1 << WDP1) | (0 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT0125:
		LDI		R18, (0 << WDP3) | (0 << WDP2) | (1 << WDP1) | (1 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT0250:
		LDI		R18, (0 << WDP3) | (1 << WDP2) | (0 << WDP1) | (0 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT0500:
		LDI		R18, (0 << WDP3) | (1 << WDP2) | (0 << WDP1) | (1 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT1000:
		LDI		R18, (0 << WDP3) | (1 << WDP2) | (1 << WDP1) | (0 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT2000:
		LDI		R18, (0 << WDP3) | (1 << WDP2) | (1 << WDP1) | (1 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT4000:
		LDI		R18, (1 << WDP3) | (0 << WDP2) | (0 << WDP1) | (0 << WDP0) | (1 << WDIE)
		RJMP	Vix
WDT8000:
		LDI		R18, (1 << WDP3) | (0 << WDP2) | (0 << WDP1) | (1 << WDP0) | (1 << WDIE)
		RJMP	Vix
Vix:
		WDR	
		; Start timed sequence
		LDS		R16, WDTCSR
		ORI		R16, (1 << WDCE) | (1 << WDE) ; change prescaler mode enable
		STS		WDTCSR, R16
		STS		WDTCSR, R18

		SEI
		RET
; End Procedure ================================================


; EEPROM =====================================================
			.ESEG				; Сегмент EEPROM
