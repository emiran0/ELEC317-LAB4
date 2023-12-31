/*
 * Lab4_ADC.asm
 *	;;;;TASK 2;;;;;;
 *	CLK ==> 4MHz, to stop sudden jumps.
 *	476 Byte
 *  8 registers
 *	each index of the data table is for the time index from T0
 *	which equals to the result (potentiometer).
 */ 

;***** Constants
.equ	preset=130			;T/C0 Preset constant (256-64)
.equ num9= 0x6F
.equ num8= 0x7F
.equ num7= 0x07
.equ num6= 0x7D
.equ num5= 0x6D
.equ num4= 0x66
.equ num3= 0x4F
.equ num2= 0x5B
.equ num1= 0x06
.equ num0= 0x3F	
;***** A/D converter Global Registers
.def	result=r16			;Result and intermediate data
.def	temp=r17			;Scratch register
.def	sevsegDigit = r18
.def	levelCounter = r19
.def	temp2=r20
.def	temp3=r21
.def	temp4 = r22
.def	hunderedNum = r23

;***********************************************************;
;*  	PROGRAM START - EXECUTION STARTS HERE			   *;	
;***********************************************************;
.cseg
.org $0000
jmp RESET      ;Reset handle
.org OVF0addr
jmp ANA_COMP   ;Timer0 overflow handle
.org ACIaddr
jmp ANA_COMP   ;Analog comparator handle

RESET:
	ldi 	TEMP, low(RAMEND)	; initialize stack pointer
	out		SPL, TEMP
	ldi 	TEMP, high(RAMEND)
	out 	SPH, TEMP
	rcall	convert_init		;Initialize A/D converter
	ldi		result,$ff			;set port D as output
	out		DDRC,result			;for LED?s
	sei							;Enable global interrupt
Delay:	
	clr		temp2			;Clear temp counter 1
	ldi		temp3,$f0		;Reset temp counter 2
loop1:	
	inc		temp2			;Count up temp counter 1
	brne	loop1			;Check if inner loop is finished
	inc 	temp3			;Count up temp counter 2
	brne 	loop1			;Check if delay is finished
	rcall	AD_convert		;Start conversion

Wait:
	brtc	Wait			;Wait until conversion is complete (T flag set)
	mov		sevsegDigit, result
	rcall	getExp
	rcall	seperateDigits
	rcall	hunderedDigit
	rcall	Delay2
	rcall	tenDigit
	rcall	Delay2
	rcall	digitSelect		;Write result on port C
	rcall	Delay2
	clr		levelCounter
	clr		hunderedNum
	rjmp	Delay			;Repeat conversion

getExp:
	push	XL
	push	XH
	push	result

	ldi		ZL, low(expLookup * 2)
	ldi		ZH, high(expLookup * 2)
	add		ZL, sevsegDigit
	clr		result
	adc		ZH, result
	lpm		sevsegDigit, Z

	pop		result
	pop		XH
	pop		XL

Delay2:	ldi temp3, $00
	ldi temp4, $03
Wait1:	subi temp3, 1
	sbci temp4, 0
	brcc Wait1
	ret

seperateDigits:
	cpi		sevsegDigit, 0x64
	brsh	countHundereds
	cpi		sevsegDigit, 0x0A
	brsh	countTens
	ret

countHundereds:
	subi	sevsegDigit, 0x64
	inc		hunderedNum
	cpi		sevsegDigit, 0x64
	brlo	seperateDigits
	ret

countTens:
	subi	sevsegDigit, 0x0A
	inc		levelCounter
	cpi		sevsegDigit, 0x0A
	brsh	seperateDigits
	ret	 

digitSelect:
	ldi		temp, (1<<0)
	out		PORTA, temp
	cpi		sevsegDigit, 0x09
	breq	go_nine
	cpi		sevsegDigit, 0x08
	breq	go_eight
	cpi		sevsegDigit, 0x07
	breq	go_seven
	cpi		sevsegDigit, 0x06
	breq	go_six
	cpi		sevsegDigit, 0x05
	breq	go_five
	cpi		sevsegDigit, 0x04
	breq	go_four
	cpi		sevsegDigit, 0x03
	breq	go_three
	cpi		sevsegDigit, 0x02
	breq	go_two
	cpi		sevsegDigit, 0x01
	breq	go_one
	cpi		sevsegDigit, 0x00
	breq	go_zero
	ret

