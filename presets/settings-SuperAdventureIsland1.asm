;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1000
!OutAddr = $3000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"