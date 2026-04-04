;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $201A
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readV090.asm"