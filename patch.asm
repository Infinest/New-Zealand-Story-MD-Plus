; Build params: ------------------------------------------------------------------------------
CHEAT               set 0
EXTENDED_SOUNDTRACK set 1
; Overrides: ---------------------------------------------------------------------------------

    org $370
    jsr PLAY_FUNCTION
    nop
    nop
    nop
    nop
    nop

    org $694
    jsr STOP_MUSIC_ON_RESET_FUNCTION

    org $74E
    jsr PAUSE_AND_RESUME_FUNCTION

; Detours: -----------------------------------------------------------------------------------
    ORG    $34E40
PLAY_FUNCTION:
    move.b  ($FFF083),d2
    cmpi.b  #$5,d2
    bcs     NORMAL_FX                   ; Branch if lower than 0x5 (Song indexes start at 0x5)            
    cmpi.b  #$11,d2  
    bhi.s   SPECIAL_SONG_CHECKS         ; Branch if higher than 0x11 (Song indexes end at 0x11)
    subi.b  #$4,d2                      ; Makes sure song indexes start at 1
ACTUALLY_MUSIC:
    andi.w #$00FF,d2                    ; Empty first word in d2
    
    if EXTENDED_SOUNDTRACK

    cmpi.b #$2,d2                       ; If the current song index is 2 (level theme, we check for the
    bne    NOT_LEVEL_THEME              ; current level and play different music depending on the level)
    JSR    GET_CURRENT_LEVEL_FUNCTION   ; Load current world into d4. Zero indexed
    tst.b  d4
    beq    NOT_LEVEL_THEME              ; We don't need to add anything to the track index if it's the first level, so skip the following code
    addi.b #$F,d2                       ; Add 0xF to the current track index. The list of extended level themes therefore start at track 18
    add.b  d4,d2                        ; add the current world number to the index
NOT_LEVEL_THEME:
    cmpi.b #$3,d2                       ; If the current song index is 3 (boss theme, we check for the current level and
    bne    NOT_BOSS_THEME               ; play the different end boss music if we are on the last level)
    JSR    GET_CURRENT_LEVEL_FUNCTION
    cmpi.b #$D,d4
    bne    NOT_BOSS_THEME               ; If the level index is not 0xD (index of last level), we don't need to add anything to the track index
    addi.b #$E,d2                       ; Add 0xE (14) to the track index. The final boss track is therefore track 17
NOT_BOSS_THEME:

    endif
    
    ori.w  #$1200,d2                    ; Put play command into upper byte of first word in d2
    move.w #$CD54,($0003F7FA)           ; Open interface
    move.w d2,($0003F7FE)               ; Send play command to interface
    move.w #$0000,($0003F7FA)           ; Close interface
    rts
SPECIAL_SONG_CHECKS:
    cmpi.b #$31,d2                      ; There is some music with later indexes. We check for these here. (Book of Death)
    bne    SKIP_1
    subi.b #$23,d2                      ; Makes sure the song is index 14
    bra    ACTUALLY_MUSIC
SKIP_1:
    cmpi.b #$38,d2                      ; (Entrance of Heaven)
    bne    SKIP_2
    subi.b #$29,d2                      ; Makes sure the song is index 15
    bra    ACTUALLY_MUSIC
SKIP_2:
    cmpi.b #$39,d2                      ; (Clock)
    bne    NORMAL_FX
    subi.b #$29,d2                      ; Makes sure the song is index 16
    bra    ACTUALLY_MUSIC
NORMAL_FX:
    move.b #$2,$a01e00.l
    move.b ($FFF083),$a01e01.l
    rts
    
STOP_MUSIC_ON_RESET_FUNCTION:
    move.w #$CD54,($0003F7FA)           ; Open interface
    move.w #$1300,($0003F7FE)           ; Send pause command to interface
    move.w #$0000,($0003F7FA)           ; Close interface
    rts
    
PAUSE_AND_RESUME_FUNCTION:
    cmpi.b #$3,d0
    bne PAUSE
RESUME:
    move.w #$1400,d4                    ; Write resume command to d4
    bra INTERFACE_WRITING
PAUSE:
    move.w #$1300,d4                    ; Write pause command to d4
INTERFACE_WRITING:
    move.w #$CD54,($0003F7FA)           ; Open interface
    move.w d4,($0003F7FE)               ; Send pause/resume command to interface
    move.w #$0000,($0003F7FA)           ; Close interface
    if     CHEAT
    move.b #$02,($FF8002)               ;The move instruction allows completing a level by pausing/resuming
    endif
    rts
    
GET_CURRENT_LEVEL_FUNCTION:
    andi.w #$0000,d4
    move.b ($FF8001),d4
    rts