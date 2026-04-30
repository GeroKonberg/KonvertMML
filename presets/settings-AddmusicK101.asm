;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $236A
!OutAddr = $7000
!ProgAddr = $F000

!ReadIndex = $0A

incsrc "asm/readVAMK.asm"