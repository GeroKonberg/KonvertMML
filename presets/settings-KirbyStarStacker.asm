;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $3300
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $48

incsrc "asm/readV120.asm"