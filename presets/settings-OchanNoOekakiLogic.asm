;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $D800
!OutAddr = $0200
!ProgAddr = $C800

!ReadIndex = $01

incsrc "asm/readVSun.asm"