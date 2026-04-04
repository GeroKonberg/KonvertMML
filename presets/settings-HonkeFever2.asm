;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $111C
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"