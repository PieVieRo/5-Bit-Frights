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

; IRQ Vector
IRQVec = $0314

; VERA
VERA_addr_L   = $9F20
VERA_addr_H   = $9F21
VERA_bank     = $9F22
VERA_data0    = $9F23
VERA_data1    = $9F24
VERA_ctrl     = $9F25
VERA_ien      = $9F26
VERA_dc_video = $9F29
VERA_L1_MB    = $9F35
VERA_L1_TB    = $9F36
VERA_L1_HS_L  = $9F37
VERA_L1_HS_H  = $9F38
VSYNC_BIT     = $01

; VERA addresses
VERA_charset = $1F000

; KERNAL
SCREEN_MODE  = $FF5F
MOUSE_CONFIG = $FF68
MOUSE_GET    = $FF6B

; CONSTANTS
LEFT_SIDE  = $80
RIGHT_SIDE = 640 - LEFT_SIDE

; FLAGS
SCREEN_MOVE_RIGHT = $01
SCREEN_MOVE_LEFT  = $02

; ====================
; |     VARIABLES    |
; ====================
player_flags: .byte $00 ; will probably move it to one of the ZP cells at some point
default_irq_handler: .addr $0

; ======
; MACROS
; =====

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


.macro print_8bit_hex_imm val, x_loc, y_loc
    lda #$21
    sta VERA_bank
    lda #y_loc
    clc
    adc #$B0
    sta VERA_addr_H
    lda #x_loc
    asl
    sta VERA_addr_L
    lda #val
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


.macro print_8bit_hex address, x_loc, y_loc
    lda #$21
    sta VERA_bank
    lda #y_loc
    clc
    adc #$B0
    sta VERA_addr_H
    lda #x_loc
    asl
    sta VERA_addr_L
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
    ; CHANGE IRQ HANDLER
    lda IRQVec
    sta default_irq_handler
    lda IRQVec+1
    sta default_irq_handler+1
    sei ; disable irq interrupt
    lda #<custom_irq_handler
    sta IRQVec
    lda #>custom_irq_handler
    sta IRQVec+1
    lda #VSYNC_BIT
    sta VERA_ien
    cli

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

@mouse_loop:
    ldx #MOUSE_X
    jsr MOUSE_GET
    pha
    ; stz VERA_ctrl
    ; print_16bit_hex MOUSE_X, 0, 58
    ; print_16bit_hex MOUSE_Y, 0, 59
    lda MOUSE_X+1
    beq @left_side_check ; could be left side
@right_side_check:
    cmp #>RIGHT_SIDE
    bmi @not_on_side ; it's not on the right side
    lda MOUSE_X
    cmp #<RIGHT_SIDE
    bmi @not_on_side ; It's not on the right side
    lda player_flags
    ora #SCREEN_MOVE_RIGHT
    bra @continue
@left_side_check:
    lda MOUSE_X
    cmp #LEFT_SIDE
    bpl @not_on_side ; It's not on the left side
    lda player_flags
    ora #SCREEN_MOVE_LEFT
    bra @continue
@not_on_side:
    lda player_flags
    and #%11111100
@continue:
    sta player_flags
    pla
    jmp @mouse_loop
    rts

custom_irq_handler:
    lda player_flags
    bit #SCREEN_MOVE_LEFT ; move screen to the left
    bne @try_move_left
    bit #SCREEN_MOVE_RIGHT ; move screen to the right
    bne @try_move_right
    bra @continue
@try_move_left:
    lda VERA_L1_HS_L
    beq @check_high_byte_left
    dec VERA_L1_HS_L
    bra @continue
@check_high_byte_left:
    lda VERA_L1_HS_H
    beq @continue
    dec VERA_L1_HS_H
    lda #$FF
    sta VERA_L1_HS_L
    bra @continue
@try_move_right:
    lda VERA_L1_HS_L
    cmp #$FF
    beq @check_high_byte_right
    inc VERA_L1_HS_L
    bra @continue
@check_high_byte_right:
    lda VERA_L1_HS_H
    cmp #$01
    beq @continue
    inc VERA_L1_HS_H
    stz VERA_L1_HS_L
    bra @continue
@continue:
    jmp (default_irq_handler)

; ===========
; SUBROUTINES
; ===========

print_hex_vera:
    cmp #$0A
    bpl @letter
    ora #$30
    bra @print
@letter:
    clc
    sbc #8
@print:
    sta VERA_data0
    rts

