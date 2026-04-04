;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $2300
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV132.asm"