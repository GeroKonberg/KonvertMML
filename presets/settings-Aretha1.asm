;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $00AC
!OutAddr = $AF00
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVJam.asm"