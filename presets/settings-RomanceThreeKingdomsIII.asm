;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $A01A
!OutAddr = $0200
!ProgAddr = $9000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"