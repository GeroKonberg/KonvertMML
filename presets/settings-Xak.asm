;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $9A00
!OutAddr = $0200
!ProgAddr = $8A00

!ReadIndex = $01

incsrc "asm/readVSun.asm"