; SwitchTestMain.s
; Runs on TM4C1294
; Test the switch initialization functions by setting the LED
; status according to the status of the switches.
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
; positive logic external switch connected to PA5 with external pull-down resistor
; positive logic LED1 connected to PN1 on the Connected LaunchPad
; positive logic LED2 connected to PN0 on the Connected LaunchPad
; positive logic LED3 connected to PF4 on the Connected LaunchPad (also Ethernet TX/RX activity)
; positive logic LED4 connected to PF0 on the Connected LaunchPad (also Ethernet link OK)

        IMPORT  Switch_Init
        IMPORT  Switch_Input
        IMPORT  Board_Init
        IMPORT  Board_Input
        IMPORT  Board_Output

        AREA    |.text|, CODE, READONLY, ALIGN=2
        THUMB
        EXPORT  Start
Start
    BL  Switch_Init                 ; PA5 is input
    BL  Board_Init                  ; initialize built-in switches and LEDs
loop
    BL  Board_Input                 ; Switch 1 in bit 0 of R0, Switch 2 in bit 1 of R0
    MVN R0, R0                      ; R0 = ~R0 (invert R0 for negative logic switches)
    AND R4, R0, #0x01               ; R4 = R0&0x01 (Switch 1 in bit 0 of R4)
    LSR R5, R0, #1                  ; R5 = R0>>1
    AND R5, R5, #0x01               ; R5 = R5&0x01 (Switch 2 in bit 0 of R5)
    BL  Switch_Input                ; external switch in bit 5 of R0
    LSR R6, R0, #5                  ; R6 = R0>>5 (external switch in bit 0 of R6)
    AND R0, R4, R5                  ; R0 = R4&R5 (Switch 1 & Switch 2)
    AND R0, R0, R6                  ; R0 = R0&R6 (Switch 1 & Switch 2 & external switch)
    LSL R0, R0, #3                  ; R0 = R0<<3 (pressing all three switches sets bit 3 of R0)
    LSL R1, R6, #2                  ; R1 = R6<<2 (external switch in bit 2 of R1)
    ORR R0, R0, R1                  ; R0 = R0|R1 (pressing external switch sets bit 2 of R0)
    LSL R1, R5, #1                  ; R1 = R5<<1 (Switch 2 in bit 1 of R1)
    ORR R0, R0, R1                  ; R0 = R0|R1 (pressing Switch 2 sets bit 1 of R0)
    ORR R0, R0, R4                  ; R0 = R0|R4 (pressing Switch 1 sets bit 0 of R0)
    BL  Board_Output                ; update LEDs
    B   loop

    ALIGN                           ; make sure the end of this section is aligned
    END                             ; end of file
