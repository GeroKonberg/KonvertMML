;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1C80
!OutAddr = $6000
!ProgAddr = $F000

!ReadIndex = $02

incsrc "asm/readVMio.asm"