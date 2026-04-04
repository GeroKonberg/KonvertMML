;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1A00
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"