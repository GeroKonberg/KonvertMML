;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1FE4
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $09

incsrc "asm/readV120.asm"