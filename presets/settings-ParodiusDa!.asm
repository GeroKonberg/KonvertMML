;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $120A
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVKon1.asm"