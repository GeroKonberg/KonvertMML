;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $CF00
!OutAddr = $0200
!ProgAddr = $BF00

!ReadIndex = $01

incsrc "asm/readVKoei.asm"