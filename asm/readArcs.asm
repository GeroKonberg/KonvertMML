norom
arch spc700-raw
dpbase $0000
optimize dp always

;direct page

org $000000
incbin "input.spc":$000000..$010000 ;insert original SPC here
org $010000
incbin "input.spc":$010000..$010200 ;insert original SPC here
org $01016C
db $E0 ;disable audio/echo writes at all cost


org $000025
dw KonvertInit

org $000100
base $000000 ;zero page

ReadSeq:
skip 2
ReadPat:
skip 2
ReadOffset:
skip 2
BackSeq: ;backup for subroutine calls
skip 2
DPSubFlag:
skip 1
ReadTrackX: ;0-7,1-8
skip 2
WriteOut:
skip 2
DParamSize:
skip 1
DPKitFlag:
skip 1
DPLegatoFlag:
skip 1
DPNoteLength:
skip 1
DPNoteOctave:
skip 1
DPOctLatest:
skip 1
DPNoteLatest:
skip 1
DPNoteKey:
skip 1
DPNoteTens:
skip 1
DPNoteHund:
skip 1
DPNoteTrans:
skip 1
DPNoteQuant:
skip 1
DPNoteVel:
skip 1
DPNoteParam:
skip 1
DPStack:
skip 1
DPStack2:
skip 1
DPatPhrase: ;which phrase to take place at currently
skip 1
DPatMirror:
skip 2
DPRepFlagA: ;how many repeats are left, if specified
skip 1
DPRepFlagB:
skip 1
DPSum1:
skip 1
DPSum2:
skip 1
DPQuant:
skip 1
DPBypass:
skip 1
DPBetopID:
skip 1
DPRepValA:
skip 1
DPRepValB:
skip 1

DPArcTracks:
skip 1
DPArcVolume:
skip 1
DPArcDrum:
skip 1

DPatRuntime: ;calculate pattern length on runtime for comparisons
skip 2
DPatSubtime: ;calculate pattern length on subtime for comparisons
skip 2
DPatLength: ;measure total pattern lengths for channel 0
skip 128


org !OutAddr+256
base !OutAddr
	db "#amk 2 #samples {#default }"
	db $20
	db $20
	db "#0 "

org !ProgAddr+256
base !ProgAddr ;bypass driver code with a converter

KonvertInit:
	mov $f2,#$6c
	mov $f3,#$e0
	mov a,#$00 ;clear zero page
	mov y,a
	mov x,a
	dec x
	mov sp,x
	inc x
	mov y,#$f0
-	dec y
	mov $00+y,a
	cmp y,#$00
	bne -
	mov a,KonvertSet+1+x ;store song position
	mov y,a
	mov a,KonvertSet+x
	movw ReadSeq,ya
	movw ReadPat,ya ;write pattern location for above song
	mov a,KonvertSet+4
	mov y,a
	mov a,KonvertSet+3
	movw WriteOut,ya ;where to write out data
	mov y,#$00
	mov a,(ReadSeq)+y
	mov DPArcTracks,a
	mov a,#$23
	call RoutineWriter
	mov a,#$61
	call RoutineWriter
	mov a,#$6d
	call RoutineWriter
	mov a,#$6b
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	mov a,#$32
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	jmp KonvertReadPattern

KonvertSet:
	dw !ReadAddr
	db !ReadIndex
	dw !OutAddr

KonvertReadPattern:
	;read 2x8 pattern index from channel 0-7
	mov DPatPhrase,#$00
	mov DPKitFlag,#$00
	mov DPLegatoFlag,#$00
	mov DPNoteLatest,#$00
	mov DPNoteOctave,#$00
	mov DPNoteLength,#$00
	mov DPNoteQuant,#$00
	mov DPNoteVel,#$00
	mov DPNoteParam,#$00
	mov DPNoteKey,#$00
	mov DPNoteTrans,#$00
	mov DPArcVolume,#$00
	mov DPArcDrum,#$00
	mov a,#$23 ;start new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov y,a
	mov a,PresetHex+y
	call RoutineWriter
	mov a,ReadTrackX
	inc a
	mov y,#$06
	mul ya
	mov y,a
	mov a,(ReadSeq)+y ;volume R
	mov DPArcVolume,a
	dec y
	mov a,(ReadSeq)+y ;volume L
	cmp a,DPArcVolume
	bmi +
	mov DPArcVolume,a
