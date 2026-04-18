;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1C00
!OutAddr = $7000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVPure.asm"