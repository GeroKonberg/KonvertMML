;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $D200
!OutAddr = $0200
!ProgAddr = $C000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"