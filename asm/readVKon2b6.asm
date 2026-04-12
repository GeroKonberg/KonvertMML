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
DPatFlag: ;how many repeats are left, if specified
skip 1
DPSum1:
skip 1
DPSum2:
skip 1
DPQuant:
skip 1
DPBypass:
skip 1
DPRepValA:
skip 1
DPRepValB:
skip 1
DPVoltaFlag:
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
	mov a,KonvertSet+2 ;store song ID (-1) to read
	dec a
	asl a
	mov y,a
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	mov y,a
	pop a
	movw ReadSeq,ya 
	movw ReadPat,ya ;write pattern location for above song
	mov a,KonvertSet+4
	mov y,a
	mov a,KonvertSet+3
	movw WriteOut,ya
	jmp KonvertReadPattern

KonvertSet:
	dw !ReadAddr
	db !ReadIndex
	dw !OutAddr+32

KonvertReadPattern:
	;read 2x8 pattern index from channel 0-7
	mov a,ReadTrackX
	asl a
	mov y,a
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	bne +++ ;read pattern address, otherwise fill in rests on zeroes
	pop a
	inc DPatPhrase
--	mov a,DPatMirror+1 ;check pattern length (high bit->2x128 notes)
	beq ++
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;equal
	call RoutineWriter
	mov a,#$80
	call RoutineHexDecimal
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;equal
	call RoutineWriter
	mov a,#$80
	call RoutineHexDecimal
	dec DPatMirror+1
	bra --
++	mov a,DPatMirror  ;check pattern length (low bit->remainders)
	beq ++
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;equal
	call RoutineWriter
	mov a,DPatMirror ;get remainder
	call RoutineHexDecimal
++	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern
+++	mov y,a
	pop a
	movw ReadSeq,ya
	jmp ReadSequence

ReadSequence:
	mov a,DPatMirror+1
	bne +
	mov a,DPatMirror
	beq ++
+	movw ya,DPatRuntime 
	cmpw ya,DPatMirror
	bne ++
;	jmp ForceInterrupt
++	mov y,#$00
	mov a,(ReadSeq)+y
	bne +
	jmp VoiceInterrupt
+	bmi +
	cmp a,#$60
	bmi ++
	jmp KonamiVoiceEvent0
++
-	jmp KonamiNoteEvent
+	cmp a,#$e0
	bmi -
	jmp KonamiVoiceEvent1


KonamiNoteEvent:
	mov a,(ReadSeq)+y ;read note key
	and a,#$7f
	mov DPNoteLatest,a
	mov a,(ReadSeq)+y
	bmi +++ ;skip note length on upper bit
	inc y
	mov a,(ReadSeq)+y ;read note length
	mov DPNoteLength,a
+++	inc y
	mov a,(ReadSeq)+y
	bmi +++ ;skip quantization on upper bit
	and a,#$f0
	mov DPNoteQuant,a
++	inc y
	mov a,(ReadSeq)+y ;read velocity
+++ call RoutineGetForte
	cmp DPKitFlag,#$00 ;check for percussion notes
	beq ++
	mov a,#$da ;intepret percussion as program changes
	call RoutineWriteHex
	mov a,DPNoteLatest
	call RoutineWriteHex
	mov DPNoteLatest,#$30 ;o4c
++	mov a,DPNoteLatest
	call RoutineGetNote
	mov DPOctLatest,DPNoteOctave
	mov a,#$3d ;=
	call RoutineWriter
	mov a,DPNoteLength ;convert hex to decimal length (up to =127 supported)
	call RoutineHexDecimal
	jmp FinishCom

KonamiVoiceEvent0:
	and a,#$1f ;60-7f
	bne +
	inc DPKitFlag
	jmp FinishCom
+	cmp a,#$01
	bne +
	mov DPKitFlag,#$00
	jmp FinishCom
+	
	jmp FinishCom ;todo: add tuning converter here

KonamiVoiceEvent1:
	and a,#$1f ;e0-ff
	asl a
	mov x,a
	mov a,PresetKonamiIndex1+1+x ;jump to special Betop VCMD
	push a
	mov a,PresetKonamiIndex1+x
	push a
	ret

