.org $080D
.segment "ONCE"
.segment "STARTUP"
    jmp start
.segment "CODE"

; ZP variables
ZP        = $22
MOUSE_X   = ZP
MOUSE_X_L = ZP
MOUSE_X_H = MOUSE_X+1
MOUSE_Y   = MOUSE_X+2
MOUSE_Y_L = MOUSE_Y
MOUSE_Y_H = MOUSE_Y+1


; VERA
VERA_addr_L   = $9F20
VERA_addr_H   = $9F21
VERA_bank     = $9F22
VERA_data0    = $9F23
VERA_data1    = $9F24
VERA_ctrl     = $9F25
VERA_dc_video = $9F29
VERA_L1_MB    = $9F35
VERA_L1_TB    = $9F36
VERA_L1_HS_L  = $9F37
VERA_L1_HS_H  = $9F38

; VERA addresses
VERA_charset = $1F000

; KERNAL
SCREEN_MODE  = $FF5F
MOUSE_CONFIG = $FF68
MOUSE_GET    = $FF6B

; macro to load 8 bit addresses to VERA address thingies
.macro load_VERA_8bit_address address, stride
    lda address
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    lsr
    ora #(stride * $10)
    sta VERA_bank
    lda address
    asl
    sta VERA_addr_H
    stz VERA_addr_L
.endmacro

.macro print_16bit_hex address, x_loc, y_loc
    lda #$21
    sta VERA_bank
    lda #y_loc
    clc
    adc #$B0
    sta VERA_addr_H
    lda #x_loc
    asl
    sta VERA_addr_L
    lda address+1
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_vera
    pla
    and #$0F
    jsr print_hex_vera
    lda address
    pha
    lsr
    lsr
    lsr
    lsr
    jsr print_hex_vera
    pla
    and #$0F
    jsr print_hex_vera
.endmacro

start:
    ; TURN ON MOUSE
    sec
    jsr SCREEN_MODE
    lda #1
    jsr MOUSE_CONFIG

    ; LOAD THE MAPBASE
    load_VERA_8bit_address VERA_L1_MB, 2

    ldx #255
@A_loop:
    lda #1
    sta VERA_data0
    dex
    bne @A_loop

    ; lda #$F0
    ; sta VERA_L1_HS_L

@mouse_loop:
    ldx #MOUSE_X
    jsr MOUSE_GET
    pha
    stz VERA_ctrl
    print_16bit_hex MOUSE_X, 0, 58
    print_16bit_hex MOUSE_Y, 0, 59
    pla
    bra @mouse_loop
    rts

print_hex_vera:
    cmp #$0A
    bpl @letter
    ora #$30
    bra @print
@letter:
    clc
    sbc #9
@print:
    sta VERA_data0
    rts
