;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $0700
!OutAddr = $0200
!ProgAddr = $D800

!ReadIndex = $01

incsrc "asm/readVCube.asm"