PORTB = $6000   ; Data B
PORTA = $6001   ; Data A
DDRB = $6002    ; Data Direction B
DDRA = $6003    ; Data Direction A
PCR  = $600c    ; Peripheral Control
IFR  = $600d    ; Interrupt Flag Register
IER  = $600e    ; Interrupt Enable Register

value =     $0200   ; 2 bytes
mod10 =     $0202   ; 2 bytes
message =   $0204 ; 6 bytes
counter =   $020a ; 2 bytes

E  = %10000000  ; LCD Emable
RW = %01000000  ; LCD Read/Write
RS = %00100000  ; LCD Register Select


CB = %00011110  ; Control Buttons

    .org $8000
reset:
    ldx #$ff
    txs
    cli

    lda #$83
    sta IER
    lda #%00000101  ; Input-positive active edge 
    sta PCR

    lda #%11111111  ; Set all pins on port B to output
    sta DDRB
    lda #%11100000  ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000  ; Set 8 bit mode - 2 line - 5x8 font
    jsr lcd_instruction
    lda #%00001110  ; Set display on - cursor on - blink off
    jsr lcd_instruction
    lda #%00000110  ; Set inc and shift cursor - no scroll
    jsr lcd_instruction
    lda #%00000001  ; Clear screen
    jsr lcd_instruction

    lda #0
    sta counter
    sta counter + 1

loop:
    lda #%00000010  ; Home cursor
    jsr lcd_instruction


    lda #" "
    sta message
    lda #0
    sta message + 1

    sei
    lda counter
    sta value
    lda counter + 1
    sta value + 1
    cli

divide:
    lda #0
    sta mod10
    sta mod10 + 1
    clc

    ldx #16
divloop:
    rol value
    rol value + 1
    rol mod10
    rol mod10 + 1

    sec 
    lda mod10
    sbc #10
    tay     ; store low byte in y
    lda mod10 + 1
    sbc #0
    bcc negative   ; divident was less then divider
    sty mod10
    sta mod10 + 1

negative:
    dex
    bne divloop

    rol value
    rol value + 1
    lda mod10
    clc
    adc #"0"    
    jsr push_char

    ; check if value is 0
    lda value
    ora value + 1
    bne divide

    ldx #0
printy:
    lda message,x
    beq loop
    jsr print_char
    inx
    jmp printy  


; push char in a to start of message string
push_char:
    pha     ; push chat on to stack
    ldy #0
char_loop:
    lda message,y
    tax 
    pla
    sta message,y
    iny
    txa
    pha
    bne char_loop   ; loop if char is not null
    pla
    sta message,y   ; add null to end of string
    rts

lcd_wait:
    pha
    lda #%00000000  ; Set Port B to input
    sta DDRB
lcd_busy
    lda #RW
    sta PORTA
    lda # (RW | E)
    sta PORTA
    lda PORTB
    and #%10000000
    bne lcd_busy
    lda #RW
    sta PORTA
    lda #%11111111  ; Set Port B to output
    sta DDRB
    pla
    rts

lcd_instruction:
    jsr lcd_wait
    sta PORTB
    lda #0          ; Clear E RW RS bits
    sta PORTA
    lda #E          ; set E to send instruction
    sta PORTA
    lda #0          ; Clear E RW RS bits
    sta PORTA
    rts

print_char:
    jsr lcd_wait
    sta PORTB
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
    lda #(RS | E)   ; set RS E to send instruction
    sta PORTA
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
    rts
nmi:
    rti

irq:
    pha
    txa
    pha
    tya 
    pha

;   inc counter
;    bne exit_irq
;    inc counter + 1
;exit_irq:

    lda PORTA
    and #%00011110
    sta counter


;    ldy #$ff
    ldx #$ff
;delay:
;    dex
;    bne delay
;    dey
;    bne delay

    pla
    tay
    pla
    tax
    pla
    rti

; vectors
    .org $fffa
    .word nmi
    .word reset
    .word irq
