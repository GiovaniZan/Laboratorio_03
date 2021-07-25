        PUBLIC  __iar_program_start
        PUBLIC  __vector_table

     
        SECTION .noinit:DATA(2) ;,0x20000000 ; início da RAM
        DATA
EBAt    DS32  1
EBAnt   DS32  1
CBo     DS32  1

        SECTION .text:CODE:REORDER(2)
        
        ;; Keep vector table even if it's not referenced
        REQUIRE __vector_table
        
        THUMB
 

//        
//        Exercício 18
//•
//Utilize o projeto do Exercício 17 como base
//para um novo programa que incremente uma
//contagem binária nos LEDs do kit a cada
//pressionamento do botão SW1 e decremente
//a cada pressionamento do botão SW2
//•
//Sugestão:
//–
//Pesquise e idealize uma sub rotina que faça
//debounce dos botões por software e retorne
//os seus estados para o programa principal
        
        
//
// led1 - PN1
// led2 - PN0
// led3 - PF4
// led4 - PF0




__iar_program_start

SYSCTL_RCGCGPIO_R       EQU     0x400FE608
SYSCTL_PRGPIO_R		EQU     0x400FEA08
PORTN_BIT               EQU     1000000000000b ; bit 12 = Port N
PORTF_BIT               EQU     0000000100000b ; bit  5 = Port F
PORTJ_BIT               EQU     0000100000000b ; bit  8 = Port F
LEDMASK_PORT_N          EQU     00000011b
LEDMASK_PORT_F          EQU     00010001b


// endereços básicos da porta N
GPIO_PORTN_DATA_R    	EQU     0x40064000
GPIO_PORTN_DIR_R     	EQU     0x40064400
GPIO_PORTN_DEN_R     	EQU     0x4006451C

//endereços básicos da porta F
GPIO_PORTF_DATA_R    	EQU     0x4005D000
GPIO_PORTF_DIR_R     	EQU     0x4005D400
GPIO_PORTF_DEN_R     	EQU     0x4005D51C


//endereços básicos da porta J
GPIO_PORTJ_DATA_R    	EQU     0x40060000
GPIO_PORTJ_DIR_R     	EQU     0x40060400
GPIO_PORTJ_PUR_R     	EQU     0x40060510
GPIO_PORTJ_DEN_R     	EQU     0x4006051C

NOVACONTAGEM EQU 0x00000001
NOVOBOTAO EQU 0x00000002
NOVOBOTAOVALIDO EQU 0x00000004

ContagensParaBotaoValido EQU 60 ; ajusta a velocidade de resposta do botão quanto maior, mais lento. Unidades de 10ms
        
        

// inicializa as portas
// contagem de tempo para 500ms realizado no registrador R0
// a cada 200ms atualiza os leds de acordo com o estado 
// dos botões

// usa R0 para armazenar contador
// usa R1 para contar unidades de tempo de atraso
// Usa R2 como Flags para ações
// USA r3 PARA COMPARAÇÕES

      