+	asl DPArcVolume
	mov a,#$e7
	call RoutineWriteHex
	mov x,DPArcVolume
	mov a,PresetVolumes+x
	call RoutineWriteHex
	mov a,#$da
	call RoutineWriteHex
	dec y
	mov a,(ReadSeq)+y ;program change
	call RoutineWriteHex
	mov a,#$ee
	call RoutineWriteHex
	dec y
	mov a,(ReadSeq)+y ;fine tune
	call RoutineWriteHex
	dec y
	mov a,(ReadSeq)+y ;track H
	push a
	dec y
	mov a,(ReadSeq)+y ;track L
	mov ReadSeq,a
	pop a
	mov ReadSeq+1,a
	jmp ReadSequence

ReadSequence:
	mov y,#$00
	mov a,(ReadSeq)+y
	bmi ++
	cmp a,#$61
	bpl +++
-	nop
	bra -
++	cmp a,#$e0
	bmi +++
	jmp VoiceCommandRun
+++	clrc
	adc a,#$20
	and a,#$7f
	inc a
	bpl +
	jmp VcmdDFRest
+	dec a
	cmp a,#$70 ;drum kit
	bmi ++
	and a,#$0f
	cmp a,DPArcDrum ;check for duplicate drum numbers
	beq +
	mov DPArcDrum,a
	push a
	mov a,#$da
	call RoutineWriteHex
	pop a
	call RoutineWriteHex
+	mov a,#$2c ;->30
++	
+++	call RoutineGetNote
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;length param (00-7F)
	bpl +
	dec y
	mov a,DPNoteLength
+	mov DPNoteLength,a
	call RoutineHexDecimal
	jmp FinishCom

VoiceCommandRun: ;E0-FF
	and a,#$1f
	asl a
	mov x,a
	mov a,PresetArcIndex+1+x ;jump to special VCMD
	push a
	mov a,PresetArcIndex+x
	push a
	ret

PresetArcIndex:
	dw VcmdE0end	;e0
	dw VcmdE1	;e1
	dw VcmdE2	;e2
	dw VcmdE3	;e3
	dw VcmdE4	;e4
	dw VcmdE5	;e5
	dw VcmdE6end	;e6
	dw VcmdE7vol	;e7
	dw VcmdE8src	;e8
	dw VcmdE9rep1	;e9
	dw VcmdEA	;ea
	dw VcmdEBbend	;eb
	dw VcmdEC	;ec
	dw VcmdED	;ed
	dw VcmdEE	;ee
	dw VcmdEF	;ef
	dw VcmdF0	;f0
	dw VcmdF1	;f1
	dw VcmdF2	;f2
	dw VcmdF3Tempo	;f3
	dw VcmdF4	;f4
	dw VcmdF5	;f5
	dw VcmdF6	;f6
	dw VcmdF7	;f7
	dw VcmdF8adsr	;f8
	dw VcmdF9	;f9
	dw VcmdFA	;fa
	dw VcmdFB	;fb
	dw VcmdFCfine	;fc
	dw VcmdFD	;fd
	dw VcmdFE	;fe
	dw VcmdFF	;ff

FinishCom:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDFRest: ;df
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;param 1 (00-7F)
	bpl +
	dec y
	mov a,DPNoteLength
+	mov DPNoteLength,a
	call RoutineHexDecimal
	jmp FinishCom

VcmdE0end:	;e0 loop/end track
	inc ReadTrackX
	cmp ReadTrackX,DPArcTracks ;check for max tracks
	bmi +
-	nop
	bra -
+	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern

VcmdE1:	;e1
-	nop
	bra -

VcmdE2:	;e2
-	nop
	bra -

VcmdE3:	;e3
-	nop
	bra -

VcmdE4:	;e4
-	nop
	bra -

