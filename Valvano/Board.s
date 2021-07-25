; Board.s
; Runs on TM4C1294
; Provide functions that initialize two negative logic switches
; on PJ0 and PJ1 and four positive logic LEDs on PN1, PN0, PF4,
; and PF0.  The negative logic switches use internal pull-up
; resistors.
; Use bit-banded I/O.
; Daniel and Jonathan Valvano
; April 30, 2014

;  This example accompanies the book
;  "Embedded Systems: Introduction to Arm Cortex M Microcontrollers"
;  ISBN: 978-1469998749, Jonathan Valvano, copyright (c) 2014
;  Section 4.2.2, Program 4.2, Figure 4.9
;
;  "Embedded Systems: Real Time Interfacing to ARM Cortex M Microcontrollers",
;  ISBN: 978-1463590154, Jonathan Valvano, copyright (c) 2014
;  Example 2.3, Program 2.9, Figure 2.36
;
;Copyright 2014 by Jonathan W. Valvano, valvano@mail.utexas.edu
;   You may use, edit, run or distribute this file
;   as long as the above copyright notice remains
;THIS SOFTWARE IS PROVIDED "AS IS".  NO WARRANTIES, WHETHER EXPRESS, IMPLIED
;OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, IMPLIED WARRANTIES OF
;MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE APPLY TO THIS SOFTWARE.
;VALVANO SHALL NOT, IN ANY CIRCUMSTANCES, BE LIABLE FOR SPECIAL, INCIDENTAL,
;OR CONSEQUENTIAL DAMAGES, FOR ANY REASON WHATSOEVER.
;For more information about my classes, my research, and my books, see
;http://users.ece.utexas.edu/~valvano/

; negative logic switches connected to PJ0 and PJ1 on the Connected LaunchPad
; positive logic LED1 connected to PN1 on the Connected LaunchPad
; positive logic LED2 connected to PN0 on the Connected LaunchPad
; positive logic LED3 connected to PF4 on the Connected LaunchPad (also Ethernet TX/RX activity)
; positive logic LED4 connected to PF0 on the Connected LaunchPad (also Ethernet link OK)

GPIO_PORTF_DATA_R             EQU 0x4005D3FC
GPIO_PORTF_DIR_R              EQU 0x4005D400
GPIO_PORTF_AFSEL_R            EQU 0x4005D420
GPIO_PORTF_DEN_R              EQU 0x4005D51C
GPIO_PORTF_AMSEL_R            EQU 0x4005D528
GPIO_PORTF_PCTL_R             EQU 0x4005D52C
PF0                           EQU 0x4005D004
PF4                           EQU 0x4005D040
LED34                         EQU 0x4005D044
LED3_ON                       EQU 0x10  ; value written to location PF4 or LED34 to turn on LED3
LED4_ON                       EQU 0x01  ; value written to location PF0 or LED34 to turn on LED4
GPIO_PORTJ_DATA_R             EQU 0x400603FC
GPIO_PORTJ_DIR_R              EQU 0x40060400
GPIO_PORTJ_AFSEL_R            EQU 0x40060420
GPIO_PORTJ_PUR_R              EQU 0x40060510
GPIO_PORTJ_DEN_R              EQU 0x4006051C
GPIO_PORTJ_AMSEL_R            EQU 0x40060528
GPIO_PORTJ_PCTL_R             EQU 0x4006052C
PJ0                           EQU 0x40060004
PJ1                           EQU 0x40060008
SWITCHES                      EQU 0x4006000C
SW1_PRESSED                   EQU 0x02  ; value read from location SWITCHES when just SW1 is pressed
SW2_PRESSED                   EQU 0x01  ; value read from location SWITCHES when just SW2 is pressed
BOTH_PRESSED                  EQU 0x00  ; value read from location SWITCHES when both switches are pressed
NO_PRESSED                    EQU 0x03  ; value read from location SWITCHES when neither switch is pressed
GPIO_PORTN_DATA_R             EQU 0x400643FC
GPIO_PORTN_DIR_R              EQU 0x40064400
GPIO_PORTN_AFSEL_R            EQU 0x40064420
GPIO_PORTN_DEN_R              EQU 0x4006451C
GPIO_PORTN_AMSEL_R            EQU 0x40064528
GPIO_PORTN_PCTL_R             EQU 0x4006452C
PN0                           EQU 0x40064004
PN1                           EQU 0x40064008
LED12                         EQU 0x4006400C
LED1_ON                       EQU 0x02  ; value written to location PN1 or LED12 to turn on LED1
LED2_ON                       EQU 0x01  ; value written to location PN0 or LED12 to turn on LED2
SYSCTL_RCGCGPIO_R             EQU 0x400FE608
SYSCTL_RCGCGPIO_R12           EQU 0x00001000  ; GPIO Port N Run Mode Clock Gating Control
SYSCTL_RCGCGPIO_R8            EQU 0x00000100  ; GPIO Port J Run Mode Clock Gating Control
SYSCTL_RCGCGPIO_R5            EQU 0x00000020  ; GPIO Port F Run Mode Clock Gating Control
SYSCTL_PRGPIO_R               EQU 0x400FEA08
SYSCTL_PRGPIO_R12             EQU 0x00001000  ; GPIO Port N Peripheral Ready
SYSCTL_PRGPIO_R8              EQU 0x00000100  ; GPIO Port J Peripheral Ready
SYSCTL_PRGPIO_R5              EQU 0x00000020  ; GPIO Port F Peripheral Ready

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Board_Init
        EXPORT  Board_Input
        EXPORT  Board_Output