main    

        //LDR R0, =Iniciais ; ponteiro de origem
        MOV R0, #0
        LDR R3, =EBAnt
        STR R0,[R3, #0]
        LDR R3, =EBAt
        STR R0,[R3, #0]
        LDR R3, =CBo
        STR R0,[R3, #0]
        
        BL inicializacaoPortas
        
        MOV R0, #0 ; UTILIZADO COMO CONTADOR de estado
        MOV R1, #0 ; UTILIZADO COMO CONTADOR de unidades de atraso
        MOV R2, #5 ; UTILIZADO COMO flag para ações do programa
main_loop


        BL debounceBotoes
        //ADD R0, #1 ; adiciona 1 ao contador
        
        TEQ R2, #NOVOBOTAOVALIDO
        BNE cont2
        BL atualizaContador
        orr R4,  R2, #NOVACONTAGEM
        and R4, #NOVACONTAGEM

cont2
        
        TEQ R4, #NOVACONTAGEM ; // CHECA SE HOUVE ALTERAÇÃO DA CONTAGEM
        BNE cont1
        BL AtualizaLeds ;
cont1
        BIC R2, #NOVACONTAGEM ; // LIMPA FLAG DA CONTAGEM
        BL rotinaDeAtraso

        B main_loop
//        B       main


/////// ROTINA PARA DEBOUNCE DE BOTÕES /////////
debounceBotoes
        PUSH {R0-R1}
        PUSH {R3-R10}
        
        LDR R3, =CBo
        LDR R6, [R3, #0]
        LDR R3, =EBAt
        LDR R5, [R3, #0]
        LDR R3, =EBAnt
        STR R5, [R3, #0] ; ATUALIZA estado de botão
        
        LDR R1, = GPIO_PORTJ_DATA_R
        MOV R9, #0x00C
        LDR R10, [R1, R9] ; LÊ PORTA j COM MASCARAMENTO
  //      MVN R10, R10
  //      AND R10, #3
        EOR R10, #3
        LDR R3, =EBAt
        STR R10, [R3, #0] ; 
        
                // verifica se o estado é nulo - (teclas liberadas)
        CMP R10, #0
        BEQ debounceBotoes_botoes_soltos
        
        
        CMP R5,R10 ; COMPARA SE HOUVE ALTERAÇÃO
        ITE EQ
        ADDEQ R6, #1
        MOVNE R6, #0 ; ZERA R6
        
        CMP R6, #ContagensParaBotaoValido // ajuste de velocidade de resposta
        ITTE EQ
        EOREQ R2, #NOVOBOTAOVALIDO
        EOREQ R6,R6 ; ZERA R6
        BICNE R2, #NOVOBOTAOVALIDO
        
        LDR R3, =EBAt
        STR R10, [R3, #0]

        B debounceBotoes_saida

debounceBotoes_botoes_soltos
        MOV R6,#0 ; ZERA R6
        BIC R2, #NOVOBOTAOVALIDO
        LDR R3, =EBAt
        STR R10, [R3, #0] ; 

        
debounceBotoes_saida
        LDR R3, =CBo
        STR R6, [R3, #0]

        POP {R3-R10}
        POP {R0-R1}
        
        BX LR
////////////////////////////////////////

/////// ROTINA PARA ATUALIZAR CONTADOR /////////////

atualizaContador
        PUSH {R1-R10}
 
        LDR R3, =EBAt
        LDR R5, [R3, #0]
        
        TEQ R5, #3
        BEQ atualizaContador_Fim


        CMP R5, #2
        BNE atualizaContador_teste2
        ADD R0, #1
        
atualizaContador_teste2        
        CMP R5, #1
        BNE atualizaContador_Fim
        SUB r0, #1
        
atualizaContador_Fim
 
 
        POP {R1-R10}
        BX LR

////////////////////////////////////






//////// rotina de atraso/////////
///// 10-ms /////// para o debounce ///
rotinaDeAtraso
        PUSH {R1-R10}
        //MOVT R3, #0x000F ; constante de atraso 
        MOV R3, #0x3E80
rotinaDeAtraso_delay   CBZ R3, rotinaDeAtraso_theend ; 1 clock
        SUB R3, R3, #1 ; 1 clock
        B rotinaDeAtraso_delay ; 3 clocks
rotinaDeAtraso_theend  //EOR R1, R1, R2 ; troca o estado
        POP {R1-R10}
        BX LR
////////  fim da rotina de atraso/////////



////////////// rotina de atualização dos leds ///////////////////
// rotina de atualização de leds, conformecontador em R0
AtualizaLeds
// L4  L3  L2  L1  -> SEQUENCIADE LEDS  
// F0  F4  N0  N1  -> PORTA
// B3  B2  B1  B0  -> BIT DO CONTADOR
// B0  B4  B0  B1  -> BIT NA PORTA
        PUSH {R1-R10}
        PUSH {LR}
        MOV R2, #1
        MOV R3, #2
        MOV R4, #16
       // MOV R5, #0X08

        // PREPARA REGISTRADORES PARA PORTA N
        AND R6, R2, R0, LSR #1 ; DETERMINA O LED 0 - PN1 
        AND R7, R3, R0, LSL #1 ; DETERMINA O LED 1 - PN0
        ORR R7, R7, R6
        LDR R1, = GPIO_PORTN_DATA_R
        MVN R8, #LEDMASK_PORT_N
        BL AtualizaLedsPorta_X

 //       ORR R7, R7 ; LIMPA R7
  //      ORR R6,R6
        AND R6, R4 ,R0, LSL #2 ; DETERINA O LED 2 - PF4
        AND R7, R2, R0, LSR #3 ; DETERMINA O LED 3 - PF0
        ORR R7, R7, R6
        LDR R1, = GPIO_PORTF_DATA_R
        MVN R8, #LEDMASK_PORT_F
        BL AtualizaLedsPorta_X

        POP {LR}
        POP {R1-R10}
        BX LR


AtualizaLedsPorta_X ; Leds D1, D2
        MOV R9, #0x3FC
        LDR R10, [R1, R9]
        AND R10, R8 // ELIMINA OS BITS NÃO ENVOLVIDOS
        ORR R10, R7 // AJUSTA OS BITS ADEQUADOS
        STR R10, [R1, R9]
        BX LR

////////////// fim da rotina de atualização dos leds ///////////////////


////////// rotina de inicialiação das portas ///////////////
// inicializa portas utilizadas
inicializacaoPortas
        PUSH {R0-R10} // JUST IN CASE...
        
        MOV R2, #PORTN_BIT
        ORR R2, R2, #PORTF_BIT 
         LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ;   habilita port N , F e J
	STR R1, [R0] ; escrita do novo estado

        LDR R0, =SYSCTL_PRGPIO_R   // aguarda estabilização daporta N
inicializacaoPortas_wait_NF
        LDR R2, [R0] ; leitura do estado atual
	TEQ R1, R2 ; clock do port N , F e J habilitado?
	BNE inicializacaoPortas_wait_NF ; caso negativo, aguarda
        
        
      
        
        
        
        
        // prepara porta N - N1 e N0 como output
        MOV R2, #00000011b ; bit 0
        
        // habilita bit zero da porta N como saída N0=out
	LDR R0, =GPIO_PORTN_DIR_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; bit de saída
	STR R1, [R0] ; escrita do novo estado

        //habilita porta N como digital
	LDR R0, =GPIO_PORTN_DEN_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita função digital
	STR R1, [R0] ; escrita do novo estado

        // INICIALIZA PORTA N, escreve sem ler antes
        MOV R4, #0
        LDR R0, = GPIO_PORTN_DATA_R
        MOV R2, #0x3FC ; deslocamento para acesso sem mascaramento
        STR R4, [R0, R2]; coloca na porta Nsem mascaramento, o registrador R4

        // prepara porta F - F4 e F0 como output
        MOV R2, #00010001b ; bit 0

        // habilita bit zero da porta F como saída N0=out
	LDR R0, =GPIO_PORTF_DIR_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; bit de saída
	STR R1, [R0] ; escrita do novo estado

        //habilita porta F como digital
	LDR R0, =GPIO_PORTF_DEN_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita função digital
	STR R1, [R0] ; escrita do novo estado

     // INICIALIZA PORTA F, escreve sem ler antes
    //  MOV R4, #0
        LDR R0, = GPIO_PORTF_DATA_R
    //  MOV R2, #0x3FC ; deslocamento para acesso sem mascaramento
        STR R4, [R0, R2]; coloca na porta Nsem mascaramento, o registrador R4


        // prepara porta J - J1 e J0 como input
        MOV R2, #PORTJ_BIT 
        LDR R0, =SYSCTL_RCGCGPIO_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ;   habilita port  J
	STR R1, [R0] ; escrita do novo estado

        LDR R0, =SYSCTL_PRGPIO_R   // aguarda estabilização daporta N
inicializacaoPortas_wait_J
        LDR R2, [R0] ; leitura do estado atual
	TEQ R1, R2 ; clock do port  J habilitado?
	BNE inicializacaoPortas_wait_J ; caso negativo, aguarda

        // habilita bit zero da porta J como input J0 = J1 = input
        MOV R2, #0
//        LDR R0, =GPIO_PORTJ_DIR_R
//	LDR R1, [R0] ; leitura do estado anterior
//	STR R2, [R0] ; escrita do novo estado

        LDR R0, =GPIO_PORTJ_DIR_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; bit de saída
	STR R1, [R0] ; escrita do novo estado

        MOV R2, #00000011b ; bit 0
        //habilita porta J como digital
	LDR R0, =GPIO_PORTJ_DEN_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita função digital
	STR R1, [R0] ; escrita do novo estado

        //habilita Pull Ups na porta J
	LDR R0, =GPIO_PORTJ_PUR_R
	LDR R1, [R0] ; leitura do estado anterior
	ORR R1, R2 ; habilita função digital
	STR R1, [R0] ; escrita do novo estado

        // INICIALIZA PORTA J, escreve sem ler antes
        MOV R4, #0
        LDR R0, = GPIO_PORTJ_DATA_R
        MOV R2, #0x3FC ; deslocamento para acesso sem mascaramento
        STR R4, [R0, R2]; coloca na porta Nsem mascaramento, o registrador R4

        POP {R0-R10}
        BX LR
////////// fim da  rotina de inicialiação das portas ///////////////





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; seção de constantes em ROM
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

        SECTION .rodata:CONST(2)
        DATA
Iniciais   DC32 0,0,0

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; seção de variáveis não inicializadas em RAM
;; ver arquivo de configuração do linker (my_cortex.icf)
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

//        //ASEGN .bss:DATA(2),0x20000000 ; início da RAM  //  Fatal Error[Lp049]: there was no reference to __iar_data_init3, but it is needed to initialize section bss (asm.o #8)   
//// ASEGN é um label???
// //       minhasvariaveis bss:DATA(2),0x20000000 ; início da RAM  // resulta em bad instruction
// //       SECTION MYVARS :DATA(2) //  Fatal Error[Lp049]: there was no reference to __iar_data_init3, but it is needed to initialize section MYVARS (asm.o #8)   
//  //      SECTION MYVARS :DATA(2) ,0x20000000 //  Fatal Error[Lp049]: there was no reference to __iar_data_init3, but it is needed to initialize section MYVARS (asm.o #8)   
//        section .bss:DATA(2),0x20000000 ; início da RAM  // Fatal Error[Lp049]: there was no reference to __iar_data_init3, but it is needed to initialize section .bss (asm.o #8)   
//

//__iar_data_init3
//          section  minhasvariaveis:DATA(2)    
//          DATA
//EstadoBotoesAnterior   DS32 1 ; estado anterior
//EstadoBotoesAtual      DS32 1 ; estado atual
//contadorBotao          DS32 1 ;


//
//EstadoBotoesAnterior   .bss DS32 1 ; estado anterior
//EstadoBotoesAtual      .bss DS32 1 ; estado atual
//contadorBotao          .bss DS32 1 ;



//        ASEGN .bss:DATA(2),0x20000000 ; início da RAM
//        DATA
////EstadoBotoesAnterior   DS32 1
////EstadoBotoesAtual   DS32  1
////contadorBotao   DS32  1
//EBAt   DS32 1
//EBAnt   DS32  1
//CBo   DS32  1

         ;; Forward declaration of sections.
        SECTION CSTACK:DATA:NOROOT(3)
        SECTION .intvec:CODE:NOROOT(2)
        
        DATA

__vector_table
        DCD     sfe(CSTACK)
        DCD     __iar_program_start

        DCD     NMI_Handler
        DCD     HardFault_Handler
        DCD     MemManage_Handler
        DCD     BusFault_Handler
        DCD     UsageFault_Handler
        DCD     0
        DCD     0
        DCD     0
        DCD     0
        DCD     SVC_Handler
        DCD     DebugMon_Handler
        DCD     0
        DCD     PendSV_Handler
        DCD     SysTick_Handler

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; Default interrupt handlers.
;;

        PUBWEAK NMI_Handler
        PUBWEAK HardFault_Handler
        PUBWEAK MemManage_Handler
        PUBWEAK BusFault_Handler
        PUBWEAK UsageFault_Handler
        PUBWEAK SVC_Handler
        PUBWEAK DebugMon_Handler
        PUBWEAK PendSV_Handler
        PUBWEAK SysTick_Handler

        SECTION .text:CODE:REORDER:NOROOT(1)
        THUMB

NMI_Handler
HardFault_Handler
MemManage_Handler
BusFault_Handler
UsageFault_Handler
SVC_Handler
DebugMon_Handler
PendSV_Handler
SysTick_Handler
Default_Handler
__default_handler
        CALL_GRAPH_ROOT __default_handler, "interrupt"
        NOCALL __default_handler
        B __default_handler

        END