PresetKonamiIndex1:
	dw VcmdE0rest	;e0
	dw VcmdE1tie	;e1
	dw VcmdE2inst	;e2
	dw VcmdE3pan	;e3
	dw VcmdE4vibrato	;e4
	dw VcmdE5	;e5
	dw VcmdE6lp1start	;e6
	dw VcmdE7lp1end	;e7
	dw VcmdE8lp2start	;e8
	dw VcmdE9lp2end	;e9
	dw VcmdEAbpm	;ea
	dw VcmdEBbpmfade	;eb
	dw VcmdECkeydiff	;ec
	dw VcmdED	;ed
	dw VcmdEEvol	;ee
	dw VcmdEF	;ef
	dw VcmdF0porta	;f0
	dw VcmdF1envb	;f1
	dw VcmdF2fine	;f2
	dw VcmdF3bend	;f3
	dw VcmdF4echo1	;f4
	dw VcmdF5echo2	;f5
	dw VcmdF6voltaSet	;f6
	dw VcmdF7voltaCall	;f7
	dw VcmdF8	;f8
	dw VcmdF9	;f9
	dw VcmdFAadsrg	;fa
	dw VcmdFB	;fb
	dw VcmdFCvolprog	;fc
	dw VcmdFDjmp	;fd
	dw VcmdFEsubcall	;fe
	dw VcmdFFend	;ff

FinishCom:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdE0rest:	;e0
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;param1
	mov DPNoteLength,a
	call RoutineHexDecimal
	jmp FinishCom


VcmdE1tie:	;e1
	inc y
	inc y ;param 2 (velocity)
	mov a,(ReadSeq)+y
	call RoutineGetForte
	dec y
	mov a,(ReadSeq)+y ;param1 (note len)
	mov DPNoteLength,a
	call RoutineHexDecimal
	mov a,#$5e ;^
	call RoutineWriter
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	jmp FinishCom


VcmdE2inst:	;e2
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	jmp FinishCom


VcmdE3pan:	;e3
	mov a,#$db
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	lsr a
	call RoutineWriteHex
	jmp FinishCom


VcmdE4vibrato:	;e4
	mov y,#$03
	mov a,(ReadSeq)+y ;check if vibrato should be toggled or not
	bne ++
	mov a,#$df
	call RoutineWriteHex
	jmp FinishCom
++	mov a,#$de
	call RoutineWriteHex
	mov y,#$01
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	lsr a
	lsr a
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param3
	call RoutineWriteHex
	jmp FinishCom


VcmdE5:	;e5
-	nop
	bra -


VcmdE6lp1start:
	mov a,#$20 ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$20 ;start double bracket
	call RoutineWriter
	jmp FinishCom


VcmdE7lp1end:
	mov a,#$20 ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	bne +
	mov a,#$02 ;in case of forever loops
+	call RoutineHexDecimal
	inc y ;skip unknown 
	inc y
	jmp FinishCom
	

VcmdE8lp2start:	;e8
	mov a,#$20 ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$5b ;start double bracket
	call RoutineWriter
	mov a,#$20 ;start double bracket
	call RoutineWriter
	jmp FinishCom


VcmdE9lp2end:	;e9
	mov a,#$20 ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	bne +
	mov a,#$02 ;in case of forever loops
+	call RoutineHexDecimal
	inc y ;skip unknown 
	inc y
	jmp FinishCom


VcmdEAbpm: ;ea
	inc y
	cmp ReadTrackX,#$00 ;check for redundant tempo usage
	bne +++
	mov a,#$74 ;t
	call RoutineWriter
	mov a,(ReadSeq)+y ;param1
	lsr a
	lsr a
	dec a
	call RoutineHexDecimal
+++	jmp FinishCom


VcmdEBbpmfade:	;eb
	inc y
	inc y
	cmp ReadTrackX,#$00 ;check for redundant tempo usage
	bne +++
	mov a,#$e3
	call RoutineWriteHex
	mov a,(ReadSeq)+y ;param2 fade
	call RoutineWriteHex
	dec y
	mov a,(ReadSeq)+y ;param1 target
	lsr a
	lsr a
	dec a
	call RoutineWriteHex
	inc y
+++	jmp FinishCom


VcmdECkeydiff: ;ec
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


VcmdED:	;ed
-	nop
	bra -


VcmdEEvol:	;ee
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	jmp FinishCom


VcmdEF:	;ef
-	nop
	bra -


VcmdF0porta:	;f0
	inc y ;skip for now
	jmp FinishCom


VcmdF1envb:	;f1
	mov a,#$eb
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param3 diff
	call RoutineWriteHex
	inc y ;skip deltas
	inc y
	jmp FinishCom


VcmdF2fine:	;f2
	inc y
	jmp FinishCom


VcmdF3bend:	;f3
	mov a,#$dd
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param3 note
	eor a,#$80
	setc
	sbc a,#$0c
	call RoutineWriteHex
	inc y ;skip deltas
	inc y
	inc y
	jmp FinishCom


VcmdF4echo1:	;f4
	mov a,#$ef
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param3
	call RoutineWriteHex
	jmp FinishCom


VcmdF5echo2:	;f5
	mov a,#$f1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	inc y
	mov a,#$01 ;param3
	call RoutineWriteHex
	jmp FinishCom


VcmdF6voltaSet:	;f6
	and DPVoltaFlag,#$7f
	inc DPVoltaFlag
	call RoutineGetVolta
	mov a,#$5b	;square bracket start
	call RoutineWriter
	mov a,#$20 ;differenciate this from loops/macros
	call RoutineWriter
	jmp FinishCom


