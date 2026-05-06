;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $B500
!OutAddr = $0200
!ProgAddr = $A500

!ReadIndex = $01

incsrc "asm/readVSun.asm"