VcmdE5:	;e5
-	nop
	bra -

VcmdE6end: ;e6
	jmp VcmdE0end

VcmdE7vol: ;e7
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	mov DPArcVolume,a
	inc y
	mov a,(ReadSeq)+y
	cmp a,DPArcVolume
	bmi ++
	mov DPArcVolume,a
++	asl a
	mov x,a
	mov a,PresetVolumes+x
	call RoutineWriteHex
	jmp FinishCom

VcmdE8src:	;e8
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	jmp FinishCom

VcmdE9rep1:	;e9 00 = start loop, end loop with repeat-1
	inc y
	mov a,(ReadSeq)+y ;param1 (nest level)
	bne +++
	mov a,DPRepFlagA ;check for previous repeats
	bne ++
	inc y
	mov a,(ReadSeq)+y ;param2
	dec a
	mov DPRepFlagA,a
	inc y
	mov a,(ReadSeq)+y ;addr L
	push a
	inc y
	mov a,(ReadSeq)+y ;addr H
	mov y,a
	pop a
	movw ReadSeq,ya
	mov a,#$5b ;start bracket
	call RoutineWriter
	jmp ReadSequence
++	mov a,#$5d ;end bracket
	call RoutineWriter
	mov a,DPRepFlagA ;amount to loop (minus init)
	call RoutineHexDecimal
	mov DPRepFlagA,#$00
	mov y,#$04
	jmp FinishCom

VcmdE9rep2:
+++	mov a,DPRepFlagB ;check for previous repeats
	bne ++
	inc y
	mov a,(ReadSeq)+y ;param2
	dec a
	mov DPRepFlagB,a
	inc y
	mov a,(ReadSeq)+y ;addr L
	push a
	inc y
	mov a,(ReadSeq)+y ;addr H
	mov y,a
	pop a
	movw ReadSeq,ya
	mov a,#$20 ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$20 ;start double bracket
	call RoutineWriter
	jmp ReadSequence
++	mov a,#$20 ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,DPRepFlagB ;amount to loop (minus init)
	call RoutineHexDecimal
	mov DPRepFlagB,#$00
	mov y,#$04
	jmp FinishCom


VcmdEA: ;ea
-	nop
	bra -

VcmdEBbend:	;eb
	mov y,#$04 ;save bend data for later in reverse order
	mov a,(ReadSeq)+y
	push a
	dec y
	dec y
	mov a,(ReadSeq)+y
	push a
	dec y
	mov a,(ReadSeq)+y
	push a
	inc y
	inc y
	mov a,(ReadSeq)+y ;get starting note 
	clrc
	adc a,#$20
	and a,#$7f
	call RoutineGetNote
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	inc y
	mov a,(ReadSeq)+y ;note length [00-7F]
	bpl +
	dec y
	mov a,DPNoteLength
+	mov DPNoteLength,a
	call RoutineHexDecimal
	mov a,#$dd
	call RoutineWriteHex
	pop a ;delay
	call RoutineWriteHex
	pop a ;duration
	call RoutineWriteHex
	pop a ;note
	clrc
	adc a,#$20
	and a,#$7f
	call RoutineGetNote
	mov a,#$20
	call RoutineWriter
	jmp FinishCom

VcmdEC: ;ec
-	nop
	bra -

VcmdED:	;ed
-	nop
	bra -

VcmdEE:	;ee
-	nop
	bra -

VcmdEF:	;ef
-	nop
	bra -

VcmdF0:	;f0
-	nop
	bra -

VcmdF1:	;f1
-	nop
	bra -

VcmdF2:	;f2
-	nop
	bra -

VcmdF3Tempo: ;f3
	mov a,#$74  ;t
	call RoutineWriter
	inc y ;skip param1
	inc y
	mov a,(ReadSeq)+y ;param2
	lsr a
	lsr a
	lsr a
	dec a
	call RoutineHexDecimal
	jmp FinishCom


VcmdF4:	;f4
-	nop
	bra -

VcmdF5:	;f5
-	nop
	bra -

VcmdF6:	;f6
-	nop
	bra -

