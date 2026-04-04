;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1136
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $03

incsrc "asm/readV120.asm"