;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $06D0
!OutAddr = $0200
!ProgAddr = $D300

!ReadIndex = $01

incsrc "asm/readVCube.asm"