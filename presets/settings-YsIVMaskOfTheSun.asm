;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $0690
!OutAddr = $0800
!ProgAddr = $C000

!ReadIndex = $16

incsrc "asm/readVCube.asm"