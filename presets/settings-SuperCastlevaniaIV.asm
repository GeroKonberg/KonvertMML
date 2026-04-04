;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $12A7
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVKon.asm"