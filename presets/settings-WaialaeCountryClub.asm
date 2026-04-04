;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1271
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV120.asm"