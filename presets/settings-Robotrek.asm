;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $6F91
!OutAddr = $0200
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"