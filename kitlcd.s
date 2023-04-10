PORTB   = $6000
PORTA   = $6001
DDRB    = $6002
DDRA    = $6003

curh    = $0300 ; 1 byte
dir     = $0301 ; 1 byte

SAC = %10000000 ; set address counter
E   = %10000000
RW  = %01000000
RS  = %00100000

    .org $8000
reset:
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


    lda #0
    sta curh
    lda #$01
    sta dir

printy:
    jsr move_cursor
    lda #" "
    jsr print_char
    lda curh
    clc
    adc dir
    sta curh
    jsr move_cursor
    lda #$ff
    jsr print_char
    jsr move_cursor
    jsr print_char
    jsr move_cursor
    jsr print_char
    jsr move_cursor
    jsr print_char
    jsr move_cursor
    jsr print_char
    jsr move_cursor
    jsr print_char
    jsr move_cursor
    jsr print_char
    lda #$0f
    cmp curh
    beq bacward
    lda #$00
    cmp curh
    beq forward
    jmp printy
bacward:
    sec
    lda dir
    sbc #$02
    sta dir
    jmp printy  
forward:
    lda dir
    clc
    adc #$02
    sta dir
    jmp printy  

loop:
    jmp loop


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

print_char:
    jsr lcd_wait
    sta PORTB
    pha
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
    lda #(RS | E)   ; set RS E to send instruction
    sta PORTA
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
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


    .org $fffc
    .word reset
    .word $0000
