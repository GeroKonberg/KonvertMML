
norom
arch spc700-raw
dpbase $000000
optimize dp ram

;direct page

org $000000
incbin "asm/SPCBase.bin" ;insert SPC header here

org $01016C
db $E0 ;disable audio/echo writes at all cost

org $0100
base $0000 ;zero page

ReadSeq: ;00-01
skip 2
WriteOut: ;02-03
skip 2
ReadTrackX: ;04
skip 1
DParamSize: ;05
skip 1
DPNoteOctave: ;06
skip 1
DPOctLatest: ;07
skip 1
DPNoteKey: ;08
skip 1
DPStack1: ;09
skip 1
DPStack2: ;0A
skip 1
DPSum1: ;0B
skip 1
DPSum2: ;0C
skip 1
DPBypass: ;0D
skip 1
DPatLength: ;0E-0F measure total pattern length for channel 0
skip 2
DPatRuntime: ;10-11 calculate pattern length on runtime for comparisons
skip 2
DPatOuttime: ;12-13 measure lengths for splitting
skip 2
DPatOutpost: ;14-15 when to split output
skip 2
DPLatestTempo: ;16
skip 1 
DPLatestPan: ;17
skip 1
DPLatestVolume: ;18
skip 1
DPLatestProg: ;19
skip 1
DPLatestForte: ;1A
skip 1
DPLatestMod: ;1B
skip 1
DPPercFlag: ;1C
skip 1
DPLatestPerc: ;1D
skip 1
DPRemainder: ;1E
skip 1
DPLengthFlag:
skip 1
DPLatestDelta: ;1F-20
skip 2
DPCompareDelta:
skip 2
PresetDuration:
	db $01,$60,$30,$18,$0C,$06,$03,$01
OutDuration:
	db "0","1","2","3","4","5","6","0"
DPActFlag:
skip 1

org $0200
base $0100 ;one page

fillbyte $00
fill align 256

org $0300
base $0200 ;write page

HeaderSQ:
FormatSQ: ;write out
skip 4000
skip align 256
LoadMIDI: ;load song
	incbin "input.mid"

fillbyte $00
fill 256
fill align 256


org $f100
base $f000 ;memory page


	dw LoadMIDI
	dw FormatSQ

KonvertInit:
	clrp
	mov a,#$00
	mov y,a
	mov x,a
	dec x
	mov sp,x ;stack ff
	inc x

KonvertProcessInit:
	mov ReadTrackX,#$fe
	mov a,KonvertInit-3
	mov y,a
	mov a,KonvertInit-4
	movw ReadSeq,ya
	mov a,KonvertInit-1
	mov y,a
	mov a,KonvertInit-2
	movw WriteOut,ya
	mov a,#$80
	mov y,#$01
	movw DPatOutpost,ya ;length of one 4/4 bar (output)
	mov y,#$17 ;skip header shenanigans
	
ReadSequence:
	mov a,(ReadSeq)+y
	bmi +++ ;01-7F -> delta wait
	mov a,#$3b
	call RoutineWriter
	mov a,#$21
	call RoutineWriter
-	nop
	bra -
+++	cmp a,#$ff ;meta event
	bne +
	jmp	ReadMetaEvent
+;	push a
;	mov DPPercFlag,#$00
;	and a,#$0f
;	cmp a,#$09 ;check for drum channel 10, enable flag if true
;	bne +
;	mov DPPercFlag,#$01
+;	pop a
	and a,#$70
	xcn a
	asl a
	mov x,a
	mov a,VCMDHighBit+1+x
	push a
	mov a,VCMDHighBit+x
	push a
	ret ;jmp to command

VCMDHighBit:
	dw ReadNoteOff ;80-8F
	dw ReadNoteOn ;90-9F
	dw ReadPolyphony ;A0-AF
	dw ReadController ;B0-BF
	dw ReadInstrument ;C0-CF
	dw ReadPressure ;D0-DF
	dw ReadBend ;E0-EF
	dw ReadSysex ;F0-FF

FinishCom:
---	inc y
	call RoutineUpdateWord
	jmp ReadSequence

ReadNoteOff:
	inc DPBypass
	mov y,#$03
	mov a,(ReadSeq)+y ;compare delta
	beq ---
	call RoutineCalcDelta
	mov a,#$72 ;r
	call RoutineWriter
	jmp FinishCom

