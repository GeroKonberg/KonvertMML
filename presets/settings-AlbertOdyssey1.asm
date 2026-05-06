;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $A000
!OutAddr = $0200
!ProgAddr = $9000

!ReadIndex = $01

incsrc "asm/readVSun.asm"