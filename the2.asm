list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

UDATA_ACS
  state_rg0	res 1
  state_rg1	res 1
  state_rg2	res 1
  state_rg3	res 1
  paddlepos_0	res 1
  paddlepos_1	res 1
  ballpos_x	res 1
  ballpos_y	res 1


	
state   udata 0x21
state

counter   udata 0x22
counter
   
org     0x00
goto    init

org     0x08
goto    isr             ;go to interrupt service routine

init:
    ;Disable interrupts
    clrf    INTCON
    clrf    INTCON2

    ;Configure Output Ports
    clrf    LATA ; clear LATF
    clrf    TRISA ; use LATF as output
    clrf    LATB ; clear LATF
    clrf    TRISB ; use LATF as output
    clrf    LATC ; clear LATF
    clrf    TRISC ; use LATF as output
    clrf    LATD ; clear LATF
    clrf    TRISD ; use LATF as output
    clrf    LATE ; clear LATF
    clrf    TRISE ; use LATF as output
    clrf    LATF ; clear LATF
    clrf    TRISF ; use LATF as output
    
    clrf    LATG
    movlw   0x0f
    movwf   TRISG
    
    movlw   b'00011100'
    movwf   LATA
    movwf   LATF
    bsf	    LATD, 3

    ;Initialize Timer0
    movlw   b'01000111' ;Disable Timer0 by setting TMR0ON to 0 (for now)
                        ;Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ;Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON ; T0CON = b'01000111'

    bsf     INTCON2, 2  ;Timer HIGH priority !!!!!!

    ;Enable interrupts
    movlw   b'11100000' ;Enable Global, peripheral, Timer0 by setting GIE, PEIE, TMR0IE bits to 1
    movwf   INTCON

    bsf     T0CON, 7    ;Enable Timer0 by setting TMR0ON to 1
    
    movlw   0x02	;initially at position 2
    movwf   paddlepos_0
    movwf   paddlepos_1
    
    clrf    state_rg0	;initially all buttons are unpressed
    clrf    state_rg1
    clrf    state_rg2
    clrf    state_rg3

    movlw   0x3
    movwf   ballpos_x
    movwf   ballpos_y
main:
    call    rg0_task
    call    rg1_task
    call    rg2_task
    call    rg3_task
    goto    main
    
    
;;;;;;;;;;;;;;;;;;;;;;;; Interrupt  Service  Routine  ;;;;;;;;;;;;;;;;;;;;;;;;;;
isr:
    btfss   INTCON, 2       ;Is this a timer interrupt?
    goto    timer_interrupt ;Yes. Goto timer interrupt handler part

;;;;;;;;;;;;;;;;;;;;;;;; Timer interrupt handler part ;;;;;;;;;;;;;;;;;;;;;;;;;;
timer_interrupt:
    incf	counter, f              ;Timer interrupt handler part begins here by incrementing count variable
    movf	counter, w              ;Move count to Working register
    sublw	d'50'                   ;Decrement 5 from Working register
    btfss	STATUS, Z               ;Is the result Zero?
    goto	timer_interrupt_exit    ;No, then exit from interrupt service routine
    clrf	counter                 ;Yes, then clear count variable
    ; change ball position
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	0
    bz		portA
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	1
    bz		portB_right
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	2
    bz		portC_right
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	3
    bz		portD_right
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	4
    bz		portE_right
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	5
    bz		portF
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	6
    bz		portE_left
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	7
    bz		portD_left
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	8
    bz		portC_left
    
    movf	ballpos_x, w		; switch(ballpos)
    xorlw	9
    bz		portB_left
    
    return
    
    portA:  ; can only move in right direction
	; check if paddle and ball overlap, if not player1 lost, restart
	btfss	direction
	goto	_up		    ; if direction is 0 goto _up
	movf	direction, w
	xorlw	0x1		    ; check if direction is 1
	BZ	$+4		   ; if Z flag is not set, direction is 2 
	goto	_down
	;;;;;;;;;;;;;;;;;;;;;;;;
	; direction is 1, move horizontally
	bsf	PORTB, ballpos_y
	goto	timer_interrupt_exit
	;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	; dont check porta but check ballpos_y
	_up:
	 
	
	
    

timer_interrupt_exit:
    bcf		INTCON, 2           ;Clear TMROIF
    movlw	d'22'               ;256-61=195; 195*256*5 = 249600 instruction cycle;
    movwf	TMR0
    retfie
    
rg0_task
    tstfsz  state_rg0	        ; check if previously unpressed
    goto    _pressed_0
    btfss   PORTG, 0
    return
    comf    state_rg0, f	; state changed to pressed
    ;change paddle position
    
    movf   paddlepos_1, w		; switch(paddlepos_1) 
    XORLW   0
    BZ	    pos_0

    movf   paddlepos_1, w
    XORLW   1
    BZ	    pos_1

    movf   paddlepos_1, w
    XORLW   2
    BZ	    pos_2

    movf   paddlepos_1, w
    XORLW   3
    BZ	    pos_3
    
    return
    pos_0:  ; rf0 & rf1 & rf2 are on
	bcf	LATF, 0 ; rf0 turned off
	bsf	LATF, 3 ; rf3 turned on
	incf	paddlepos_1
	return

    pos_1:  ; rf1 & rf2 & rf3 are on
	bcf	LATF, 1 ; rf1 turned off
	bsf	LATF, 4 ; rf4 turned on
	incf	paddlepos_1
	return
    pos_2:  ; rf2 & rf3 & rf4 are on
	bcf	LATF, 2 ; rf2 turned off
	bsf	LATF, 5 ; rf5 turned on
	incf	paddlepos_1
	return
    pos_3:  ; rf3 & rf4 & rf5 are on
	return
    
    
    
