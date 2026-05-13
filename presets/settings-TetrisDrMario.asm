;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $D000
!OutAddr = $0200
!ProgAddr = $B000

!ReadIndex = $01

incsrc "asm/readV120.asm"