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

ticks       = $00   ; 4 bytes
ball_time   = $05 ; 1 byte
sount_time  = $06 ; 1 byte
ballp       = $0300 ; 1 byte
dir         = $0302 ; 1 byte
cur        = $0303 ; 1 byte
under_ball  = $0304 ; 1 byte
under_cursor= $0305 ; 1 byte
tone        = $0306 ; 1 byte
length      = $0307 ; 1 byte

blank       = " "
block       = $ff

SAC = %10000000 ; set cursor address counter
E  = %10000000  ; LCD Emable
RW = %01000000  ; LCD Read/Write
RS = %00100000  ; LCD Register Select

;LEFT    = %0000001
;UP      =  %00000100
;RIGHT   =  %0001000
;DOWN    =  %00010000

TIMER1FLAG      =  %01000000
CA1FLAG         =  %00000010
CA2FLAG         =  %00000001

    .org $8000
reset:
    ldx #$ff
    txs
    stx length

    lda #%11000011
    sta IER
    lda #%00000101  ; Input-positive active edge 
    sta PCR

    jsr init_timer

    lda #%11111111  ; Set all pins on port B to output
    sta DDRB
    lda #%11100001  ; Set top 3 pins on port A to output
    sta DDRA

    lda #%00111000  ; Set 8 bit mode - 2 line - 5x8 font
    jsr lcd_instruction
    lda #%00001100  ; Set display on - cursor off - blink off
    jsr lcd_instruction
    lda #%00000110  ; Set inc and shift cursor - no scroll
    jsr lcd_instruction
    lda #%00000001  ; Clear screen
    jsr lcd_instruction


    lda #$01
    sta dir
    sta ballp
    sta tone
    lda #$00
    sta PORTA
    sta ball_time
    sta cur 
    jsr move_cursor
    lda #$ff
    jsr print_char
    lda #" "
    sta under_ball
    sta under_cursor
    jsr draw_net
    cli

loop:
    jsr move_ball
    jmp loop

beep:
    ldx length
beeping:
    jsr sound
    cpx #0
    bne beeping
    rts    

sound:
    sei
    sec 
    lda ticks
    sbc sount_time
    cmp tone
    bcc exit_sound
    lda #$01
    eor PORTA
    sta PORTA

    lda ticks
    sta sount_time
    dex
exit_sound:
    cli
    rts

move_ball:
    sec 
    lda ticks
    sbc ball_time
    cmp #250 ; 250ms
    bcc exit_move_ball

    lda ballp
    jsr move_cursor
    lda under_ball
    jsr print_char
    lda ballp
    clc
    adc dir
    sta ballp
    lda #$0f
    cmp ballp
    beq bacward
    lda #$40
    cmp ballp
    beq forward

    jmp update_ball_time
bacward:
    sec
    lda dir
    sbc #$02
    sta dir
    lda ballp
    clc
    adc #$3f
    sta ballp
    jmp update_ball_time  
forward:
    lda dir
    clc
    adc #$02
    sta dir 
    lda ballp
    clc
    sbc #$3e
    sta ballp
update_ball_time:
    lda ballp
    jsr move_cursor
    jsr read_char
    sta under_ball
    lda ballp
    jsr move_cursor
    lda #block
    jsr print_char
    lda ticks
    sta ball_time
    jsr check_squash
exit_move_ball:
    rts

butt_move:
    lda cur
    jsr move_cursor
    lda under_cursor
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
    lda #%000001111
    bit cur
    beq exit_move
    dec cur
    jmp exit_move
goright:
    lda cur
    and #%000001111
    cmp #%000001111
    beq exit_move
    inc cur
    jmp exit_move
goup:
    lda #%01000000
    bit cur
    beq exit_move
    lda cur
    clc
    sbc #$3f
    sta cur
    jmp exit_move
godown:
    lda #%01000000
    bit cur
    bne exit_move
    lda cur
    clc
    adc #$40
    sta cur
    jmp exit_move

exit_move:
    lda cur
    jsr move_cursor
    jsr read_char
    sta under_cursor
    lda cur
    jsr move_cursor
    lda #block 
    jsr print_char
    lda #$01
    sta tone
    lda #$62
    sta length
    jsr beep
    jsr check_squash
    rts

check_squash
    pha
    lda cur
    cmp ballp
    bne no_squash
    lda #$58
    sta under_ball
    sta under_cursor 
    lda #$03
    sta tone
    lda #$ff
    sta length
    jsr beep
no_squash
    pla
    rts

init_timer
    lda 0
    sta ticks
    sta ticks + 1
    sta ticks + 2
    sta ticks + 3
    lda #%01000000
    sta ACR
    lda #$e6
    sta T1CL
    lda #$03
    sta T1CH
    rts

draw_net:
    lda #$07
    jsr move_cursor
    lda #$7c
    jsr print_char
    lda #$08
    jsr move_cursor
    lda #$7c
    jsr print_char
    lda #$47
    jsr move_cursor
    lda #$7c
    jsr print_char
    lda #$48
    jsr move_cursor
    lda #$7c
    jsr print_char
    rts


lcd_wait:
    pha
    lda #%00000000  ; Set Port B to input
    sta DDRB
lcd_busy
    lda #RW
    sta PORTA
    lda #(RW | E)
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

read_char:
    jsr lcd_wait    
    lda #%00000000  ; Set Port B to input
    sta DDRB
    lda #(RS | RW)
    sta PORTA
    lda #(RS | RW | E)
    sta PORTA
    lda PORTB
    pha
    ;and #%10000000
    lda #(RS | RW)
    sta PORTA
    lda #%11111111  ; Set Port B to output
    sta DDRB
    pla
    rts

print_char:
    pha
    jsr lcd_wait
    sta PORTB
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
    lda #(RS | E)   ; set RS E to send instruction
    sta PORTA
    lda #RS         ; Set RS - Clear E RW bits
    sta PORTA
    pla
    rts

move_cursor:
    jsr lcd_wait
    ora #SAC
    sta PORTB
    lda #0          ; Clear E RW RS bits
    sta PORTA
    lda #E          ; set E to send instruction
    sta PORTA
    lda #0          ; Clear E RW RS bits
    sta PORTA
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

    bit IFR
    bvc not_timer
    jsr irqt
not_timer:
    lda #CA1FLAG
    bit IFR
    beq not_ca1
    jsr butt_move
not_ca1:
    lda #CA2FLAG
    bit IFR
    beq not_ca2
    jsr butt_move
not_ca2:

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
