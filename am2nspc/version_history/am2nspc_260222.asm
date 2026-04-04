norom
arch spc700-raw
dpbase $0000
optimize dp always

;direct page

org $000000
incbin "driver.spc":$000000..$010000 ;insert original SPC here
org $010000
incbin "driver.spc":$010000..$010200 ;insert original SPC here
org $01016C
db $E0 ;disable audio/echo writes at all cost
org $005B54
incbin "input.spc":$002B54..$005FFF ;insert addmusic SPC here

org $000025
dw KonvertInit

org $000100
base $000000 ;zero page

ReadSeq:
skip 2
BackSeq: ;backup for subroutine calls
skip 2
PointDiff:
skip 2
DPSubFlag:
skip 1
ReadPat:
skip 2
ReadTrackX: ;0-7,1-8
skip 2
WriteOut:
skip 2
WriteSub:
skip 2
DParamSize:
skip 1
DPNoteLength:
skip 1
DPNoteOctave:
skip 1
DPOctLatest:
skip 1
DPNoteKey:
skip 1
DPNoteTens:
skip 1
DPNoteHund:
skip 1
DPNoteTrans:
skip 1
DPStack:
skip 1
DPStack2:
skip 1
DPatPhrase: ;which phrase to take place at currently
skip 1
DPatRuntime: ;calculate pattern length on runtime for comparisons
skip 2
DPatMirror:
skip 2
DPatFlag: ;how many repeats are left, if specified
skip 1
DPatLength: ;measure total pattern lengths for channel 0
skip 32
DPSum1:
skip 1
DPSum2:
skip 1
DPQuant:
skip 1
DPBypass:
skip 1

org $009100
base $009000 ;drive page

KonvertInit:
	mov DPSubFlag,#$00
	mov ReadTrackX,#$00
	mov y,#$c0
	mov a,#$30
	movw WriteOut,ya

	mov y,#$a0
	mov a,#$00
	movw WriteSub,ya

	mov y,#$5a
	mov a,#$54
	movw ReadPat,ya

	mov y,#$00
	mov a,(ReadPat)+y
	push a
	inc y
	mov a,(ReadPat)+y
	clrc
	adc a,#$30
	mov y,a
	pop a
	movw ReadPat,ya

KonvertReadPattern: ;8x2-byte word pattern
	mov a,ReadTrackX
	asl a
	mov y,a
	mov a,(ReadPat)+y
	push a
	inc y
	mov a,(ReadPat)+y
	clrc
	adc a,#$30
	mov y,a
	pop a
	movw ReadSeq,ya
	jmp ReadSequence

ReadSequence:
---	mov y,#$00
	mov a,(ReadSeq)+y
	bmi ++
	bne +
	call RoutineWriter
	call ReadInterrupt
+
--	call RoutineWriter
	inc y
	call RoutineUpdateWord
	bra ---

++	and a,#$7f
	cmp a,#$5a ;da-ff = VCMDS
	bmi +
	call ReadVoiceCommands
+	cmp a,#$46   ;c6-d9 = ties, rests & drum notes
	bmi +
	inc a
	inc a
+	eor a,#$80
	bra --

ReadInterrupt:
-	nop
	bra -

ReadVoiceCommands:
-	setc
	sbc a,#$5a
	asl a
	mov x,a
	mov a,PresetVCMD+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMD+x
	push a
	ret

PresetVCMD:
	dw VcmdDA
	dw VcmdDB
	dw VcmdDC
	dw VcmdDD
	dw VcmdDE
	dw VcmdDF
	dw VcmdE0
	dw VcmdE1
	dw VcmdE2
	dw VcmdE3
	dw VcmdE4
	dw VcmdE5
	dw VcmdE6
	dw VcmdE7
	dw VcmdE8
	dw VcmdE9
	dw VcmdEA
	dw VcmdEB
	dw VcmdEC
	dw VcmdED
	dw VcmdEE
	dw VcmdEF
	dw VcmdF0
	dw VcmdF1
	dw VcmdF2
	dw VcmdF3
	dw VcmdF4
	dw VcmdF5
	dw VcmdF6
	dw VcmdF7
	dw VcmdF8
	dw VcmdF9
	dw VcmdFA
	dw VcmdFB
	dw VcmdFC
	dw VcmdFD
	dw VcmdFE
	dw VcmdFF

VcmdDA:
	mov a,#$e0
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDB:
	mov a,#$e1
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDC:
	mov a,#$e2
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDD:
	mov a,#$f9
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDE:
	mov a,#$e3
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDF:
	mov a,#$e4
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE0:
	mov a,#$e5
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE1:
	mov a,#$e6
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE2:
	mov a,#$e7
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdE3:
	mov a,#$e8
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE4:
	mov a,#$e9
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE5:
	mov a,#$eb
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE6:
-	nop
	bra -

VcmdE7:
	mov a,#$ed
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE8:
	mov a,#$ee
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdE9: ;subroutines
	mov a,#$ef
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	push a
	inc y ;arg 2
	mov a,(ReadSeq)+y
	clrc
	adc a,#$30
	push a
	inc y ;arg 3
	mov a,(ReadSeq)+y
	mov DPSubFlag,a
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeq,ya
	pop a
	mov y,a
	pop a
	movw ReadSeq,ya
	jmp ReadSequence

VcmdEA:
	mov a,#$f0
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEB:
	mov a,#$f1
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEC:
	mov a,#$f2
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdED:
-	nop
	bra -

VcmdEE:
	mov a,#$f4
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEF:
	mov a,#$f5
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF0:
	mov a,#$f6
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF1:
	mov a,#$f7
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,#$00
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF2:
	mov a,#$f8
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdF3:
-	nop
	bra -

VcmdF4:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdF5:
-	nop
	bra -

VcmdF6:
-	nop
	bra -

VcmdF7:
-	nop
	bra -

VcmdF8:
-	nop
	bra -

VcmdF9:
-	nop
	bra -

VcmdFA:
	inc y
	mov a,(ReadSeq)+y
	inc y
	cmp a,#$02
	bne +
	mov a,#$ea
	call RoutineWriter
	mov a,(ReadSeq)+y
	call RoutineWriter
+	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdFB:
-	nop
	bra -

VcmdFC:
-	nop
	bra -

VcmdFD:
-	nop
	bra -

VcmdFE:
-	nop
	bra -

VcmdFF:
-	nop
	bra -




RoutineUpdateWord:
	mov a,y
	clrc
	adc a,ReadSeq
	bcc +
	inc ReadSeq+1
+	mov ReadSeq,a
	mov y,#$00
	ret


RoutineWriter: ;write accumulator to output
	cmp DPSubFlag,#$00
	bne +++
	push y
	mov y,#$00
	mov (WriteOut)+y,a
	mov a,WriteOut
	clrc
	adc a,#$01
	bcc +
	inc WriteOut+1
+	mov WriteOut,a
	pop y
	ret
	
RoutineSubWriter: ;write accumulator to output
+++	push y
	mov y,#$00
	mov (WriteSub)+y,a
	mov a,WriteSub
	clrc
	adc a,#$01
	bcc +
	inc WriteSub+1
+	mov WriteSub,a
	pop y
	ret
	