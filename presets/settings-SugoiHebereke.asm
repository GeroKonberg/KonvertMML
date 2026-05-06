;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $E200
!OutAddr = $0200
!ProgAddr = $D000

!ReadIndex = $01

incsrc "asm/readVSun.asm"