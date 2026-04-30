;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $4400
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $13

incsrc "asm/readV120.asm"