;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $C000
!OutAddr = $0200
!ProgAddr = $B000

!ReadIndex = $01

incsrc "asm/readVSun.asm"