;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $9F00
!OutAddr = $0200
!ProgAddr = $8F00

!ReadIndex = $01

incsrc "asm/readVKoei.asm"