;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1F00
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readTnE.asm"