;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1A33
!OutAddr = $0200
!ProgAddr = $DE00

!ReadIndex = $01

incsrc "asm/readVCube.asm"