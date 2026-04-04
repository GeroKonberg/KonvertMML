;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $2800
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readArcs.asm"