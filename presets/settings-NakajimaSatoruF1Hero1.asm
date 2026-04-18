;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1800
!OutAddr = $7000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVMio.asm"