go_nine:
	ldi		temp3, num9
	out		PORTC, temp3
	ret
go_eight:
	ldi		temp3, num8
	out		PORTC, temp3
	ret
go_seven:
	ldi		temp3, num7
	out		PORTC, temp3
	ret
go_six:
	ldi		temp3, num6
	out		PORTC, temp3
	ret
go_five:
	ldi		temp3, num5
	out		PORTC, temp3
	ret
go_four:
	ldi		temp3, num4
	out		PORTC, temp3
	ret
go_three:
	ldi		temp3, num3
	out		PORTC, temp3
	ret
go_two:
	ldi		temp3, num2
	out		PORTC, temp3
	ret
go_one:
	ldi		temp3, num1
	out		PORTC, temp3
	ret
go_zero:
	ldi		temp3, num0
	out		PORTC, temp3
	ret

tenDigit:
	ldi		temp, (1<<1)
	out		PORTA, temp
	cpi		levelCounter, 0x00
	breq	go_zero
	cpi		levelCounter, 0x01
	breq	go_one
	cpi		levelCounter, 0x02
	breq	go_two
	cpi		levelCounter, 0x03
	breq	go_three
	cpi		levelCounter, 0x04
	breq	go_four
	cpi		levelCounter, 0x05
	breq	go_five
	cpi		levelCounter, 0x06
	breq	go_six
	cpi		levelCounter, 0x07
	breq	go_seven
	cpi		levelCounter, 0x08
	breq	go_eight
	cpi		levelCounter, 0x09
	breq	go_nine
	ret

hunderedDigit:
	ldi		temp, (1<<2)
	out		PORTA, temp
	cpi		hunderedNum, 0x00
	breq	go_zero
	cpi		hunderedNum, 0x01
	breq	go_one
	ret

convert_init:
	ldi     result,(1<<ACIE)|(1<<ACIS1)|(1<<ACIS0)  ;Initiate comparator
	out     ACSR,result 				; enable comparator interrupt
	ldi     result,(1<<TOIE0)      			;Enable timer interrupt
	out     TIMSK,result
	sbi     DDRB,PB1       			;Set converter charge/discharge pin
	cbi     DDRB,PB3				;AIN1	;Voltage input to the comparator
	ret							
		;Return from subroutine

AD_convert:
	ldi		result,preset		  	;Load offset value (192)
	out		TCNT0,result    		;to the counter
	clt								;Clear conversion complete flag (t)
	cbi		DDRB, PB2				;AIN0	;Disconnect discharging, input to comp.
	ldi		result,(1<<CS01)		;Start timer0 with prescaling f/8
	out		TCCR0,result

	sbi		PORTB,PB1				;Start charging of capacitor
	ret								;Return from subroutine

;Interrupt handler for A/D Comparator and overflow
ANA_COMP:       	
	in		result,TCNT0    	; Get timer value
	clr		temp    			; Stop timer0
	out		TCCR0,temp         
	subi	result,preset+1 	; Rescale A/D output 
								;(+1 for int. delay)

	cbi		PORTB,PB1       	;Start discharge
	sbi		DDRB, PB2			;AIN0	;Make discharging pin an output
								;it automatically becomes low
	set							;Set conversion complete flag (T flag)
	reti             			;Return from interrupt



expLookup:
.db 0
.db 1, 6
.db 11, 16
.db 20, 24
.db 28, 32
.db 36, 39
.db 43, 46
.db 49, 52
.db 55, 58
.db 61, 63
.db 66, 68
.db 71, 73
.db 75, 77
.db 79, 81
.db 83, 85
.db 86, 88
.db 89, 91
.db 92, 94
.db 95, 96
.db 98, 99
.db 100, 101
.db 102, 103
.db 104, 105
.db 106, 107
.db 108, 108
.db 109, 110
.db 111, 111
.db 112, 113
.db 113, 114
.db 114, 115
.db 115, 116
.db 116, 117
.db 117, 118
.db 118, 119
.db 119, 119
.db 120, 120
.db 120, 121
.db 121, 121
.db 122, 122
.db 122, 122
.db 123, 123
.db 123, 123
.db 123, 124
.db 124, 124
.db 124, 124
.db 124, 125
.db 125, 125
.db 125, 125
.db 125, 125
.db 126, 126
.db 126, 126
.db 126, 126
.db 126, 126
.db 126, 126
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
.db 127, 127
;exponential graph goes 127 for inf. in this example