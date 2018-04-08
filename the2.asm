list P=18F8722

#include <p18f8722.inc>
config OSC = HSPLL, FCMEN = OFF, IESO = OFF, PWRT = OFF, BOREN = OFF, WDT = OFF, MCLRE = ON, LPT1OSC = OFF, LVP = OFF, XINST = OFF, DEBUG = OFF

UDATA_ACS
    state_rg0	    res 1
    state_rg1	    res 1
    state_rg2	    res 1
    state_rg3	    res 1
    paddlepos_1	    res 1
    paddlepos_2	    res 1
    ballcolumn	    res 1
    ballrow	    res 1
    direction	    res 1
    tmp		    res 1
    p1_wins_round   res 1
    p2_wins_round   res 1
    p1_score	    res 1
    p2_score	    res 1
    t1		    res 1
    t2		    res 1
    t3		    res 1

state   udata 0x21
state

counter udata 0x22
counter

org     0x00
goto    start

org     0x08
goto    isr             ;go to interrupt service routine

_gameends_:
    bcf	    INTCON, 7	; disable all interrupts
    goto    main	; loop forever

DELAY 	; handles button tasks as well
    MOVLW 1	; Copy desired value to W
    MOVWF t3	; Copy W into t3
    ___loop3:
	MOVLW 0x20  ; Copy desired value to W
	MOVWF t2    ; Copy W into t2
	___loop2:
	    MOVLW 0x5D	; Copy desired value to W
	    MOVWF t1	; Copy W into t1
	    ___loop1:
    		call    rg0_task
		call    rg1_task
		call    rg2_task
		call    rg3_task
		decfsz t1,F ; Decrement t1. If 0 Skip next instruction
		GOTO ___loop1 ; ELSE Keep counting down
		decfsz t2,F ; Decrement t2. If 0 Skip next instruction
		GOTO ___loop2 ; ELSE Keep counting down
		decfsz t3,F ; Decrement t3. If 0 Skip next instruction
		GOTO ___loop3 ; ELSE Keep counting down
		return

start:
    clrf    TRISH   ; conf?gure PORTH as output
    clrf    TRISJ   ; conf?gure PORTJ as output
    clrf    PORTH
    clrf    PORTJ
    clrf    p1_score
    clrf    p2_score

init:
    tstfsz  p1_wins_round
    incf    p1_score	    ; p1 has scored, increment its score

    tstfsz  p2_wins_round
    incf    p2_score	    ; p2 has scored, increment its score

    clrf    p1_wins_round
    clrf    p2_wins_round

    ;Disable interrupts
    clrf    INTCON
    clrf    INTCON2

    ;Configure Output Ports
    clrf    LATA
    clrf    TRISA   ; use PORTA as output
    clrf    LATB
    clrf    TRISB   ; use PORTB as output
    clrf    LATC
    clrf    TRISC   ; use PORTC as output
    clrf    LATD
    clrf    TRISD   ; use PORTD as output
    clrf    LATE
    clrf    TRISE   ; use PORTE as output
    clrf    LATF
    clrf    TRISF   ; use PORTF as output

    clrf    LATG
    movlw   0x0f    ; use rg0-3 as inputs
    movwf   TRISG

    movlw   b'00011100'	; initial paddle positions
    movwf   LATA
    movwf   paddlepos_1
    movwf   LATF
    movwf   paddlepos_2
    bsf	    LATD, 3	; initial ball position

    movlw   d'1'	; set timer0's initial value
    movwf   TMR0

    ;Initialize Timer0
    movlw   b'01000111' ; Disable Timer0 by setting TMR0ON to 0 (for now)
                        ; Configure Timer0 as an 8-bit timer/counter by setting T08BIT to 1
                        ; Timer0 increment from internal clock with a prescaler of 1:256.
    movwf   T0CON	; T0CON = b'01000111'

    movlw   b'10000001' ; Enable Timer1 by setting TMR1ON to 1
                        ; Configure Timer1 as 16-bit
    movwf   T1CON	; T1CON = b'10000001'


    bsf     INTCON2, 2  ; Timer0 set as HIGH priority

    ;Enable interrupts
    movlw   b'11100000' ; Enable Global, peripheral, Timer0 by setting GIE, PEIE, TMR0IE bits to 1
    movwf   INTCON

    bsf     T0CON, 7    ; Enable Timer0 by setting TMR0ON to 1

    clrf    state_rg0
    clrf    state_rg1
    clrf    state_rg2
    clrf    state_rg3

    movlw   0x3
    movwf   ballcolumn	; initially on PORTD, mov?ng to the right
    movlw   b'00001000'	; 3rd row - RD3
    movwf   ballrow

main:
    movf	p1_wins_round, w
    xorlw	0x03
    bz		init		; player1 has scored

    movf	p2_wins_round, w
    xorlw	0x03
    bz		init		; player2 has scored

    ;;;;;;;;;display;;;;;;;;;

    ; switch(p1_score)
    movf	p1_score, w
    xorlw	0x00
    bz		_score0

    movf	p1_score, w
    xorlw	0x01
    bz		_score1

    movf	p1_score, w
    xorlw	0x02
    bz		_score2

    movf	p1_score, w
    xorlw	0x03
    bz		_score3

    movf	p1_score, w
    xorlw	0x04
    bz		_score4

    movf	p1_score, w
    xorlw	0x05
    bz		_score5

