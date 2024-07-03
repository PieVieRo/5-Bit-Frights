        .org $080D
.segment "ONCE"
.segment "STARTUP"

; ZP variables
ZP = $22
MOUSE_X = ZP
MOUSE_X_L = ZP
MOUSE_X_H = MOUSE_X+1
MOUSE_Y = MOUSE_X+2
MOUSE_Y_L = MOUSE_Y
MOUSE_Y_H = MOUSE_Y+1

; IRQ Vector
IRQVec = $0314

; VERA
VERA_addr_L = $9F20
VERA_addr_H = $9F21
VERA_bank = $9F22
VERA_data0 = $9F23
VERA_data1 = $9F24
VERA_ctrl = $9F25
VERA_ien = $9F26
VERA_dc_video = $9F29
VERA_L1_MB = $9F35
VERA_L1_TB = $9F36
VERA_L1_HS_L = $9F37
VERA_L1_HS_H = $9F38
VSYNC_BIT = $01

; VERA addresses
VERA_charset = $1F000

; KERNAL
SCREEN_MODE = $FF5F
MOUSE_CONFIG = $FF68
MOUSE_GET = $FF6B

; CONSTANTS
LEFT_SIDE = $80
RIGHT_SIDE = 640 - LEFT_SIDE

; FLAGS
SCREEN_MOVE_RIGHT = $01
SCREEN_MOVE_LEFT = $02


; ======
; MACROS
; =====

.macro  load_VERA_8bit_address address, stride
        LDA address
        LSR
        LSR
        LSR
        LSR
        LSR
        LSR
        LSR
        ORA #(stride * $10)
        STA VERA_bank
        LDA address
        ASL
        STA VERA_addr_H
        STZ VERA_addr_L
.endmacro


.macro  print_8bit_hex_imm val, x_loc, y_loc
        LDA #$21
        STA VERA_bank
        LDA #y_loc
        CLC
        ADC #$B0
        STA VERA_addr_H
        LDA #x_loc
        ASL
        STA VERA_addr_L
        LDA #val
        PHA
        LSR
        LSR
        LSR
        LSR
        JSR print_hex_vera
        PLA
        AND #$0F
        JSR print_hex_vera
.endmacro


.macro  print_8bit_hex address, x_loc, y_loc
        LDA #$21
        STA VERA_bank
        LDA #y_loc
        CLC
        ADC #$B0
        STA VERA_addr_H
        LDA #x_loc
        ASL
        STA VERA_addr_L
        LDA address
        PHA
        LSR
        LSR
        LSR
        LSR
        JSR print_hex_vera
        PLA
        AND #$0F
        JSR print_hex_vera
.endmacro

.macro  print_16bit_hex address, x_loc, y_loc
        LDA #$21
        STA VERA_bank
        LDA #y_loc
        CLC
        ADC #$B0
        STA VERA_addr_H
        LDA #x_loc
        ASL
        STA VERA_addr_L
        LDA address + 1
        PHA
        LSR
        LSR
        LSR
        LSR
        JSR print_hex_vera
        PLA
        AND #$0F
        JSR print_hex_vera
        LDA address
        PHA
        LSR
        LSR
        LSR
        LSR
        JSR print_hex_vera
        PLA
        AND #$0F
        JSR print_hex_vera
.endmacro

.segment "CODE"

start:
        ; CHANGE IRQ HANDLER
        LDA IRQVec
        STA default_irq_handler
        LDA IRQVec + 1
        STA default_irq_handler + 1
        SEI             ; disable irq interrupt
        LDA #<custom_irq_handler
        STA IRQVec
        LDA #>custom_irq_handler
        STA IRQVec + 1
        LDA #VSYNC_BIT
        STA VERA_ien
        CLI

        ; TURN ON MOUSE
        SEC
        JSR SCREEN_MODE
        LDA #1
        JSR MOUSE_CONFIG

        ; LOAD THE MAPBASE
        load_VERA_8bit_address VERA_L1_MB, 2

        ; LOOP THE A's
        LDX #255
    @A_loop:
        LDA #1
        STA VERA_data0
        DEX
        BNE @A_loop

    @mouse_loop:
        LDX #MOUSE_X
        JSR MOUSE_GET

        ; STORE THE BUTTON STATE ON THE STACK
        PHA

        ; stz VERA_ctrl
        ; print_16bit_hex MOUSE_X, 0, 58
        ; print_16bit_hex MOUSE_Y, 0, 59

        LDA MOUSE_X + 1
        ; IF HIGH BYTE == 0 IT WON'T BE ON THE RIGHT SIDE
        BEQ @left_side_check

    @right_side_check:
        CMP #>RIGHT_SIDE
        BMI @not_on_side
        LDA MOUSE_X
        CMP #<RIGHT_SIDE
        BMI @not_on_side
        LDA player_flags
        ORA #SCREEN_MOVE_RIGHT
        BRA @continue

    @left_side_check:
        LDA MOUSE_X
        CMP #LEFT_SIDE
        BPL @not_on_side; It's not on the left side
        LDA player_flags
        ORA #SCREEN_MOVE_LEFT
        BRA @continue

    @not_on_side:
        LDA player_flags
        AND #%11111100
    @continue:
        STA player_flags

        ; PULL THE MOUSE STATE FROM THE STACK
        PLA
        JMP @mouse_loop
        RTS

custom_irq_handler:
        JSR move_screen
        JMP (default_irq_handler)


; ===========
; SUBROUTINES
; ===========

move_screen:
        LDA player_flags
        BIT #SCREEN_MOVE_LEFT; move screen to the left
        BNE @try_move_left
        BIT #SCREEN_MOVE_RIGHT; move screen to the right
        BNE @try_move_right
        BRA @continue
    @try_move_left:
        LDA VERA_L1_HS_L
        BEQ @check_high_byte_left
        DEC VERA_L1_HS_L
        BRA @continue
    @check_high_byte_left:
        LDA VERA_L1_HS_H
        BEQ @continue
        DEC VERA_L1_HS_H
        LDA #$FF
        STA VERA_L1_HS_L
        BRA @continue

; CHECKING RIGHT SIDE
    @try_move_right:
        LDX VERA_L1_HS_H
        BEQ @check_full_right
        LDY VERA_L1_HS_L
        CPY #$7F
        BEQ @continue
        INC VERA_L1_HS_L
        BRA @continue
    @check_full_right:
        LDY VERA_L1_HS_L
        CPY #$FF
        BEQ @add_high_hs
        INC VERA_L1_HS_L
        BRA @continue
    @add_high_hs:
        INC VERA_L1_HS_H
        STZ VERA_L1_HS_L
        BRA @continue
    @continue:
        RTS

print_hex_vera:
        CMP #$0A
        BPL @letter
        ORA #$30
        BRA @print
    @letter:
        CLC
        SBC #8
    @print:
        STA VERA_data0
        RTS

.segment "BSS"
player_flags:
        .byte $00 ; will probably move it to one of the ZP cells at some point
default_irq_handler:
        .addr $0
