;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $901A
!OutAddr = $0200
!ProgAddr = $8000

!ReadIndex = $01

incsrc "asm/readVKoei.asm"