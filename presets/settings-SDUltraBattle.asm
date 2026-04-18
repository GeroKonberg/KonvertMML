;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $2400
!OutAddr = $7000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVPure.asm"