_pressed_0:
    btfsc   PORTG, 0 
    return
    comf    state_rg0, f	; state changed to unpressed
    return

rg1_task
    tstfsz  state_rg1	        ; check if previously unpressed
    goto    _pressed_1
    btfss   PORTG, 1
    return
    comf    state_rg1, f	; state changed to pressed
    ;change paddle position
    movf   paddlepos_1, w		; switch(paddlepos_1) 
    XORLW   0
    BZ	    pos1_0

    movf   paddlepos_1, w
    XORLW   1
    BZ	    pos1_1

    movf   paddlepos_1, w
    XORLW   2
    BZ	    pos1_2

    movf   paddlepos_1, w
    XORLW   3
    BZ	    pos1_3
    
    return
    pos1_0:  ; rf0 & rf1 & rf2 are on
	return

    pos1_1:  ; rf1 & rf2 & rf3 are on
	bcf	LATF, 3 ; rf3 turned off
	bsf	LATF, 0 ; rf0 turned on
	decf	paddlepos_1
	return
    pos1_2:  ; rf2 & rf3 & rf4 are on
	bcf	LATF, 4 ; rf4 turned off
	bsf	LATF, 1 ; rf1 turned on
	decf	paddlepos_1
	return
    pos1_3:  ; rf3 & rf4 & rf5 are on
	bcf	LATF, 5 ; rf5 turned off
	bsf	LATF, 2 ; rf2 turned on
	decf	paddlepos_1
	return
    
_pressed_1:
    btfsc   PORTG, 1
    return
    comf    state_rg1, f	; state changed to unpressed
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rg2_task
    tstfsz  state_rg2	        ; check if previously unpressed
    goto    _pressed_2
    btfss   PORTG, 2
    return
    comf    state_rg2, f	; state changed to pressed
    ;change paddle position
    movf   paddlepos_0, w		; switch(paddlepos_0) 
    XORLW   0
    BZ	    pos2_0

    movf   paddlepos_0, w
    XORLW   1
    BZ	    pos2_1

    movf   paddlepos_0, w
    XORLW   2
    BZ	    pos2_2

    movf   paddlepos_0, w
    XORLW   3
    BZ	    pos2_3
    
    return
    pos2_0:  ; ra0 & ra1 & ra2 are on
	bcf	LATA, 0 ; ra0 turned off
	bsf	LATA, 3 ; ra3 turned on
	incf	paddlepos_0
	return

    pos2_1:  ; ra1 & ra2 & ra3 are on
	bcf	LATA, 1 ; ra1 turned off
	bsf	LATA, 4 ; ra4 turned on
	incf	paddlepos_0
	return
    pos2_2:  ; ra2 & ra3 & ra4 are on
	bcf	LATA, 2 ; ra2 turned off
	bsf	LATA, 5 ; ra5 turned on
	incf	paddlepos_0
	return
    pos2_3:  ; ra3 & ra4 & ra5 are on
	return
    
_pressed_2:
    btfsc   PORTG, 2
    return
    comf    state_rg2, f	; state changed to unpressed
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rg3_task
    tstfsz  state_rg3	        ; check if previously unpressed
    goto    _pressed_3
    btfss   PORTG, 3
    return
    comf    state_rg3, f	; state changed to pressed
    ;change paddle position
    ; move the paddle up
    movf   paddlepos_0, w		; switch(paddlepos_0) 
    XORLW   0
    BZ	    pos3_0

    movf   paddlepos_0, w
    XORLW   1
    BZ	    pos3_1

    movf   paddlepos_0, w
    XORLW   2
    BZ	    pos3_2

    movf   paddlepos_0, w
    XORLW   3
    BZ	    pos3_3
    
    return
    pos3_0:  ; ra0 & ra1 & ra2 are on
	return

    pos3_1:  ; ra1 & ra2 & ra3 are on
	bcf	LATA, 3 ; ra3 turned off
	bsf	LATA, 0 ; ra0 turned on
	decf	paddlepos_0
	return
    pos3_2:  ; ra2 & ra3 & ra4 are on
	bcf	LATA, 4 ; ra4 turned off
	bsf	LATA, 1 ; ra1 turned on
	decf	paddlepos_0
	return
    pos3_3:  ; ra3 & ra4 & ra5 are on
	bcf	LATA, 5 ; ra5 turned off
	bsf	LATA, 2 ; ra2 turned on
	decf	paddlepos_0
	return
   
_pressed_3:
    btfsc   PORTG, 3
    return
    comf    state_rg3, f	; state changed to unpressed
    return

    

END