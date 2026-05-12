;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $18EC
!OutAddr = $0200
!ProgAddr = $EF00

!ReadIndex = $01

incsrc "asm/readVIS3.asm"