;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $E000
!OutAddr = $6000
!ProgAddr = $5000

!ReadIndex = $06

incsrc "asm/readV120.asm"