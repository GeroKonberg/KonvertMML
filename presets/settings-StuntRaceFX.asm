;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $07F6
!OutAddr = $0800
!ProgAddr = $E000

!ReadIndex = $01

incsrc "asm/readV120.asm"