;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $D000
!OutAddr = $0200
!ProgAddr = $C000

!ReadIndex = $01

incsrc "asm/readVSun.asm"