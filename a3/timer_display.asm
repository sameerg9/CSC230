;Assignment_3.asm
; CSC 230 - Summer 2017
; 
; A3 Starter code
;
; B. Bird - 06/29/2017


; No data address definitions are needed since we use the "m2560def.inc" file

.include "m2560def.inc"


.include "lcd_function_defs.inc"

; Definitions for button values from the ADC
; Some boards may use the values in option B
; The code below used less than comparisons so option A should work for both

; Option A (v 1.1)
;.equ ADC_BTN_RIGHT = 0x032
;.equ ADC_BTN_UP = 0x0FA
;.equ ADC_BTN_DOWN = 0x1C2
;.equ ADC_BTN_LEFT = 0x28A
;.equ ADC_BTN_SELECT = 0x352

; Option B (v 1.0)
.equ ADC_BTN_RIGHT = 0x032
.equ ADC_BTN_UP = 0x0C3
.equ ADC_BTN_DOWN = 0x17C
.equ ADC_BTN_LEFT = 0x22B
.equ ADC_BTN_SELECT = 0x316

.equ SPH_DATASPACE = 0x5E
.equ SPL_DATASPACE = 0x5D

.equ STACK_INIT = 0x21FF


.cseg
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                          Reset/Interrupt Vectors                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org 0x0000 ; RESET vector
	jmp main_begin
	
; Add interrupt handlers for timer interrupts here. See Section 14 (page 101) of the datasheet for addresses.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Main Program                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.org 0x001e
	jmp TIMER2_OVERFLOW_ISR


; According to the datasheet, the last interrupt vector has address 0x0070, so the first
; "unreserved" location is 0x0074
.org 0x0074

main_begin:
	; Initialize the stack
	ldi r16, high(STACK_INIT)
	sts SPH_DATASPACE, r16
	ldi r16, low(STACK_INIT)
	sts SPL_DATASPACE, r16
	
	clr r16 
	ldi r16 , 0

	sts tenth, r16 
	sts sec_low,r16 
	sts sec_high , r16  
	sts min_low, r16 
	sts min_high, r16 
	
	sts tenth0, r16 
	sts sec_low0, r16 
	sts sec_high0, r16
	sts min_low0, r16 
	sts min_high0 , r16


	  ; Set up the ADC
    
    ; Set up ADCSRA (ADEN = 1, ADPS2:ADPS0 = 111 for divisor of 128)
    ldi    r16, 0x87
    sts    ADCSRA, r16
    
    ; Set up ADCSRB (all bits 0)
    ldi    r16, 0x00
    sts    ADCSRB, r16
    
    ; Set up ADMUX (MUX4:MUX0 = 00000, ADLAR = 0, REFS1:REFS0 = 1)
    ldi    r16, 0x40
    sts    ADMUX, r16

	ldi r16, 61
	sts speed , r16 
;	call wait_for_adc

	ldi r16 , 1 ;init so button can only enable timer start 
	sts adder, r16 
	
	clr r16 
	ldi r16 , 0 
	sts pause_toggle , r16 
	clr r16 

	call lcd_init

	ldi YL, low(LINE_ONE)
	ldi YH, high(LINE_ONE)

	ldi r16, 'T'
	st Y+, r16
	ldi r16, 'i'
	st Y+, r16
	ldi r16, 'm'
	st Y+, r16
	ldi r16, 'e'
	st Y+, r16
	ldi r16, ':'
	st Y+, r16
	ldi r16, ' '
	st Y+, r16
	ldi r16 ,' '
	STD Y+7,r16
	ST Y+ , r16 
	
	; Set up the lcd display starting row 0 column 0
	ldi r16, 0  ; Row number 0
	push r16
	ldi r16, 0  ; Column number 0
	push r16
	call lcd_gotoxy
	pop r16
	pop r16

	;Display the string
	ldi r16, high(LINE_ONE)
	push r16
	ldi r16, low(LINE_ONE)
	push r16
	call lcd_puts
	pop r16
	pop r16

;;;;;;;;;;set speed here 
	ldi r17, 24
	sts speed , r17

	ldi r16, 0 
	sts toggle, r16 ;;init toggle 
	sts ignore, r16 ;;init ignore 


	call TIMER2_SETUP
	
	call display_time

	jmp infinite_loop

infinite_loop:
	rjmp infinite_loop



