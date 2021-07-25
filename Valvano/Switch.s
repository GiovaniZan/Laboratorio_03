; Switch.s
; Runs on TM4C1294
; Provide functions that initialize a GPIO as an input pin for
; a positive logic external switch on PA5 using an external
; pull-down resistor.
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

; positive logic external switch connected to PA5 with external pull-down resistor

GPIO_PORTA_DATA_R             EQU 0x400583FC
GPIO_PORTA_DIR_R              EQU 0x40058400
GPIO_PORTA_AFSEL_R            EQU 0x40058420
GPIO_PORTA_DEN_R              EQU 0x4005851C
GPIO_PORTA_AMSEL_R            EQU 0x40058528
GPIO_PORTA_PCTL_R             EQU 0x4005852C
PA5                           EQU 0x40058080
PA5_SW_PRESSED                EQU 0x20  ; value read from location PA5 when external switch is pressed
PA5_SW_NO_PRESSED             EQU 0x00  ; value read from location PA5 when external switch is released
SYSCTL_RCGCGPIO_R             EQU 0x400FE608
SYSCTL_RCGCGPIO_R0            EQU 0x00000001  ; GPIO Port A Run Mode Clock Gating Control
SYSCTL_PRGPIO_R               EQU 0x400FEA08
SYSCTL_PRGPIO_R0              EQU 0x00000001  ; GPIO Port A Peripheral Ready

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Switch_Init
        EXPORT  Switch_Input

;------------Switch_Init------------
; Initialize GPIO Port A bit 5 as input
; Input: none
; Output: none
; Modifies: R0, R1
Switch_Init
    ; 1) activate clock for Port A
    LDR R1, =SYSCTL_RCGCGPIO_R      ; R1 = SYSCTL_RCGCGPIO_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #SYSCTL_RCGCGPIO_R0 ; R0 = R0|SYSCTL_RCGCGPIO_R0
    STR R0, [R1]                    ; [R1] = R0
    ; allow time for clock to stabilize
    LDR R1, =SYSCTL_PRGPIO_R        ; R1 = SYSCTL_PRGPIO_R (pointer)
switchinitloop
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ANDS R0, R0, #SYSCTL_PRGPIO_R0  ; R0 = R0&SYSCTL_PRGPIO_R0
    BEQ switchinitloop              ; if(R0 == 0), keep polling
    ; 2) no need to unlock GPIO Port A
    ; 3) disable analog functionality on PA5
    LDR R1, =GPIO_PORTA_AMSEL_R     ; R1 = GPIO_PORTA_AMSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x20               ; R0 = R0&~0x20 (disable analog functionality on PA5)
    STR R0, [R1]                    ; [R1] = R0
    ; 4) configure PA5 as GPIO
    LDR R1, =GPIO_PORTA_PCTL_R      ; R1 = GPIO_PORTA_PCTL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x00F00000         ; R0 = R0&0xFF0FFFFF (clear bit5 field)
    ADD R0, R0, #0x00000000         ; R0 = R0+0x00000000 (configure PA5 as GPIO)
    STR R0, [R1]                    ; [R1] = R0
    ; 5) make PA5 input
    LDR R1, =GPIO_PORTA_DIR_R       ; R1 = GPIO_PORTA_DIR_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x20               ; R0 = R0&~0x20 (make PA5 input)
    STR R0, [R1]                    ; [R1] = R0
    ; 6) disable alt funct on PA5
    LDR R1, =GPIO_PORTA_AFSEL_R     ; R1 = GPIO_PORTA_AFSEL_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    BIC R0, R0, #0x20               ; R0 = R0&~0x20 (disable alt funct on PA5)
    STR R0, [R1]                    ; [R1] = R0
    ; 7) enable digital I/O on PA5
    LDR R1, =GPIO_PORTA_DEN_R       ; R1 = GPIO_PORTA_DEN_R (pointer)
    LDR R0, [R1]                    ; R0 = [R1] (value)
    ORR R0, R0, #0x20               ; R0 = R0|0x20 (enable digital I/O on PA5)
    STR R0, [R1]                    ; [R1] = R0
    BX  LR                          ; return

;------------Switch_Input------------
; Read and return the status of PA5
; Input: none
; Output: R0  0x20 if PA5 high
;         R0  0x00 if PA5 low
; Assumes: Switch_Init() has already been called
; Modifies: R1
Switch_Input
    LDR R1, =PA5      ; pointer to PA5
    LDR R0, [R1]      ; read just PA5
    BX  LR            ; 0x20 or 0x00

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
