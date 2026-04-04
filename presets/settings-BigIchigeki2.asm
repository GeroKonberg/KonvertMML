;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $C800
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $02

incsrc "asm/readV120.asm"