;konvertMML settings
!ReadFile = "input.spc"

!ReadAddr = $1B10
!OutAddr = $4000
!ProgAddr = $3800

!ReadIndex = $01

incsrc "asm/readV120.asm"