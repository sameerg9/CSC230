; a2_template.asm
; CSC 230 - Summer 2017
; 
; Some starter code for Assignment 2. You do not have
; to use this code if you'd rather start from scratch.
;
; B. Bird - 06/01/2017

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                        Constants and Definitions                            ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

; Special register definitions
.def XL = r26
.def XH = r27
.def YL = r28
.def YH = r29
.def ZL = r30
.def ZH = r31

; Stack pointer and SREG registers (in data space)
.equ SPH = 0x5E
.equ SPL = 0x5D
.equ SREG = 0x5F

; Initial address (16-bit) for the stack pointer
.equ STACK_INIT = 0x21FF

; Port and data direction register definitions (taken from AVR Studio; note that m2560def.inc does not give the data space address of PORTB)
.equ DDRB = 0x24
.equ PORTB = 0x25
.equ DDRL = 0x10A
.equ PORTL = 0x10B

; Definitions for the analog/digital converter (ADC) (taken from m2560def.inc)
; See the datasheet for details
.equ ADCSRA = 0x7A ; Control and Status Register
.equ ADCSRB    = 0x7B ; Control and Status Register B
.equ ADMUX = 0x7C ; Multiplexer Register
.equ ADCL = 0x78 ; Output register (high bits)
.equ ADCH = 0x79 ; Output register (low bits)

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


; Definitions of the special register addresses for timer 0 (in data space)
.equ GTCCR = 0x43
.equ OCR0A = 0x47
.equ OCR0B = 0x48
.equ TCCR0A = 0x44
.equ TCCR0B = 0x45
.equ TCNT0  = 0x46
.equ TIFR0  = 0x35
.equ TIMSK0 = 0x6E

; Definitions of the special register addresses for timer 1 (in data space)
.equ TCCR1A = 0x80
.equ TCCR1B = 0x81
.equ TCCR1C = 0x82
.equ TCNT1H = 0x85
.equ TCNT1L = 0x84
.equ TIFR1  = 0x36
.equ TIMSK1 = 0x6F

; Definitions of the special register addresses for timer 2 (in data space)
.equ ASSR = 0xB6
.equ OCR2A = 0xB3
.equ OCR2B = 0xB4
.equ TCCR2A = 0xB0
.equ TCCR2B = 0xB1
.equ TCNT2  = 0xB2
.equ TIFR2  = 0x37
.equ TIMSK2 = 0x70

;Definitions for counters
.def D0 = r20
.def D1 = r21
.def D2 = r22
.def D3 = r23

.equ counter_value = 0x00200000

.equ CV0 = low(counter_value-1)
.equ CV1 = byte2(counter_value-1)
.equ CV2 = byte3(counter_value-1)
.equ CV3 = byte4(counter_value-1)


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

.org 0x002e
    jmp TIMER0_OVERFLOW_ISR


; According to the datasheet, the last interrupt vector has address 0x0070, so the first
; "unreserved" location is 0x0074
.org 0x0074

main_begin:
 	
    ; Initialize the stack
    ldi r16, high(STACK_INIT)
    sts SPH, r16
    ldi r16, low(STACK_INIT)
    sts SPL, r16
    
    ldi r16, 0xFF
    sts DDRB, r16
    sts DDRL, r16

    call TIMER0_SETUP

    ldi r16, 0
    sts OVERFLOW_INTERRUPT_COUNTER, r16
    sei

    ldi r16, 1
    sts POSITION, r16
   
    ldi r17, 0
    sts INV, r17
	
	ldi r16, 0 
	sts select_toggle, r16 
	
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
	sts SPD , r16 

	

main_loop:





main_loop_done:
    lds r16, POSITION
    call SET_LED
	
	
    rjmp main_loop

stop:
    rjmp stop

TIMER0_SETUP:
    push r16

    ldi r16, 0x00
    sts TCCR0A, r16

    ldi r16, 0x05
    sts TCCR0B, r16

    ldi r16, 0x01
    sts TIMSK0, r16

    ldi r16, 0x01
    sts TIFR0, r16
    
    pop r16
    ret


TIMER0_OVERFLOW_ISR:


    push r16

    lds r16, SREG ; Load the value of SREG into r16
    push r16 ; Push SREG onto the stack

    push r17

    lds r16, OVERFLOW_INTERRUPT_COUNTER
    inc r16
    sts OVERFLOW_INTERRUPT_COUNTER, r16
			
	lds r18 , SPD
    cp r16, r18 
    brlo button_loop

    clr r16
    sts OVERFLOW_INTERRUPT_COUNTER, r16

    lds r16, POSITION
    ldi r17, 1
    cp r16, r17
    breq direction_up
    lds r16, POSITION
    ldi r17, 6
    cp r16, r17
    breq direction_down
    lds r17, DIRECTION
    add r16, r17
    sts POSITION, r16
;;;

    rjmp timer0_isr_done




direction_up:
	lds r1	 , select_toggle
	cpi r18 , 1 
	breq button_loop



    inc r16
    sts POSITION, r16
    ldi r16, 1
    sts DIRECTION, r16
	;;
	sts PREV_DIRECTION, r16
    rjmp timer0_isr_done
        
