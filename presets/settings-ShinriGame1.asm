;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1999
!OutAddr = $0200
!ProgAddr = $EF00

!ReadIndex = $01

incsrc "asm/readVIS3.asm"