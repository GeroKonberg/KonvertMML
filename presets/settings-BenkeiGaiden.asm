;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $C400
!OutAddr = $0200
!ProgAddr = $B400

!ReadIndex = $01

incsrc "asm/readVSun.asm"