;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $020E
!OutAddr = $0200
!ProgAddr = $D600

!ReadIndex = $01

incsrc "asm/readVCube.asm"