_score0:
    movlw   b'00111111'
    movwf   tmp
    goto    _display0

_score1:
    movlw   b'00000110'
    movwf   tmp
    goto    _display0

_score2:
    movlw   b'01011011'
    movwf   tmp
    goto    _display0

_score3:
    movlw   b'01001111'
    movwf   tmp
    goto    _display0

_score4:
    movlw   b'01100110'
    movwf   tmp
    goto    _display0

_score5:
    movlw   b'01101101'
    movwf   tmp


_display0:  ; update display for player1
    bsf	    PORTH, 0
    movff   tmp, PORTJ
    call    DELAY
    bcf	    PORTH, 0


;;;;;;;;;;;;;;;;;display3;;;;;;;;;;;;;;;;

    ; switch(p2_score)
    movf	p2_score, w
    xorlw	0x00
    bz		_score0_

    movf	p2_score, w
    xorlw	0x01
    bz		_score1_

    movf	p2_score, w
    xorlw	0x02
    bz		_score2_

    movf	p2_score, w
    xorlw	0x03
    bz		_score3_

    movf	p2_score, w
    xorlw	0x04
    bz		_score4_

    movf	p2_score, w
    xorlw	0x05
    bz		_score5_


_score0_:
    movlw   b'00111111'
    movwf   tmp
    goto    _display3

_score1_:
    movlw   b'00000110'
    movwf   tmp
    goto    _display3

_score2_:
    movlw   b'01011011'
    movwf   tmp
    goto    _display3

_score3_:
    movlw   b'01001111'
    movwf   tmp
    goto    _display3

_score4_:
    movlw   b'01100110'
    movwf   tmp
    goto    _display3

_score5_:
    movlw   b'01101101'
    movwf   tmp

_display3:  ; update display for player2
    bsf	    PORTH, 3
    movff   tmp, PORTJ
    call    DELAY
    bcf	    PORTH, 3

    ; check if any of the players reached score 5

    movlw   0x05
    cpfseq  p1_score
    goto    _scorecheck_p2
    goto    _gameends_

_scorecheck_p2:
    cpfseq  p2_score
    goto    _continue
    goto    _gameends_

_continue:	; game continues
    call    determine_direction
    goto    main

randomize_helper:
    movff   TMR0, WREG
    clrf    WREG
    movff   TMR1, WREG
    btfsc   TMR1H, 5
    clrf    WREG
    return

determine_direction:		 ; intended for randomization
    btfss   TMR1H, 6		 ; tests bits of TIMER0 and TIMER1
    call    randomize_helper	 ; to make a more immersive experience

    btfsc   TMR0, 6
    call    randomize_helper

    btfss   TMR0, 5
    call    randomize_helper

    btfsc   TMR1, 4
    call    randomize_helper

    btfss   TMR1H, 3
    call    randomize_helper

    btfsc   TMR0, 3
    call    randomize_helper

    btfss   TMR1, 1
    call    randomize_helper

    movf    TMR1, w
    andlw   b'00000011'
    movwf   tmp

    movf	tmp, w		; rightmost 2 bits are 00
    xorlw	b'00000000'
    bz		_horizontal	; move horizontally

    movf	tmp, w		; rightmost 2 bits are 11
    xorlw	b'00000011'
    bz		_horizontal	; move horizontally

    movf	tmp, w		; rightmost 2 bits are 01
    xorlw	b'00000001'
    bz		_up		; move up

    movf	tmp, w		; rightmost 2 bits are 10
    xorlw	b'00000010'
    bz		_down		; move down

_up:
    movlw   0x00
    movwf   direction
    return
_horizontal:
    movlw   0x01
    movwf   direction
    return
_down:
    movlw   0x02
    movwf   direction
    return

;;;;;;;;;;;;;;;;;;;;;;;; Interrupt  Service  Routine  ;;;;;;;;;;;;;;;;;;;;;;;;;;
isr:

    movlw	d'1'            ; 256-1=255; 255*256*46 = 3002880 instruction cycles;
    movwf	TMR0
    bcf		INTCON, 2       ; Clear TMROIF

    incf	counter, f      ; increment counter variable
    movf	counter, w      ; Move counter to working register
    sublw	d'46'           ; Decrement 50 from Working register
    btfss	STATUS, Z       ; Is the result zero?
    goto	isr_exit	; No, then exit from interrupt service routine
    clrf	counter         ; Yes, then clear counter variable

    ; change ball position vertically
    movf	direction, w		; move horizontally
    xorlw	0x00
    bz		_move

    movf	direction, w		; move up
    xorlw	0x01
    bz		_move_up

    movf	direction, w		; move down
    xorlw	0x02
    bz		_move_down

    movf	direction, w		; move horizontally
    xorlw	0x03
    bz		_move

_move_up:   ; move ball upwards
    btfss	ballrow, 0
    rrncf	ballrow, f
    goto	_move
