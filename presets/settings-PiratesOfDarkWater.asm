;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $DC00
!OutAddr = $0200
!ProgAddr = $CC00

!ReadIndex = $01

incsrc "asm/readVSun.asm"