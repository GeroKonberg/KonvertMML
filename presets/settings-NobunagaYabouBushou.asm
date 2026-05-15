;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $C200
!OutAddr = $0200
!ProgAddr = $B000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"