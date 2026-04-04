;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $0D7A
!OutAddr = $8000
!ProgAddr = $F000

!ReadIndex = $01

incsrc "asm/readVKon2a6.asm"