VcmdF7voltaCall:	;f7
	cmp DPVoltaFlag,#$00 ;only end square bracket after $f6
	bmi ++
	mov a,#$5d	;square bracket end
	call RoutineWriter
	eor DPVoltaFlag,#$80
	bra +++
++	call RoutineGetVolta
+++	mov a,#$01
	call RoutineHexDecimal
	jmp FinishCom


RoutineGetVolta:
	mov a,#$28  ;round bracket start
	call RoutineWriter
	mov a,ReadTrackX
	clrc
	adc a,#$30
	call RoutineWriter
	mov a,DPVoltaFlag ;get current track + voltage level
	and a,#$7f
	call RoutineHexDecimal
	mov a,#$29  ;round bracket end
	call RoutineWriter
	ret


VcmdF8:	;f8
-	nop
	bra -


VcmdF9:	;f9
-	nop
	bra -


VcmdFAadsrg:	;fa
	mov y,#$03
	mov a,(ReadSeq)+y ;read GAIN (if specified)
	beq ++
	mov a,#$ed
	call RoutineWriteHex
	mov a,#$80
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	setc
	sbc a,#$28
	call RoutineWriteHex
++	mov a,#$ed
	call RoutineWriteHex
	mov y,#$01
	mov a,(ReadSeq)+y ;param1
	and a,#$7f
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	inc y ;skip GAIN param
	jmp FinishCom


VcmdFB:	;fb
-	nop
	bra -


VcmdFCvolprog:	;fc
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param1
	call RoutineWriteHex
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;param2
	call RoutineWriteHex
	jmp FinishCom


VcmdFDjmp:	;fd
	inc y
	inc y
	jmp FinishCom


VcmdFEsubcall:	;fe
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	mov a,#$01
	mov DPSubFlag,a ;store repeat calls for later
	mov a,#$5b
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeq,ya ;store a backup for return
	pop a
	mov y,a
	pop a
	movw ReadSeq,ya ;read from subroutine
	jmp ReadSequence


VcmdFFend:	;ff
VoiceInterrupt: ;00
	cmp DPSubFlag,#$00 ;check for subroutines
	bne ++
ForceInterrupt:
	inc ReadTrackX
	cmp ReadTrackX,#$06
	bmi +
-	nop
	bra -
+	mov DPatRuntime,#$00
	mov DPatRuntime+1,#$00
	mov DPatSubtime,#$00
	mov DPatSubtime+1,#$00
	cmp DPSubFlag,#$00
	beq +
	call RoutineCloseLoop
+	mov DPatPhrase,#$00
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
	mov DPVoltaFlag,#$00
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern

++	call RoutineCloseLoop
	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence


VoiceNoteEvent: ;01-DF
	mov a,(ReadSeq)+y ;read note
	cmp a,#$4a ;drums (4A-5F)
	bmi +
	push a
	mov a,#$40 ;\@ setup drum kits
	call RoutineWriter
	mov a,#$32
	call RoutineWriter
	pop a
	setc
	sbc a,#$49
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	mov a,#$24
+	call RoutineGetNote 
++	mov a,#$3d ;=
	call RoutineWriter
	mov a,DPNoteLength ;convert hex to decimal length (up to =127 supported)
+++	mov DPNoteTens,#$00
	mov DPNoteHund,#$00
-	inc DPNoteTens
	setc
	sbc a,#$0a
	bcs -
	adc a,#$0a
	dec DPNoteTens
+	mov DPStack,a
-	mov a,DPNoteTens
	cmp a,#$10
	bmi ++
	inc DPNoteHund
	clrc
	and DPNoteTens,#$0f
	adc DPNoteTens,#$06
	bra -
++	xcn a
	and a,#$f0
	clrc
	adc a,DPStack
	daa a
	bcc +
	inc DPNoteHund
+	mov DPNoteTens,a
	mov a,DPNoteHund
	beq +
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write hundreds (if given)
+	mov a,DPNoteTens
	and a,#$f0
	xcn a
;	beq +
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write tens (if given)
+	mov a,DPNoteTens
	and a,#$0f
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write ones (mandatory)
	inc y
	call RoutineUpdateWord
	call RoutineMeasurePat
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence
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
;	clrc
;	adc a,#$04 ;correct to C neutral
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
++	ret


RoutineGetForte:
	and a,#$7f
	asl a
	and a,#$f0
	xcn a
	mov DPNoteVel,a
	clrc
	adc a,DPNoteQuant
	cmp a,DPNoteParam ;compare for qXY parameter differences
	beq ++
	mov DPNoteParam,a
	mov a,#$71 ;q
	call RoutineWriter
	mov a,DPNoteParam
	call RoutineWriteItself
++	ret


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
	
	