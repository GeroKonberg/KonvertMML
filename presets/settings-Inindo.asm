;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $B200
!OutAddr = $0200
!ProgAddr = $A000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"