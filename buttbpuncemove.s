PORTB   = $6000     ; Data B
PORTA   = $6001     ; Data A
DDRB    = $6002     ; Data Direction B
DDRA    = $6003     ; Data Direction A
T1CL    = $6004     ; Timer 1 Low
T1CH    = $6005     ; Timer 1 High
ACR     = $600b     ; Aux Control Register
PCR     = $600c     ; Peripheral Control
IFR     = $600d     ; Interrupt Flag Register
IER     = $600e     ; Interrupt Enable Register

ticks   = $00   ; 4 bytes
ball_time = $05 ; 1 byte
curh    = $0300 ; 1 byte
blank   = " "
block   = $ff

SAC = %10000000 ; set cursor address counter
E  = %10000000  ; LCD Emable
RW = %01000000  ; LCD Read/Write
RS = %00100000  

    .org $8000
reset:
    ldx #$ff
    txs

    lda #%11000011
    sta IER
    lda #%00000101  ; Input-positive active edge 
    sta PCR

    jsr init_timer

    lda #%11111111  ; Set all pins on port B to output
    sta DDRB
    lda #%11100000  ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000  ; Set 8 bit mode - 2 line - 5x8 font
    jsr lcd_instruction
    lda #%00001100  ; Set display on - cursor off - blink off
    jsr lcd_instruction
    lda #%00000110  ; Set inc and shift cursor - no scroll
    jsr lcd_instruction
    lda #%00000001  ; Clear screen
    jsr lcd_instruction

    lda #$00
    sta ball_time
    sta curh
    jsr move_cursor
    lda #$ff
    jsr print_char
    cli

loop:
    jsr move_ball
    jmp loop

move_ball:
    sec 
    lda ticks
    sbc ball_time
    cpm #10 ; 10ms
    bcc exit_move_ball
    lda ticks
    sta ball_time
ball_time:
    rts

init_timer
    lda 0
    sta ticks
    sta ticks + 1
    sta ticks + 2
    sta ticks + 3
    lda #%01000000
    sta ACR
    lda #$0e
    sta T1CL
    lda #$27
    sta T1CH
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

move_cursor:
    jsr lcd_wait
    pha
    lda curh
    ora #SAC
    sta PORTB
    lda #0          ; Clear E RW RS bits
    sta PORTA
    lda #E          ; set E to send instruction
    sta PORTA
    lda #0          ; Clear E RW RS bits
    sta PORTA
    pla
    rts



nmi:
    rti
;left: .byte %00000010
;CB      = %00011110  ; Control Buttons
LEFT: .byte %00000010
UP: .byte %00000100
RIGHT: .byte %0001000
DOWN: .byte %00010000

irqt:
    bit T1CL
    inc ticks
    bne end_ticking
    inc ticks + 1
    bne end_ticking
    inc ticks + 2
    bne end_ticking
    inc ticks + 3
end_ticking
    rts

irq:
    pha
    txa
    pha
    tya 
    pha

    jsr irqt

    jsr move_cursor
    lda #" "
    jsr print_char
    lda #" "
    jsr print_char

    lda PORTA
    and #%00011110
    beq exit_move
    bit LEFT
    bne goleft
    bit RIGHT
    bne goright
    bit UP
    bne goup
    bit DOWN
    bne godown
    jmp exit_move
    
goleft:
    dec curh
    jmp exit_move
goright:
    inc curh
    jmp exit_move
goup:
    lda curh
    clc
    sbc #$3f
    sta curh
    jmp exit_move
godown:
    lda curh
    clc
    adc #$40
    sta curh
    jmp exit_move

exit_move:
    jsr move_cursor
    lda #$ff 
    jsr print_char

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