display_time:
	
	push r16
	push YL
	push YH

	ldi YL, low(LINE_ONE)
	ldi YH, high(LINE_ONE)

	;set LCD to display first line
	ldi r16, 0x00
	push r16
	ldi r16, 0x06
	push r16
	call lcd_gotoxy
	pop r16
	pop r16
	
	ldi XL, low(curr_time)
	ldi XH, high(curr_time)

	lds r16, min_high
	call GET_DIGIT
	st Y+, r16
	
	st X+,r16  ;update current time 

	lds r16, min_low
	call GET_DIGIT
	st Y+, r16

	st X+, r16 

	ldi r16, ':'
	st Y+, r16
	
	st X+, r16	

	lds r16, sec_high
	call GET_DIGIT
	st Y+, r16

	st X+, r16

	lds r16, sec_low 
	call GET_DIGIT
	st Y+, r16
	
	st X+, r16

	ldi r16, '.'
	st Y+, r16
	st X+, r16

	lds r16, Tenth
	call GET_DIGIT
	st Y+, r16
	st X+, r16


	ldi r16 ,' '
	st Y+ ,r16 
	st Y+,r16
	st Y+, r16 
	 	
	;add null terminator
	ldi r16, 0
	st Y, r16


	;now call lcd_puts to display string
	ldi r16, high(LINE_ONE)
	push r16
	ldi r16, low(LINE_ONE)
	push r16
	call lcd_puts
	pop r16
	pop r16
	
	pop YH
	pop YL
	pop r16

	ret

stop:
	rjmp stop
	
TIMER2_SETUP:
	push r16

	ldi r16, 0x00
	sts TCCR2A, r16
	ldi r16, 0x06
	sts TCCR2B, r16
	ldi r16, 0x01
	sts TIMSK2, r16
	ldi r16, 0x01
	sts TIFR2, r16

	sei

	pop r16
	ret

TIMER2_OVERFLOW_ISR:
	push r16
	lds r16, SREG
	push r16
	push r17
	push r18

	lds r16, OVERFLOW_INTERRUPT_COUNTER
	inc r16
	sts OVERFLOW_INTERRUPT_COUNTER, r16
	
	; if counter equals 61, clear
	
	lds r17, speed  
	

	cp r16, r17  
	brlo timer2_isr_done

	clr r16
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	lds r16, Tenth 
	
 
	lds r18 , adder 
	add r16 , r18 
	clr r18 

	sts Tenth, r16
	clr r16
	call Set_Tenth

;;;;;;;;;;;;;;;;;;;;;;;; buttoin handling	
;;;;gonna put the adc dshity here 
	
button_loop:
	; Set up the ADC
    ; Set up ADCSRA (ADEN = 1, ADPS2:ADPS0 = 111 for divisor of 128)
    ldi    r16, 0x87
    sts    ADCSRA, r16
    ; Set up ADCSRB (all bits 0)
    ldi    r16, 0x00
    sts    ADCSRB, r16
    ; Set up ADMUX (MUX4:MUX0 = 00000, ADLAR = 0, REFS1:REFS0 = 1)
    ldi    r16, 0x40
    sts    ADMUX, r16
    ; Start an ADC conversion
    ; Set the ADSC bit to 1 in the ADCSRA register to start a conversion
    lds    r16, ADCSRA
    ori    r16, 0x40
    sts    ADCSRA, r16
    ; Wait for the conversion to finish
wait_for_adc:
    lds     r16, ADCSRA
    andi    r16, 0x40
    brne    wait_for_adc

    lds    XL, ADCL
    lds    XH, ADCH

	ldi r20, low(ADC_BTN_RIGHT)
    ldi r21, high(ADC_BTN_RIGHT)
    cp XL, r20
    cpc XH, r21
    brlo timer2_isr_done ;;replace with button 
    
    ldi r20, low(ADC_BTN_UP)
    ldi r21, high(ADC_BTN_UP)
    cp XL, r20
    cpc XH, r21
    brlo timer2_isr_done ;;replace with button
	
	
	ldi r20, low(ADC_BTN_LEFT)
    ldi r21, high(ADC_BTN_LEFT)
    cp XL, r20
    cpc XH, r21
    brlo reset_time 
	

    ldi r20, low(ADC_BTN_SELECT)
    ldi r21, high(ADC_BTN_SELECT)
    cp XL, r20
    cpc XH, r21
    brlo pause	