_move_down: ; move ball downwards
    btfss	ballrow, 5
    rlncf	ballrow, f

_move:
    movf	ballcolumn, w	; switch(ballpos)
    xorlw	0x00
    bz		portA

    movf	ballcolumn, w
    xorlw	0x01
    bz		portB_right

    movf	ballcolumn, w
    xorlw	0x02
    bz		portC_right

    movf	ballcolumn, w
    xorlw	0x03
    bz		portD_right

    movf	ballcolumn, w
    xorlw	0x04
    bz		portE_right

    movf	ballcolumn, w
    xorlw	0x05
    bz		portF

    movf	ballcolumn, w
    xorlw	0x06
    bz		portE_left

    movf	ballcolumn, w
    xorlw	0x07
    bz		portD_left

    movf	ballcolumn, w
    xorlw	0x08
    bz		portC_left

    movf	ballcolumn, w
    xorlw	0x09
    bz		portB_left

    portA:  ; ball moves in right direction
	tstfsz	p2_wins_round
	goto	_p1lose
	incf	ballcolumn
	movff	ballrow, LATB
	goto	isr_exit
    _p1lose:
	incf	p2_wins_round
	goto	isr_exit

    portB_right:  ; ball moves in right direction
    	incf	ballcolumn
	clrf	LATB
	movff	ballrow, LATC
	goto	isr_exit

    portC_right:  ; ball moves in right direction
    	incf	ballcolumn
	clrf	LATC
	movff	ballrow, LATD
    	goto	isr_exit

    portD_right:  ; ball moves in right direction
    	incf	ballcolumn
	clrf	LATD
	movff	ballrow, LATE
    	goto	isr_exit

    portE_right:  ; ball moves in right direction
    	incf	ballcolumn
	clrf	LATE
	movf	ballrow, w
	andwf	paddlepos_2, w
	btfsc	STATUS, Z
	incf	p1_wins_round
	movf	ballrow, w
	iorwf	LATF, f
    	goto	isr_exit

    portF:	  ; ball moves in left direction
	tstfsz	p1_wins_round
	goto	_p2lose
    	incf	ballcolumn
	movff	ballrow, LATE
    	goto	isr_exit
    _p2lose:
	incf	p1_wins_round
	goto	isr_exit


    portE_left:  ; ball moves in left direction
    	incf	ballcolumn
	clrf	LATE
	movff	ballrow, LATD
    	goto	isr_exit

    portD_left:  ; ball moves in left direction
    	incf	ballcolumn
	clrf	LATD
	movff	ballrow, LATC
    	goto	isr_exit

    portC_left:  ; ball moves in left direction
    	incf	ballcolumn
	clrf	LATC
	movff	ballrow, LATB
    	goto	isr_exit

    portB_left:  ; ball moves in left direction
    	clrf	ballcolumn
	clrf	LATB
	movf	ballrow, w
	andwf	paddlepos_1, w
	btfsc	STATUS, Z
	incf	p2_wins_round
	movf	ballrow, w
	iorwf	LATA, f
    	goto	isr_exit

isr_exit:
    retfie

rg0_task:
    tstfsz  state_rg0	        ; check if previously unpressed
    goto    _pressed_0
    btfss   PORTG, 0
    return
    comf    state_rg0, f	; state changed to pressed

    btfss   paddlepos_2, 5	; check for boundary condition
    rlncf   paddlepos_2, f	; move the paddle down

    movff   paddlepos_2, LATF
    return

_pressed_0:
    btfsc   PORTG, 0
    return
    comf    state_rg0, f	; state changed to unpressed
    return

rg1_task:
    tstfsz  state_rg1	        ; check if previously unpressed
    goto    _pressed_1
    btfss   PORTG, 1
    return
    comf    state_rg1, f	; state changed to pressed

    btfss   paddlepos_2, 0	; check for boundary condition
    rrncf   paddlepos_2, f	; move the paddle up

    movff   paddlepos_2, LATF
    return

_pressed_1:
    btfsc   PORTG, 1
    return
    comf    state_rg1, f	; state changed to unpressed
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rg2_task:
    tstfsz  state_rg2	        ; check if previously unpressed
    goto    _pressed_2
    btfss   PORTG, 2
    return
    comf    state_rg2, f	; state changed to pressed

    btfss   paddlepos_1, 5	; check for boundary condition
    rlncf   paddlepos_1, f	; move the paddle down

    movff   paddlepos_1, LATA
    return

_pressed_2:
    btfsc   PORTG, 2
    return
    comf    state_rg2, f	; state changed to unpressed
    return

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
rg3_task:
    tstfsz  state_rg3	        ; check if previously unpressed
    goto    _pressed_3
    btfss   PORTG, 3
    return
    comf    state_rg3, f	; state changed to pressed

    btfss   paddlepos_1, 0	; check for boundary condition
    rrncf   paddlepos_1, f	; move the paddle up

    movff   paddlepos_1, LATA
    return

_pressed_3:
    btfsc   PORTG, 3
    return
    comf    state_rg3, f	; state changed to unpressed
    return

END
