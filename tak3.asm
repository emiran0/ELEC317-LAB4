/*
 * Lab4_ADC.asm
 *
 ******  TASK 1 ********	
 *
 *	204 Byte
 *	7 Register used.
 *	CLK ==> 4MHz. To stop sudden jumps in seven segment display.
 *	There are minor changes like new Delay subroutine and driving
 *	the seven segment display. 
 *  
 */ 

;***** Constants
.equ	preset=193			;T/C0 Preset constant (256-64)
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
.def	temp=r17			;Scratch register
.def	sevsegDigit = r18
.def	levelCounter = r19
.def	temp2=r20
.def	temp3=r21
.def	temp4 = r22

;***********************************************************;
;*  	PROGRAM START - EXECUTION STARTS HERE			   *;	
;***********************************************************;
.cseg
.org $0000
jmp RESET      ;Reset handle

RESET:
	ldi 	TEMP, low(RAMEND)	; initialize stack pointer
	out		SPL, TEMP
	ldi 	TEMP, high(RAMEND)
	out 	SPH, TEMP
	ldi		result,$ff			;set port D as output
	out		DDRC,result			;for LED�s
	ldi		temp2, (1<<ADLAR)|(1<<MUX2)|(1<<MUX1) ; ADC6 pin is used which is the same as PA6 pin.
	out		ADMUX, temp2
	ldi		r23, (1<<ADEN)|(1<<ADPS1)|(1<<ADPS0)|(1<<ADPS2)
	out		ADCSRA, temp2
	sei							;Enable global interrupt
Delay:	
	clr		temp2			;Clear temp counter 1
	ldi		temp3,$f0		;Reset temp counter 2
	ldi		r23, (1<<ADEN)|(1<<ADSC) ; Start A/D Conversion again
	out		ADCSRA, r23
loop1:	
	inc		temp2			;Count up temp counter 1
	brne	loop1			;Check if inner loop is finished
	inc 	temp3			;Count up temp counter 2
	brne 	loop1			;Check if delay is finished
	
Wait:
	in		sevsegDigit, ADCH ; Get high resolution 8 bit from the high register.
	lsr		sevsegDigit ;	8 to 7 bit (added resolution)
	lsr		sevsegDigit ;	7 to 6 bit (added resolution)
	rcall	seperateDigits
	rcall	tenDigit
	rcall	Delay2
	rcall	digitSelect		
	rcall	Delay2
	rjmp	Delay			;Repeat conversion

Delay2:	ldi temp3, $00
	ldi temp4, $05
Wait1:	subi temp3, 1
	sbci temp4, 0
	brcc Wait1
	ret

seperateDigits:
	cpi		sevsegDigit, 0x0A
	brsh	countTens
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
	clr		levelCounter
	ldi		temp3, num9
	out		PORTC, temp3
	ret
go_eight:
	clr		levelCounter
	ldi		temp3, num8
	out		PORTC, temp3
	ret
go_seven:
	clr		levelCounter
	ldi		temp3, num7
	out		PORTC, temp3
	ret
go_six:
	clr		levelCounter
	ldi		temp3, num6
	out		PORTC, temp3
	ret
go_five:
	clr		levelCounter
	ldi		temp3, num5
	out		PORTC, temp3
	ret
go_four:
	clr		levelCounter
	ldi		temp3, num4
	out		PORTC, temp3
	ret
go_three:
	clr		levelCounter
	ldi		temp3, num3
	out		PORTC, temp3
	ret
go_two:
	clr		levelCounter
	ldi		temp3, num2
	out		PORTC, temp3
	ret
go_one:
	clr		levelCounter
	ldi		temp3, num1
	out		PORTC, temp3
	ret
go_zero:
	clr		levelCounter
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
	ret