;------------Board_Init------------
; Initialize GPIO Port J for negative logic switches on PJ1-0
; as the Connected LaunchPad is wired.  Weak internal pull-up
; resistors are enabled.  Initialize GPIO Port F and Port N
; for the LEDs.
; Input: none
; Output: none
; Modifies: R0, R1
Board_Init
    ; initialize negative logic switches on PJ0 and PJ1
    ; activate clock for Port J
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #SYSCTL_RCGCGPIO_R8 ; R0 = R0|SYSCTL_RCGCGPIO_R8
    STR R0, [R1]                    ; [R1] = R0
    ; allow time for clock to stabilize
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
boardJinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R8  ; R0 = R0&SYSCTL_PRGPIO_R8
    BEQ boardJinitloop              ; if(R0 == 0), keep polling
    ; set direction register
    LDR R1, =GPIO_PORTJ_DIR_R       ; R1 = GPIO_PORTJ_DIR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x03               ; R0 = R0&~0x03 (make PJ1-0 in (PJ1-0 built-in SW2-1))
    STR R0, [R1]                    ; [R1] = R0
    ; set alternate function register
    LDR R1, =GPIO_PORTJ_AFSEL_R     ; R1 = GPIO_PORTJ_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x03               ; R0 = R0&~0x03 (disable alt funct on PJ1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; set pull-up register
    LDR R1, =GPIO_PORTJ_PUR_R       ; R1 = GPIO_PORTJ_PUR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable pull-up on PJ1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; set digital enable register
    LDR R1, =GPIO_PORTJ_DEN_R       ; R1 = GPIO_PORTJ_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable digital I/O on PJ1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; set port control register
    LDR R1, =GPIO_PORTJ_PCTL_R      ; R1 = GPIO_PORTJ_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x000000FF         ; R0 = R0&0xFFFFFF00 (clear bit1-0 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PJ1-0 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
    ; set analog mode select register
    LDR R1, =GPIO_PORTJ_AMSEL_R     ; R1 = GPIO_PORTJ_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x03               ; R0 = R0&~0x03 (disable analog functionality on PJ1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; initialize positive logic LED1-2 on PN1-0
    ; activate clock for Port N
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #SYSCTL_RCGCGPIO_R12; R0 = R0|SYSCTL_RCGCGPIO_R12
    STR R0, [R1]                    ; [R1] = R0
    ; allow time for clock to stabilize
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
boardNinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R12 ; R0 = R0&SYSCTL_PRGPIO_R12
    BEQ boardNinitloop              ; if(R0 == 0), keep polling
    ; set direction register
    LDR R1, =GPIO_PORTN_DIR_R       ; R1 = GPIO_PORTN_DIR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (make PN1-0 out (PN1-0 built-in LED1-2))
    STR R0, [R1]                    ; [R1] = R0
    ; set alternate function register
    LDR R1, =GPIO_PORTN_AFSEL_R     ; R1 = GPIO_PORTN_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x03               ; R0 = R0&~0x03 (disable alt funct on PN1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; set digital enable register
    LDR R1, =GPIO_PORTN_DEN_R       ; R1 = GPIO_PORTN_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x03               ; R0 = R0|0x03 (enable digital I/O on PN1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; set port control register
    LDR R1, =GPIO_PORTN_PCTL_R      ; R1 = GPIO_PORTN_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x000000FF         ; R0 = R0&0xFFFFFF00 (clear bit1-0 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PN1-0 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
    ; set analog mode select register
    LDR R1, =GPIO_PORTN_AMSEL_R     ; R1 = GPIO_PORTN_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x03               ; R0 = R0&~0x03 (disable analog functionality on PN1-0)
    STR R0, [R1]                    ; [R1] = R0
    ; initialize positive logic LED3-4 on PF4,0
    ; activate clock for Port F
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #SYSCTL_RCGCGPIO_R5 ; R0 = R0|SYSCTL_RCGCGPIO_R5
    STR R0, [R1]                    ; [R1] = R0
    ; allow time for clock to stabilize
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
boardFinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R5  ; R0 = R0&SYSCTL_PRGPIO_R5
    BEQ boardFinitloop              ; if(R0 == 0), keep polling
    ; set direction register
    LDR R1, =GPIO_PORTF_DIR_R       ; R1 = GPIO_PORTF_DIR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x11               ; R0 = R0|0x11 (make PF0 and PF4 out (PF4,0 built-in LED3-4))
    STR R0, [R1]                    ; [R1] = R0
    ; set alternate function register
    LDR R1, =GPIO_PORTF_AFSEL_R     ; R1 = GPIO_PORTF_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x11               ; R0 = R0&~0x11 (disable alt funct on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; set digital enable register
    LDR R1, =GPIO_PORTF_DEN_R       ; R1 = GPIO_PORTF_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x11               ; R0 = R0|0x11 (enable digital I/O on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    ; set port control register
    LDR R1, =GPIO_PORTF_PCTL_R      ; R1 = GPIO_PORTF_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x000F000F         ; R0 = R0&~0x000F000F (clear bit4,0 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PF0 and PF4 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
    ; set analog mode select register
    LDR R1, =GPIO_PORTF_AMSEL_R     ; R1 = GPIO_PORTF_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x11               ; R0 = R0&~0x11 (disable analog functionality on PF0 and PF4)
    STR R0, [R1]                    ; [R1] = R0
    BX  LR                          ; return

;------------Board_Input------------
; Read and return the status of the switches.
; Input: none
; Output: 0x02 if only Switch 1 is pressed
;         0x01 if only Switch 2 is pressed
;         0x00 if both switches are pressed
;         0x03 if no switches are pressed
; Assumes: Board_Init() has already been called
; Modifies: R1
Board_Input
    LDR R1, =SWITCHES               ; R1 = &SWITCHES (pointer to location of PJ0 and PJ1)
    LDR R0, [R1]                    ; R0 = [R1] (read PJ0 and PJ1)
    BX  LR                          ; return

;------------Board_Output------------
; Set the status of the LEDs.
; Input: R0  4-bit new status of LED1-4
; Output: none
; Assumes: Board_Init() has already been called
; Modifies: R1, R2
Board_Output
    ; test bit 0
    ANDS  R1, R0, #0x01             ; R1 = R0&0x01 (temp = data&0x01)
    ITE   EQ                        ; next two instructions are conditional
    MOVEQ R2, #0                    ; if((data&0x01) == 0), R2 = 0
    MOVNE R2, #LED1_ON              ; if((data&0x01) != 0), R2 = LED1_ON
    LDR   R1, =PN1                  ; R1 = PN1 (pointer)
    STR   R2, [R1]                  ; [R1] = R2
    ; test bit 1
    ANDS  R1, R0, #0x02             ; R1 = R0&0x02 (temp = data&0x02)
    ITE   EQ                        ; next two instructions are conditional
    MOVEQ R2, #0                    ; if((data&0x02) == 0), R2 = 0
    MOVNE R2, #LED2_ON              ; if((data&0x02) != 0), R2 = LED2_ON
    LDR   R1, =PN0                  ; R1 = PN0 (pointer)
    STR   R2, [R1]                  ; [R1] = R2
    ; test bit 2
    ANDS  R1, R0, #0x04             ; R1 = R0&0x04 (temp = data&0x04)
    ITE   EQ                        ; next two instructions are conditional
    MOVEQ R2, #0                    ; if((data&0x04) == 0), R2 = 0
    MOVNE R2, #LED3_ON              ; if((data&0x04) != 0), R2 = LED3_ON
    LDR   R1, =PF4                  ; R1 = PF4 (pointer)
    STR   R2, [R1]                  ; [R1] = R2
    ; test bit 3
    ANDS  R1, R0, #0x08             ; R1 = R0&0x08 (temp = data&0x08)
    ITE   EQ                        ; next two instructions are conditional
    MOVEQ R2, #0                    ; if((data&0x08) == 0), R2 = 0
    MOVNE R2, #LED4_ON              ; if((data&0x08) != 0), R2 = LED4_ON
    LDR   R1, =PF0                  ; R1 = PF0 (pointer)
    STR   R2, [R1]                  ; [R1] = R2
    BX    LR                        ; return

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
