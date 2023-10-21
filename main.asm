.org $080D
.segment "ONCE"
.segment "STARTUP"
    jmp start
.segment "CODE"

ZP = $20

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

start:
    ; TURN ON MOUSE
    sec
    jsr SCREEN_MODE
    lda #1
    jsr MOUSE_CONFIG

    ; LOAD THE MAPBASE
    load_VERA_8bit_address VERA_L1_MB, 2

    ldx #255
@loop:
    lda #1
    sta VERA_data0
    dex
    bne @loop
    rts
