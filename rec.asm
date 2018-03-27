list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

state   udata 0x21
state

counter   udata 0x22
counter

w_temp  udata 0x23
w_temp

status_temp udata 0x24
status_temp

pclath_temp udata 0x25
pclath_temp

portb_var   udata 0x26
portb_var

org     0x00
goto    init

org     0x08
goto    isr             ;go to interrupt service routine

init:
    ;Disable interrupts
    clrf    INTCON
    clrf    INTCON2

    ;Configure Output Ports
    clrf    LATF ; clear LATF
    clrf    TRISF ; use LATF as output

    ;Configure Input/Interrupt Ports
    movlw   b'00010000' ; w_reg =  b'00010000'
    movwf   TRISB   ; TRISB = =w_reg = b'00010000' 
    bcf     INTCON2, 7  ;Pull-ups are enabled - clear INTCON2<7>
    clrf    PORTB

    ;Initialize Timer0
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
                        ;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON ; T0CON = b'01000111'

    ;Enable interrupts
    movlw   b'11101000' ;Enable Global, peripheral, Timer0 and RB interrupts by setting GIE, PEIE, TMR0IE and RBIE bits to 1
    movwf   INTCON

    bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1

main:
    btfsc   state,0         ; Is state 0?
    bsf     PORTF,0         ; No, then turn on LED0
    btfss   state,0         ; Is state 1?
    bcf     PORTF,0         ; No, then turn off LED0
    goto    main

isr:
    call    save_registers  ;Save current content of STATUS and PCLATH registers to be able to restore them later

    btfss   INTCON, 2       ;Is this a timer interrupt?
    goto    rb_interrupt    ;No. Goto PORTB on change interrupt handler part
    goto    timer_interrupt ;Yes. Goto timer interrupt handler part

;;;;;;;;;;;;;;;;;;;;;;;; Timer interrupt handler part ;;;;;;;;;;;;;;;;;;;;;;;;;;
timer_interrupt:
    incf	counter, f              ;Timer interrupt handler part begins here by incrementing count variable
    movf	counter, w              ;Move count to Working register
    sublw	d'5'                    ;Decrement 5 from Working register
    btfss	STATUS, Z               ;Is the result Zero?
    goto	timer_interrupt_exit    ;No, then exit from interrupt service routine
    clrf	counter                 ;Yes, then clear count variable
    comf	state, f                ;Complement our state variable which controls on/off state of LED0

timer_interrupt_exit:
    bcf		INTCON, 2           ;Clear TMROIF
    movlw	d'61'               ;256-61=195; 195*256*5 = 249600 instruction cycle;
    movwf	dTMR0
    call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
    retfie

;;;;;;;;;;;;;;;;;;; PORTB on change interrupt handler part ;;;;;;;;;;;;;;;;;;;;;
rb_interrupt:
    btfss	INTCON, 0           ;Is this PORTB on change interrupt
    goto	rb_interrupt_exit0  ;No, then exit from interrupt service routine
    movf	PORTB, w            ;Read PORTB to working register
    movwf	portb_var           ;Save it to shadow register
    btfsc	portb_var, 4        ;Test its 4th bit whether it is cleared
    goto	rb_interrupt_exit2  ; RB4 is 1
    bsf		PORTF, 7            ; RB4 is 0, Button is pressed, so turn on LED7

rb_interrupt_exit1:
    movf	portb_var, w        ;Put shadow register to W
    movwf	PORTB               ;Write content of W to actual PORTB, so that we will be able to clear RBIF
    bcf		INTCON, 0           ;Clear PORTB on change FLAG
    call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
    retfie

rb_interrupt_exit2:
    bcf		PORTF, 7            ;Button is released, so turn off LED7
    movf	portb_var, w        ;Put shadow register to W
    movwf	PORTB               ;Write content of W to actual PORTB, so that we will be able to clear RBIF
    bcf		INTCON, 0           ;Clear PORTB on change FLAG
    call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
    retfie

rb_interrupt_exit0:
    call	restore_registers   ;Restore STATUS and PCLATH registers to their state before interrupt occurs
    retfie

;;;;;;;;;;;; Register handling for proper operation of main program ;;;;;;;;;;;;
save_registers:
    movwf 	w_temp          ;Copy W to TEMP register
    swapf 	STATUS, w       ;Swap status to be saved into W
    clrf 	STATUS          ;bank 0, regardless of current bank, Clears IRP,RP1,RP0
    movwf 	status_temp     ;Save status to bank zero STATUS_TEMP register
    movf 	PCLATH, w       ;Only required if using pages 1, 2 and/or 3
    movwf 	pclath_temp     ;Save PCLATH into W
    clrf 	PCLATH          ;Page zero, regardless of current page
    return

restore_registers:
    movf 	pclath_temp, w  ;Restore PCLATH
    movwf 	PCLATH          ;Move W into PCLATH
    swapf 	status_temp, w  ;Swap STATUS_TEMP register into W
    movwf 	STATUS          ;Move W into STATUS register
    swapf 	w_temp, f       ;Swap W_TEMP
    swapf 	w_temp, w       ;Swap W_TEMP into W
    return

end