ReadNoteOn:
	inc DPBypass
	mov y,#$03
	mov a,(ReadSeq)+y ;get delta
	call RoutineCalcDelta
	push y
	mov y,#$01
	mov a,(ReadSeq)+y ;get note number
	call RoutineGetNote
	mov y,#$02
	mov a,(ReadSeq)+y ;get velocity
	lsr a
	lsr a
	lsr a
	cmp a,DPLatestForte
	beq ++
	mov DPLatestForte,a
	or a,#$40
	call RoutineWriter
++	pop y
	jmp FinishCom


ReadPolyphony: ;TODO: skip this for now
-	nop
	bra -

ReadController:
	inc y
	mov a,(ReadSeq)+y ;get controller type
	cmp a,#$0c
	bmi +
	inc y
	jmp CheckDelta
+	asl a
	mov x,a
	mov a,PresetControllers+1+x
	push a
	mov a,PresetControllers+x
	push a
	inc y
	mov a,(ReadSeq)+y ;get controller value
	ret ;jmp to command


PresetControllers:
	dw CheckDelta
	dw CC01mod
	dw CC02breath
	dw CheckDelta
	dw CheckDelta
	dw CC05porta
	dw CheckDelta
	dw CC07vol
	dw CheckDelta
	dw CheckDelta
	dw CC0Apan
	dw CC0Bexp

CC01mod:
	lsr a
	lsr a
	lsr a
	cmp a,DPLatestMod
	beq ++
	mov DPLatestMod,a
	mov a,#$70 ;p
	call RoutineWriter
	mov a,DPLatestMod
	call RoutineWriteParam
++	jmp CheckDelta

CC02breath:
-	nop
	bra -

CC05porta:
-	nop
	bra -

CC07vol:
	lsr a
	lsr a
	cmp a,DPLatestVolume
	beq ++
	mov DPLatestVolume,a
	mov a,#$76 ;v
	call RoutineWriter
	mov a,DPLatestVolume
	call RoutineWriteParam
++	jmp CheckDelta

CC0Apan:
	push y
	asl a
	eor a,#$ff ;swap panning accordingly
	mov y,#$00
	mov x,#$0c
	div ya,x
	pop y
	cmp a,#$15
	bmi +
	dec a
+	cmp a,DPLatestPan
	beq ++
	mov DPLatestPan,a
	mov a,#$79  ;y
	call RoutineWriter
	mov a,DPLatestPan
	call RoutineHexDecimal
++	jmp CheckDelta

CC0Bexp:
-	nop
	bra -


ReadInstrument:
	inc y
	mov a,(ReadSeq)+y
	cmp a,DPLatestProg
	beq ++
	mov DPLatestProg,a
	mov a,#$40 ;at sign
	call RoutineWriter
	mov a,DPLatestProg
	and a,#$0f
	inc a
	call RoutineWriteParam
++	jmp CheckDelta


ReadPressure: ;TODO: skip this for now
-	nop
	bra -

ReadBend:
	inc y
	inc y
	jmp CheckDelta
	

ReadSysex:
-	nop
	bra -

ReadMetaEvent:
	inc y
	mov a,(ReadSeq)+y
	cmp a,#$2f ;end of track = $FF
	bne +++
	inc ReadTrackX
	bmi +
	mov DPOctLatest,#$00
	mov DPNoteOctave,#$00
	mov DPLatestForte,#$ff
	mov DPLatestMod,#$00
	mov DPLatestPan,#$0a
	mov DPLatestVolume,#$ff
	mov DPLatestProg,#$00
	mov DPPercFlag,#$00
	mov DPRemainder,#$00
	mov DPatOuttime,#$00
	mov DPatOuttime+1,#$00
	cmp DPActFlag,#$00
	beq ++
	mov a,#$5d ;end latest channel
	call RoutineWriter
++	inc DPActFlag
	mov a,#$5b ;start new channel
	call RoutineWriter
+	mov y,#$0a
	bra CheckDelta
