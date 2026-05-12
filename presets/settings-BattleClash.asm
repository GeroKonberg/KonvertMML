;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1AC6
!OutAddr = $7000
!ProgAddr = $EF00

!ReadIndex = $01

incsrc "asm/readVIS3.asm"