direction_down:
    lds r1	 , select_toggle
	cpi r18 , 1 
	breq button_loop

	
	
	
	dec r16
    sts POSITION, r16
    ldi r17, 0xFF
    sts DIRECTION, r17
	;
	sts PREV_DIRECTION, r17
    rjmp timer0_isr_done
    
 
button_loop:
	   
    ; Start an ADC conversion
    
    ; Set the ADSC bit to 1 in the ADCSRA register to start a conversion
    lds    r16, ADCSRA
    ori    r16, 0x40
    sts    ADCSRA, r16
    


    ; Wait for the conversion to finish
wait_for_adc:
    lds        r16, ADCSRA
    andi    r16, 0x40
    brne    wait_for_adc

    lds    XL, ADCL
    lds    XH, ADCH
    
    ldi r20, low(ADC_BTN_RIGHT)
    ldi r21, high(ADC_BTN_RIGHT)
    cp XL, r20
    cpc XH, r21
    brlo right
    
    ldi r20, low(ADC_BTN_UP)
    ldi r21, high(ADC_BTN_UP)
    cp XL, r20
    cpc XH, r21
    brlo up

    ldi r20, low(ADC_BTN_DOWN)
    ldi r21, high(ADC_BTN_DOWN)
    cp XL, r20
    cpc XH, r21
    brlo down

    ldi r20, low(ADC_BTN_LEFT)
    ldi r21, high(ADC_BTN_LEFT)
    cp XL, r20
    cpc XH, r21
    brlo left

check_select:

    ldi r20, low(ADC_BTN_SELECT)
    ldi r21, high(ADC_BTN_SELECT)
    cp XL, r20
    cpc XH, r21
    brlo pause	
	;brge cont


lds r1	 , select_toggle
cpi r18 , 1 
breq timer0_isr_done





timer0_isr_done:
	lds r1	 , select_toggle
cpi r18 , 1 
breq button_loop

 
    pop r17
    ; The next stack value is the value of SREG
    pop r16 ; Pop SREG into r16
    sts SREG, r16 ; Store r16 into SREG
    ; Now pop the original saved r16 value
    pop r16

    reti ; Return from interrupt



right:
    clr XL
    clr XH
    ldi r16, 0
    sts INV, r16
    rjmp timer0_isr_done

up:
    clr XL
    clr XH
    ldi    r16, 0b00001000
    sts PORTB, r16
    ldi r16, 0
    sts PORTL, r16

	ldi r16 , 15
	sts SPD ,r16  

    rjmp timer0_isr_done


down:
    clr XL
    clr XH
    ldi    r16, 0b00000010
    sts PORTL, r16
    ldi r16, 0
    sts PORTB, r16

	ldi r16 , 61
	sts SPD ,r16 

    rjmp timer0_isr_done

left:
    clr XL
    clr XH
    ldi r16, 1
    sts INV, r16
    rjmp timer0_isr_done


pause:
	clr XL
	clr XH
	
	
	lds r16 , select_toggle 
	ldi r17 , 1 	
	
	add r16 , r17 
	clr r17   
chill:	
	ldi r19 , 0 
	sts DIRECTION , r19 
	clr r19 	

	andi r16 , 1       ;mainttain last but apriori compar	
	
	sts select_toggle, r16
	cpi r16 , 0 
	breq cont
	
	rjmp timer0_isr_done 



cont: 
;;;;;;;;;;;;;;;;;;;;;;;~~~`
	lds r16 , select_toggle 
	cpi r16 , 1
	breq chill

	lds r16, PREV_DIRECTION   ; maintain prev direction  
	sts DIRECTION, r16 
	rjmp timer0_isr_done
;;;;;; 

	

	

SET_LED:
	

    push r16
    push r17
    push r18

    cpi r16, 1
    breq led1
    cpi r16, 2
    breq led2
    cpi r16, 3
    breq led3
    cpi r16, 4
    breq led4
    cpi r16, 5
    breq led5
    cpi r16, 6
    breq led6

    rjmp led_done

led1:
    ldi r16, 0b00000010
    ldi r17, 0
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17
    rjmp led_done
    
led2:        
    ldi r16, 0b00001000
    ldi r17, 0
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17    
    rjmp led_done

led3:    
    ldi r16, 0    
    ldi r17, 0b00000010
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17    
    rjmp led_done

led4:    
    ldi r16, 0
    ldi r17, 0b00001000
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17    
    rjmp led_done

led5:
    ldi r16, 0
    ldi r17, 0b00100000
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17    
    rjmp led_done

led6:
    ldi r16, 0
    ldi r17, 0b10000000
    lds r18, INV
    cpi r18, 1
    breq invert
    sts PORTB, r16
    sts PORTL, r17
    rjmp led_done

invert:
    com r16
    com r17
    sts PORTB, r16
    sts PORTL, r17
    rjmp led_done
	 

led_done:
    pop r18
    pop r17
    pop r16
    ret

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;                               Data Section                                  ;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

.dseg
.org 0x200
; Put variables and data arrays here...

LED_STATE: .byte 1 ; The current state of the LED (1 = on, 0 = off)

OVERFLOW_INTERRUPT_COUNTER: .byte 1 ; Counter for the number of times the overflow interrupt has been triggered.

POSITION: .byte 1

DIRECTION: .byte 1
INV: .byte 1
SPD: .byte 1 

select_toggle: .byte 1 
PREV_DIRECTION: .byte 1 
