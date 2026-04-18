;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1A80
!OutAddr = $7000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVMio.asm"