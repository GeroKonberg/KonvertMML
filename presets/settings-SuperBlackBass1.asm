;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $0729
!OutAddr = $0200
!ProgAddr = $CE00

!ReadIndex = $01

incsrc "asm/readVCube.asm"