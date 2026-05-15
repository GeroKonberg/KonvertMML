;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1951
!OutAddr = $0200
!ProgAddr = $E000

!ReadIndex = $01

incsrc "asm/readVCube.asm"