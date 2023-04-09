PORTB = $6000
PORTA = $6001
DDRB = $6002
DDRA = $6003

value =     $0200   ; 2 bytes
mod10 =     $0202   ; 2 bytes
message =   $0204 ; 6 bytes

E  = %10000000
RW = %01000000
RS = %00100000

    .org $8000
reset:
    lda #%11111111  ; Set all pins on port B to output
    sta DDRB
    lda #%11100000  ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000  ; Set 8 bit mode - 2 line - 5x8 font
    jsr lcd_instruction
    lda #%00001111  ; Set display on - cursor on - blink on
    jsr lcd_instruction
    lda #%00000110  ; Set inc and shift cursor - no scroll
    jsr lcd_instruction
    lda #%00000001  ; Clear screen
    jsr lcd_instruction

    lda #0
    sta message

    lda number
    sta value
    lda number + 1
    sta value + 1
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

loop:
    jmp loop

number: .word 1729

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


    .org $fffc
    .word reset
    .word $0000