VcmdF7:	;f7
-	nop
	bra -

VcmdF8adsr:	;f8
	mov a,#$ed
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	and a,#$7f
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	jmp FinishCom

VcmdF9:	;f9
-	nop
	bra -

VcmdFA:	;fa
-	nop
	bra -

VcmdFB:	;fb
-	nop
	bra -

VcmdFCtrans: ;fc
	mov a,#$68 ;h
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteTrans,a
	bpl +
	mov DPStack2,a
	mov a,#$2d  ;if negative, add a subtraction sign
	call RoutineWriter
	mov a,#$00
	setc
	sbc a,DPStack2
+	call RoutineHexDecimal
	jmp FinishCom

VcmdFCfine:	;fc
	mov a,#$ee
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	jmp FinishCom

VcmdFD:	;fd
-	nop
	bra -

VcmdFE:	;fe
-	nop
	bra -

VcmdFF:	;ff
-	nop
	bra -



PresetHex: ;direct hex to ascii conversion table
	db "0123456789ABCDEF"

PresetNotes: ;note definition per octave
	db "c",$00
	db "c+"
	db "d",$00
	db "d+"
	db "e",$00
	db "f",$00
	db "f+"
	db "g",$00
	db "g+"
	db "a",$00
	db "a+"
	db "b",$00

VCMDBend:
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	clrc
	adc a,DPNoteTrans ;adapt note for transposition
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence





RoutineCloseLoop:
	mov a,#$5d ;close bracket
	call RoutineWriter
	mov a,DPSubFlag
	call RoutineHexDecimal
---	dec DPSubFlag
	cmp DPSubFlag,#$00
	beq +++
	movw ya,DPatRuntime
	addw ya,DPatSubtime
	movw DPatRuntime,ya
	cmp ReadTrackX,#$00 ;measure initial pattern lengths on track 0 per phrase
	bne ---
	mov a,DPatPhrase
	asl a
	mov x,a
	mov a,DPatLength+1+x
	mov y,a
	mov a,DPatLength+x
	addw ya,DPatSubtime
	mov DPatLength+x,a
	mov a,y
	mov DPatLength+1+x,a
	bra ---
+++	mov DPatSubtime,#$00
	mov DPatSubtime+1,#$00
	ret

RoutineMeasurePat:
	mov a,DPNoteLength ;measure length of current pattern
	clrc
	adc a,DPatRuntime
	bcc +
	inc DPatRuntime+1
+	mov DPatRuntime,a
	cmp DPSubFlag,#$00 ;measure length of current subroutine
	beq ++
	mov a,DPNoteLength
	clrc
	adc a,DPatSubtime
	bcc +
	inc DPatSubtime+1
+	mov DPatSubtime,a
++	cmp ReadTrackX,#$00 ;measure initial pattern lengths on track 0 per phrase
	bne ++
	mov a,DPatPhrase
	asl a
	mov x,a
	mov a,DPNoteLength
	clrc
	adc a,DPatLength+x
	bcc +
	inc DPatLength+1+x
+	mov DPatLength+x,a
++	ret

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
	
RoutineWriteHex: ;write accumulator as a hex value
	push y
	push a
	mov a,#$24 ;hex sign
	call RoutineWriter
	pop a
	pop y
RoutineWriteItself:
	push y
	push a ;process left value
	and a,#$f0
	xcn a
	mov y,a
	mov a,PresetHex+y
	call RoutineWriter
	pop a ;process right value
	and a,#$0f
	mov y,a
	mov a,PresetHex+y
	call RoutineWriter
	pop y
	ret

RoutineGetNote:
	mov DPNoteOctave,#$00
-	cmp a,#$0c ;decrement until the last octave
	bmi +
	inc DPNoteOctave
	setc
	sbc a,#$0c
	bra -
+	mov DPNoteKey,a
	cmp DPNoteOctave,DPOctLatest ;compare latest octave for truncation
	beq +
	mov a,#$6f ;o
	call RoutineWriter
	mov a,DPNoteOctave
	mov x,a
	mov a,PresetHex+x 
	call RoutineWriter ;write octave of the key in ASCII
