;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $0706
!OutAddr = $0200
!ProgAddr = $D700

!ReadIndex = $01

incsrc "asm/readVCube.asm"