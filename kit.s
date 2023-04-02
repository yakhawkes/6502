    .org $8000
reset:
    lda #$ff
    sta $6002
    lda #$01

loopleft:
    sta $6000
    rol
    beq looprigh
    jmp loopleft

looprigh
    sta $6000
    ror
    beq loopleft
    jmp looprigh


    .org $fffc
    .word reset
    .word $0000
