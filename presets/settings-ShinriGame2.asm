;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1000
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $02

incsrc "asm/readV120.asm"