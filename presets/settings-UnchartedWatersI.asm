;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $B000
!OutAddr = $0200
!ProgAddr = $A000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"