;;else if no button has been pressed 	

	lds r16 , ignore 
	cpi r16 , 1 
	breq button_loop

	;;return from call within main begin after setting speed 
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	


timer2_isr_done:

	call display_time
	sts OVERFLOW_INTERRUPT_COUNTER, r16

	pop r18
	pop r17

	pop r16
	sts SREG, r16

	pop r16

	reti

loop_done: 
	pop r16 
	ret 


pause: 
	lds r16 , pause_toggle 
	cpi r16 , 0 
	breq pause_function 
	cpi r16 , 1 
	breq unpause_function 


pause_function : 
	ldi r16, 1
	push r17 
	ldi r17 , 0 
	sts adder , r17  
	pop r17 
	push r28 
	ldi r28  , 1 
	sts ignore, r28 
	pop r28 
	pop r16 
	ret
unpause_function: 
	ldi r18 , 0 
	push r17 
	ldi r17 , 1 ;;maintain speed 
	sts adder , r17 
	pop r17 
	push r28 
	ldi r28 ,0
	sts ignore, r28 
	pop r28 
	pop r16 
	ret 




reset_time: 
	push r16 
	ldi r16, 0
	sts tenth, r16 
	sts sec_low,r16 
	sts sec_high , r16  
	sts min_low, r16 
	sts min_high, r16 
	
	ldi r16 , 1 
	sts ignore , r16 
	pop r16 
	rjmp timer2_isr_done 
	



Set_Tenth:
	push r16

	lds r16, Tenth
	cpi r16, 10
	brsh Set_Second_low
	pop r16

	ret

Set_Second_low:
	ldi r16, 0 
	sts Tenth, r16
	lds r16, sec_low
	inc r16
	sts sec_low, r16
	cpi r16, 10
	brsh Set_Second_high
	clr r16
	pop r16
	ret

Set_Second_high:
	ldi r16, 0
	sts sec_low, r16
	lds r16, sec_high
	inc r16
	sts sec_high, r16
	cpi r16, 6
	brsh Set_Minute_low
	clr r16
	pop r16
	ret

Set_Minute_low:
	ldi r16, 0
	;sts Tenth, r16
	;sts Secoind_2, r16
	sts sec_high, r16
	lds r16, min_low
	inc r16
	sts min_low, r16
	
	cpi r16, 10
	brsh Set_Minute_high
	clr r16
	pop r16
	ret

Set_Minute_high:
	ldi r16, 0
	sts tenth, r16
	sts sec_low, r16
	sts sec_high, r16
	sts min_low,r16 

	lds r16, min_high
	inc r16
	sts min_high, r16
	cpi r16, 10
	brsh Over
	clr r16
	pop r16
	reti

Over:
	jmp timer2_isr_done
	 

; GET_DIGIT( d: r16 )
; Given a value d in the range 0 - 9 (inclusive), return the ASCII character
; code for d. This function will produce undefined results if d is not in the
; required range.
; The return value (a character code) is stored back in r16
GET_DIGIT:
	push r17
	
	; The character '0' has ASCII value 48, and the character codes
	; for the other digits follow '0' consecutively, so we can obtain
	; the character code for an arbitrary single digit by simply
	; adding 48 (or just using the constant '0') to the digit.
	ldi r17, '0' ; Could also write "ldi r17, 48"
	add r16, r17
	
	pop r17
	ret

	;set the speed to 0 ; ~~~~~~~~~~~~~~		
	
; Include LCD library code
.include "lcd_function_code.asm"
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
; Note that no .org 0x200 statement should be present

LINE_ONE: .byte 100
OVERFLOW_INTERRUPT_COUNTER: .byte 1

min_high: .byte 1 ; Minute_1: .byte 1
min_low: .byte 1;Minute_2: .byte 1
sec_high: .byte 1	;Second_1: .byte 1
sec_low: .byte 1 		;Second_2: .byte 1
Tenth: .byte 1

min_high0: .byte 1
min_low0: .byte 1
sec_high0: .byte 1
Sec_low0: .byte 1
tenth0: .byte 1
speed: .byte 1 
toggle: .byte 1 
pause_toggle: .byte 1 
ignore: .byte 1


curr_time: .byte 10
adder: .byte 1 




