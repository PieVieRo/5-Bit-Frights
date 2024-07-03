%import syslib

flags {
    const ubyte SCREEN_MOVE_RIGHT = 1 << 0
    const ubyte SCREEN_MOVE_LEFT = 1 << 1
}

main {
    const ubyte LEFT_SIDE = $80
    const uword RIGHT_SIDE = 640 - LEFT_SIDE

    ; uword @requirezp x,y
    ubyte @zp player_flags

    sub start() {
        ; cx16.set_vsync_irq_handler(custom_irq)
        ; cx16.enable_irq_handlers(false)
        sys.set_irq(custom_irq)
        cx16.mouse_config2(1)
        repeat {
            void, void, void, void = cx16.mouse_pos()
            if(cx16.r0 > RIGHT_SIDE) {
                player_flags |= flags.SCREEN_MOVE_RIGHT
            } else if(cx16.r0 < LEFT_SIDE) {
                player_flags |= flags.SCREEN_MOVE_LEFT
            } else {
                player_flags &= $FF ^ (flags.SCREEN_MOVE_RIGHT | flags.SCREEN_MOVE_LEFT)
            }
        }
        sys.restore_irq()
    }

    sub custom_irq() -> ubyte {
        cx16.save_vera_context()
        if(player_flags & flags.SCREEN_MOVE_RIGHT != 0) {
            if(cx16.VERA_L1_HSCROLL != $17F)
                cx16.VERA_L1_HSCROLL++
        } else if(player_flags & flags.SCREEN_MOVE_LEFT != 0) {
            if(cx16.VERA_L1_HSCROLL != 0)
                cx16.VERA_L1_HSCROLL--
        }
        cx16.restore_vera_context()
        return 1
    }
}
