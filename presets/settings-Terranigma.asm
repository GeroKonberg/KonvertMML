;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $10FC
!OutAddr = $0200
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"