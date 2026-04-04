;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1D6F
!OutAddr = $2000
!ProgAddr = $C000

!ReadIndex = $01

incsrc "asm/readVACC.asm"