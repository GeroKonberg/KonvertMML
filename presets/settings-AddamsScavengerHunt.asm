;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $8000
!OutAddr = $0200
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVOcean.asm"