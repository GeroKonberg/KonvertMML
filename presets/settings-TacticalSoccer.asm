;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1718
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $04

incsrc "asm/readV120.asm"