+++	cmp a,#$51 ;tempo
	bne ++
	inc y
	inc y
	mov a,(ReadSeq)+y ;read 1/3
	xcn a
	mov DPStack1,a
	inc y
	mov a,(ReadSeq)+y ;read 2/3
	and a,#$f0
	xcn a
	clrc
	adc a,DPStack1
	lsr a
	cmp a,DPLatestTempo ;check for duplicate
	beq +
	mov DPLatestTempo,a
	push a
	mov a,#$74 ;t
	call RoutineWriter
	pop a
	call RoutineWriteParam
+	inc y ;skip 3/3
	bra CheckDelta
++	inc y
	call RoutineUpdateWord
	mov a,(ReadSeq)+y ;read meta length
	mov y,a
CheckDelta:
	inc y
	mov a,(ReadSeq)+y ;check for note delta
	beq +
	jmp ReadDelta
+	jmp FinishCom

ReadDelta: ;wait for next event in ties
	call RoutineCalcDelta
	jmp FinishCom

RoutineCalcDelta:
	mov DPLatestDelta,#$00
	mov DPLatestDelta+1,#$00
	mov a,(ReadSeq)+y
	bpl +++
	push y
	and a,#$7f
	mov y,#$20
	mul ya
	movw DPLatestDelta,ya
	pop y
--	inc y
	mov a,(ReadSeq)+y
	bmi --
+++ lsr a
	bcc +
	inc DPRemainder
+	lsr a
	bcc +
	inc DPRemainder
+	cmp DPRemainder,#$04 ;even out lost ticks by 2s
	bmi +
	inc a
	mov DPRemainder,#$00
+	clrc
	adc a,DPLatestDelta
	bcc +
	inc DPLatestDelta+1
+	mov DPLatestDelta,a
	push y
	;write out length patterns
---	mov DPCompareDelta+01,#$00
	mov DPCompareDelta,#$00
	mov x,#$01
--	mov a,PresetDuration+x
	mov DPCompareDelta,a
	movw ya,DPLatestDelta
	cmpw ya,DPCompareDelta
	bpl +
	inc x
	bra --
+	movw ya,DPLatestDelta
	subw ya,DPCompareDelta
	movw DPLatestDelta,ya
	mov a,OutDuration+x
	call RoutineWriter
	movw ya,DPLatestDelta
	bne ---
	cmp DPBypass,#$00
	bne +
	mov a,#$5e ;^
	call RoutineWriter
+	mov DPBypass,#$00
	pop y



RoutineMeasurePat:
	push y

	mov a,DPStack2 ;measure length of current pattern
	clrc
	adc a,DPatRuntime
	bcc +
	inc DPatRuntime+1
+	mov DPatRuntime,a

++	mov a,DPStack2 ;measure length of output
	clrc
	adc a,DPatOuttime
	bcc +
	inc DPatOuttime+1
+	mov DPatOuttime,a

--	movw ya,DPatOuttime
	cmpw ya,DPatOutpost ;check if output timer passes one measure, add blanks to differenciate
	bmi ++
	subw ya,DPatOutpost
	movw DPatOuttime,ya
	mov a,#$20
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	bra --

++	cmp ReadTrackX,#$00 ;measure initial pattern lengths on track 0 per phrase
	bne ++
	mov x,#$00
	mov a,DPStack2
	clrc
	adc a,DPatLength+x
	bcc +
	inc DPatLength+1+x
+	mov DPatLength+x,a

++	pop y
	ret


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


RoutineWriteParam: ;parameter converter for XRMosaic
--	bmi +
	cmp a,#$1b
	bmi ++
+	setc
	sbc a,#$1a
	push a
	mov a,#$5a ;Z
	call RoutineWriter
	pop a
	bra --
++	or a,#$40
	call RoutineWriter
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
	or a,#$40
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
+	mov DPStack1,a
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
	adc a,DPStack1
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


PresetHex: ;direct hex to ascii conversion table
	db "0123456789ABCDEF"


PresetNotes: ;note definition per octave
	db "c",$00
	db "k",$00
	db "d",$00
	db "i",$00
	db "e",$00
	db "f",$00
	db "l",$00
	db "g",$00
	db "j",$00
	db "a",$00
	db "h",$00
	db "b",$00

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


base off
fillbyte $ff
fill align 65536
org $010000
db $FF
fill align 256
org $0101FF
db $00


org $000025
dw KonvertInit
org $00002E
db "Song"
org $00004E
db "Game"
org $00007E
db "Comment"
org $0000A9
db "55550000"
org $0000B1
db "Author"

