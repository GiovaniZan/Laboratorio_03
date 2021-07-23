# Exercício 17

>  Utilize o projeto “ gpio ” como base para um
> novo programa que apresente uma contagem
> binária de 4 bits nos LEDs do kit
>
> - Sugestões:
>   - Estruture o programa com sub rotinas para
>     inicialização, configuração e operação das portas
>   - Crie uma sub rotina de atraso por software, com
>     base na estrutura já existente no projeto exemplo,
>     para temporizar a contagem binária nos LEDs





LED 

-  led1 - PN1 - bit 0
-  led2 - PN0 - bit 1
-  led3 - PF4 - bit 2
-  led4 - PF0 - bit 3

​      

Contador

- R0 = x x x x b3 b2 b1 b0



- PN0 = B1 = (r0 >>1) &1
- PN1= B0 = (r0 <<1) & 2                
- PF4 = B2 = (r0 << 2 ) & 16
- PF0 = B3 = (r0 >>3) & 1
- 