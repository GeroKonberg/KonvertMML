;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $FF4D
!OutAddr = $0200
!ProgAddr = $EF00

!ReadIndex = $01

incsrc "asm/readVIS4.asm"