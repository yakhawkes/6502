
SAC = %10000000 ; set cursor address counter
E  = %10000000  ; LCD Emable
RW = %01000000  ; LCD Read/Write
RS = %00100000  ; LCD Register Select

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