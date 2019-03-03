#include "p18F4550.inc"

; CONFIG1L
  CONFIG  PLLDIV = 1            ; PLL Prescaler Selection bits (No prescale (4 MHz oscillator input drives PLL directly))
  CONFIG  CPUDIV = OSC1_PLL2    ; System Clock Postscaler Selection bits ([Primary Oscillator Src: /1][96 MHz PLL Src: /2])
  CONFIG  USBDIV = 1            ; USB Clock Selection bit (used in Full-Speed USB mode only; UCFG:FSEN = 1) (USB clock source comes directly from the primary oscillator block with no postscale)

; CONFIG1H
  CONFIG  FOSC = INTOSC_XT      ; Oscillator Selection bits (Internal oscillator, XT used by USB (INTXT))
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

; CONFIG2L
  CONFIG  PWRT = OFF            ; Power-up Timer Enable bit (PWRT disabled)
  CONFIG  BOR = ON              ; Brown-out Reset Enable bits (Brown-out Reset enabled in hardware only (SBOREN is disabled))
  CONFIG  BORV = 3              ; Brown-out Reset Voltage bits (Minimum setting)
  CONFIG  VREGEN = OFF          ; USB Voltage Regulator Enable bit (USB voltage regulator disabled)

; CONFIG2H
  CONFIG  WDT = OFF             ; Watchdog Timer Enable bit (WDT disabled (control is placed on the SWDTEN bit))
  CONFIG  WDTPS = 32768         ; Watchdog Timer Postscale Select bits (1:32768)

; CONFIG3H
  CONFIG  CCP2MX = OFF          ; CCP2 MUX bit (CCP2 input/output is multiplexed with RB3)
  CONFIG  PBADEN = OFF          ; PORTB A/D Enable bit (PORTB<4:0> pins are configured as digital I/O on Reset)
  CONFIG  LPT1OSC = OFF         ; Low-Power Timer 1 Oscillator Enable bit (Timer1 configured for higher power operation)
  CONFIG  MCLRE = ON            ; MCLR Pin Enable bit (MCLR pin enabled; RE3 input pin disabled)

; CONFIG4L
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled)
  CONFIG  ICPRT = OFF           ; Dedicated In-Circuit Debug/Programming Port (ICPORT) Enable bit (ICPORT disabled)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; CONFIG5L
  CONFIG  CP0 = OFF             ; Code Protection bit (Block 0 (000800-001FFFh) is not code-protected)
  CONFIG  CP1 = OFF             ; Code Protection bit (Block 1 (002000-003FFFh) is not code-protected)
  CONFIG  CP2 = OFF             ; Code Protection bit (Block 2 (004000-005FFFh) is not code-protected)
  CONFIG  CP3 = OFF             ; Code Protection bit (Block 3 (006000-007FFFh) is not code-protected)

; CONFIG5H
  CONFIG  CPB = OFF             ; Boot Block Code Protection bit (Boot block (000000-0007FFh) is not code-protected)
  CONFIG  CPD = OFF             ; Data EEPROM Code Protection bit (Data EEPROM is not code-protected)

; CONFIG6L
  CONFIG  WRT0 = OFF            ; Write Protection bit (Block 0 (000800-001FFFh) is not write-protected)
  CONFIG  WRT1 = OFF            ; Write Protection bit (Block 1 (002000-003FFFh) is not write-protected)
  CONFIG  WRT2 = OFF            ; Write Protection bit (Block 2 (004000-005FFFh) is not write-protected)
  CONFIG  WRT3 = OFF            ; Write Protection bit (Block 3 (006000-007FFFh) is not write-protected)

; CONFIG6H
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) are not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot block (000000-0007FFh) is not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM is not write-protected)

; CONFIG7L
  CONFIG  EBTR0 = OFF           ; Table Read Protection bit (Block 0 (000800-001FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Table Read Protection bit (Block 1 (002000-003FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR2 = OFF           ; Table Read Protection bit (Block 2 (004000-005FFFh) is not protected from table reads executed in other blocks)
  CONFIG  EBTR3 = OFF           ; Table Read Protection bit (Block 3 (006000-007FFFh) is not protected from table reads executed in other blocks)

; CONFIG7H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protection bit (Boot block (000000-0007FFh) is not protected from table reads executed in other blocks)


    UDATA
MESSAGE_READY RES 1
RC_BUFFER   RES 1

;       ALL THIS DOES IS RECEIVE A UART MESSAGE AND SHOW IT ON THE LEDS ON PORT D

RST ORG 0X00
    GOTO INIT



ISR ORG 0X08
    BANKSEL PORTD
    INCF    PORTD
ISR_FIND_SOURCE
    BANKSEL PIR1
    BTFSC   PIR1, RCIF
    GOTO    ISR_HANDLE_RCIF
    BTFSC   PIR1, TXIF
    GOTO    ISR_HANDLE_TXIF

ISR_HANDLE_RCIF
    BANKSEL RCSTA
    BCF     RCSTA, CREN

    BANKSEL PIR1
    BCF     PIR1, RCIF

    BANKSEL RCREG
    MOVF    RCREG, 0
    BANKSEL RC_BUFFER
    MOVWF   RC_BUFFER
    BANKSEL MESSAGE_READY
    SETF    MESSAGE_READY
    BANKSEL RCSTA
    BSF     RCSTA, CREN

    RETFIE
ISR_HANDLE_TXIF ;UNUSED HERE
    RETFIE



INIT    CODE
INIT
    CLRF    TRISD
    CLRF    PORTD
    BSF     TRISC,  RC6
    BSF     TRISC,  RC7

    BANKSEL MESSAGE_READY
    CLRF    MESSAGE_READY
    BANKSEL RC_BUFFER
    CLRF    RC_BUFFER

    BANKSEL OSCCON
    MOVLW   0XF0
    MOVWF   OSCCON

    BANKSEL RCSTA
    BSF     RCSTA, SPEN

    BANKSEL PIE1
    BSF     PIE1, RCIE

    BANKSEL SPBRG
    MOVLW   D'12'
    MOVWF   SPBRG

    BANKSEL INTCON
    MOVLW   0XC0
    MOVWF   INTCON

    BANKSEL RCSTA
    BSF     RCSTA, CREN     ;ENABLES UART RECEPTION

MAINLOOP
    BANKSEL MESSAGE_READY
WAIT_FOR_MESSAGE
    BANKSEL MESSAGE_READY
    BTFSS   MESSAGE_READY, 7
    GOTO    WAIT_FOR_MESSAGE

    BANKSEL RC_BUFFER
    MOVF    RC_BUFFER, 0
    BANKSEL PORTD
    MOVWF   PORTD

    BANKSEL MESSAGE_READY
    CLRF    MESSAGE_READY

    GOTO    MAINLOOP
    ;MESSAGE IS READY



    END