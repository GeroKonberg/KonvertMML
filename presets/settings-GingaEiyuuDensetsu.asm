;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1F52
!OutAddr = $2000
!ProgAddr = $C000

!ReadIndex = $01

incsrc "asm/readVACC.asm"