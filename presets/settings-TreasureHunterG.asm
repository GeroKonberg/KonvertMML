;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $3A00
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVSt2.asm"