+	mov a,DPNoteKey
	asl a
	mov x,a
	mov a,PresetNotes+x
	call RoutineWriter ;write note letter
	mov a,PresetNotes+1+x
	beq ++
	call RoutineWriter ;account for sharps and flats
++	mov DPOctLatest,DPNoteOctave
	ret

RoutineHexDecimal:
	;convert hex to decimal length (up to =127 supported)
	mov DPSum1,#$00
	mov DPSum2,#$00
-	inc DPSum1
	setc
	sbc a,#$0a
	bcs -
	adc a,#$0a
	dec DPSum1
+	mov DPStack,a
-	mov a,DPSum1
	cmp a,#$10
	bmi ++
	inc DPSum2
	clrc
	and DPSum1,#$0f
	adc DPSum1,#$06
	bra -
++	xcn a
	and a,#$f0
	clrc
	adc a,DPStack
	daa a
	bcc +
	inc DPSum2
+	mov DPSum1,a
	mov a,DPSum2
	beq +
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write hundreds (if given)
+	mov a,DPSum1
	and a,#$f0
	xcn a
;	beq +
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write tens (if given)
+	mov a,DPSum1
	and a,#$0f
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write ones (mandatory)
	ret




PresetVolumes: ;convert linear to exponential accordingly
	db $00,$18,$1d,$21, $25,$29,$2c,$2f, $31,$34,$37,$39, $3b,$3d,$3f,$42 ;00-0f
	db $44,$46,$48,$4a, $4c,$4e,$4f,$51, $52,$54,$56,$57, $59,$5a,$5c,$5d ;10-1f
	db $5e,$60,$61,$62, $64,$65,$66,$68, $69,$6a,$6b,$6d, $6e,$6f,$70,$71 ;20-2f
	db $72,$74,$75,$76, $77,$78,$79,$7a, $7b,$7c,$7d,$7e, $7f,$81,$82,$83 ;30-3f
	
	db $84,$85,$86,$87, $88,$89,$8a,$8b, $8c,$8d,$8e,$8f, $90,$91,$92,$93 ;40-4f
	db $93,$94,$95,$96, $97,$98,$99,$9a, $9a,$9b,$9c,$9d, $9e,$9f,$9f,$a0 ;50-5f
	db $a1,$a2,$a3,$a3, $a4,$a5,$a6,$a7, $a7,$a8,$a9,$aa, $ab,$ab,$ac,$ad ;60-6f
	db $ae,$ae,$af,$b0, $b1,$b1,$b2,$b3, $b3,$b4,$b5,$b6, $b6,$b7,$b8,$b9 ;70-7f
	
	db $b9,$ba,$bb,$bb, $bc,$bd,$bd,$be, $bf,$bf,$c1,$c2, $c2,$c3,$c4,$c4 ;80-8f
	db $c5,$c6,$c6,$c7, $c8,$c8,$c9,$ca, $ca,$cb,$cc,$cc, $cd,$ce,$ce,$cf ;90-9f
	db $d0,$d0,$d1,$d1, $d2,$d3,$d3,$d4, $d4,$d5,$d6,$d6, $d7,$d8,$d8,$d9 ;a0-af
	db $d9,$da,$db,$db, $dc,$dc,$dd,$de, $de,$df,$df,$e0, $e0,$e1,$e2,$e2 ;b0-bf

	db $e3,$e3,$e4,$e4, $e5,$e6,$e6,$e7, $e7,$e8,$e8,$e9, $ea,$ea,$eb,$eb ;c0-cf
	db $ec,$ec,$ed,$ed, $ee,$ef,$ef,$f0, $f0,$f1,$f1,$f2, $f2,$f3,$f3,$f4 ;d0-df
	db $f4,$f5,$f6,$f6, $f7,$f7,$f8,$f8, $f9,$f9,$fa,$fa, $fb,$fb,$fc,$fc ;e0-ef
	db $fd,$fd,$fe,$fe, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff, $ff,$ff,$ff,$ff ;f0-ff