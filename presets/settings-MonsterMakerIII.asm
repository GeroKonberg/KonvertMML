;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $06D8
!OutAddr = $0200
!ProgAddr = $D000

!ReadIndex = $01

incsrc "asm/readVCube.asm"