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
BackSeqMacA: ;backup for subroutine calls
skip 2
BackSeqMacB:
skip 2
BackSeqRepA:
skip 2
BackSeqRepB:
skip 2
BackRepeatA: ;restore amount of repeats
skip 1
BackRepeatB:
skip 1
DPSubFlag:
skip 1
DPRepValA:
skip 1
DPRepValB:
skip 1
DPRepFlag:
skip 1
ReadPat:
skip 2
ReadTrackX: ;0-7,1-8
skip 2
WriteOut:
skip 2
DParamSize:
skip 1
DPNoteBase:
skip 1
DPNoteLength:
skip 1
DPNoteOctave:
skip 1
DPOctLatest:
skip 1
DPNoteKey:
skip 1
DPNoteVol:
skip 1
DPNoteTens:
skip 1
DPNoteHund:
skip 1
DPStack:
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
DPMacroFlag:
skip 1
DPRepeatFlag:
skip 1

org !OutAddr+256
base !OutAddr
	db "#amk 2 #samples {#default }"
	db $0d
	db $0a
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
	bne ++
	dec y
	mov a,(ReadSeq)+y
	beq +
	inc y
	mov a,(ReadSeq)+y
	bra ++
+	pop a
	inc ReadTrackX
	cmp ReadTrackX,#$08
	bmi +
-	nop
	bra -
+	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern
++	mov y,a
	pop a
	addw ya,ReadPat
	movw ReadSeq,ya
	jmp ReadSequence

ReadSequence:
	mov y,#$00
	mov a,(ReadSeq)+y
	clrc
	adc a,#$10
	bpl +
	jmp VoiceCommandRun ;treat 70+ (80+) as voice commands
+	setc
	sbc a,#$10
	and a,#$f0
	xcn a
	asl a
	mov x,a
	mov a,VoiceCategory+1+x
	push a
	mov a,VoiceCategory+x
	push a
	ret

VoiceCategory:
	dw VoiceNoteBase
	dw VoiceNoteLength
	dw VoiceTwo
	dw VoiceInvalid
	dw VoiceOctave
	dw VoiceQuant
	dw VoiceInvalid
	dw VoiceCommandRun

VoiceInvalid:
-	nop
	bra -

VoiceTwo:
	mov y,#$01
	call RoutineUpdateWord
	jmp ReadSequence

VoiceNoteBase:
	mov a,(ReadSeq)+y
	asl a
	mov x,a
	mov a,PresetNotes+x
	call RoutineWriter
	mov a,PresetNotes+1+x
	beq ++
	call RoutineWriter ;account for sharps and flats
++	mov a,#$3d ;=
	call RoutineWriter
	mov a,DPNoteBase
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VoiceNoteLength:
	mov a,(ReadSeq)+y ;recieve note from octave
	and a,#$0f
	asl a
	mov x,a
	mov a,PresetNotes+x
	call RoutineWriter ;write note letter
	mov a,PresetNotes+1+x
	beq ++
	call RoutineWriter ;account for sharps and flats
++	mov a,#$3d ;=
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;recieve note custom length
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VoiceOctave:
	mov a,(ReadSeq)+y
	and a,#$0f
	bne + ;00 = absolute, 01-07 increase, 09-0F decrease
--	mov a,#$6f ;o
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;get absolute octave
	dec a
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	bra +++


+	cmp a,#$08
	beq --
	bpl ++
	mov DPStack,a
---	mov a,#$3e ;>
	call RoutineWriter
	dec DPStack
	bne ---
	bra +++


++	mov DPStack,a
	mov a,#$10
	setc
	sbc a,DPStack

	mov DPStack,a
--- mov a,#$3c ;<
	call RoutineWriter
	dec DPStack
	bne ---


+++	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VoiceQuant:
	mov a,#$71 ;q
	call RoutineWriter
	mov a,(ReadSeq)+y
	and a,#$0f
	dec a
	lsr a
	inc a
	xcn a
	dec a
	call RoutineWriteItself
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


	
VoiceCommandRun: ;70-8F
	mov DParamSize,#$00
	and a,#$7f
	asl a
	mov x,a
	mov a,PresetVCMD+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMD+x
	push a
	ret

VoiceCommandParam:
-	nop
	bra -


PresetHex: ;direct hex to ascii conversion table
	db "0123456789ABCDEF"

PresetNotes: ;rest + note definition per octave
	db "r",$00
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

PresetVCMD:
	dw VCMDTempo ;70
	dw VCMDBaseLen ;71
	dw VCMDInst ;72
	dw VCMDVolumeAbs ;73
	dw VCMDVolumeRel ;74
	dw VCMDRepeat ;75
	dw VoiceInvalid ;76
	dw VoiceInvalid ;77
	dw VCMDJump ;78
	dw VoiceInvalid ;79
	dw VoiceInvalid ;7a
	dw VoiceInvalid ;7b
	dw VoiceInvalid ;7c
	dw VCMDMacroBegin ;7d
	dw VCMDMacroEnd	;7e
	dw VCMDTrackEnd	;7f
	dw VCMDUnk80 ;80
	dw VoiceInvalid ;81
	dw VCMDPan ;82
	dw VCMDTune ;83
	dw VCMDExpOn ;84
	dw VCMDExpOff ;85
	dw VCMDBend ;86
	dw VCMDEnvPitch ;87
	dw VCMDEnvChan ;88
	dw VCMDEnvDis ;89
	dw VCMDEcho1 ;8a
	dw VCMDEcho2 ;8b
	dw VCMDEchoOff ;8c
	dw VoiceInvalid ;8d
	dw VoiceInvalid ;8e
	dw VCMDEchoOf2 ;8f

VCMDUnk80:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDTempo:
	mov a,#$e2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	lsr a
	lsr a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDBaseLen:
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteBase,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDInst:
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDVolumeAbs:
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteVol,a
	mov a,DPNoteVol
	bpl +
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
+	asl a
;	asl a
;	asl a
	mov x,a
	mov a,PresetVolumes+x
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDVolumeRel:
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	bra +
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
	mov DPStack,a
	mov a,DPNoteVol
	setc
	sbc a,DPStack
	bra ++
+	clrc
	adc a,DPNoteVol
++	mov DPNoteVol,a
	mov a,DPNoteVol
	bpl +
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
+	asl a
;	asl a
;	asl a
	mov x,a
	mov a,PresetVolumes+x
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDRepeat: ;repeat, end at $00
	inc y
	mov a,(ReadSeq)+y
	bne +++
	mov a,DPRepValA
	mov (ReadSeq)+y,a ;if zero, restore source value
	dec DPRepFlag
	cmp DPRepFlag,#$00
	bne ++
	movw ya,ReadSeq
	cmpw ya,BackSeqRepA
--- bne +
	mov a,#$5d ;end double bracket
	call RoutineWriter
;	mov a,#$5d
;	call RoutineWriter
	mov a,DPRepeatFlag
	call RoutineHexDecimal
	mov DPRepeatFlag,#$00
;	movw ya,BackSeqRepA
;	movw ReadSeq,ya
+	mov y,#$04 ;skip word pointer
	call RoutineUpdateWord
	jmp ReadSequence

++	mov a,DPRepValB
	mov (ReadSeq)+y,a
	movw ya,ReadSeq
	cmpw ya,BackSeqRepB
	bra ---

+++	cmp DPRepFlag,#$00
	bne +++
	mov DPRepValA,a
	mov DPRepeatFlag,a
	mov y,#$01
	mov a,#$00
	mov (ReadSeq)+y,a
	inc y
	mov a,(ReadSeq)+y ;low relative dir
	push a
	inc y
	mov a,(ReadSeq)+y ;high relative dir
	push a
	mov a,#$5b ;start double bracket
	call RoutineWriter
;	mov a,#$5b
;	call RoutineWriter
	inc y
	push y
	movw ya,ReadSeq
	movw BackSeqRepA,ya
---	pop y
	call RoutineUpdateWord
	pop a
	mov y,a
	pop a
	addw ya,ReadSeq ;calc relative to absolute
	movw ReadSeq,ya
	inc DPRepFlag ;mark repeat
	jmp ReadSequence


+++	mov DPRepValB,a
	mov DPRepeatFlag,a
	mov y,#$01
	mov a,#$00
	mov (ReadSeq)+y,a
	inc y
	mov a,(ReadSeq)+y ;low relative dir
	push a
	inc y
	mov a,(ReadSeq)+y ;high relative dir
	push a
	mov a,#$5b ;start double bracket
	call RoutineWriter
;	mov a,#$5b
;	call RoutineWriter
	inc y
	push y
	movw ya,ReadSeq
	movw BackSeqRepB,ya
	bra ---

-	nop
	bra -

VCMDJump: ;treat jumps, reached end of track
-	mov DPSubFlag,#$00
	mov DPRepeatFlag,#$00
	mov DPNoteBase,#$00
	mov DPNoteKey,#$00
	mov DPNoteLength,#$00
	mov DPNoteOctave,#$00
	mov DPNoteVol,#$00
	inc ReadTrackX
	cmp ReadTrackX,#$08
	bmi +
-	nop
	bra -
+	movw ya,ReadPat
	movw ReadSeq,ya
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	jmp KonvertReadPattern

VCMDMacroBegin:
	cmp DPMacroFlag,#$00
	bne +++
	inc DPMacroFlag ;enable macro flag
	inc y
	mov a,(ReadSeq)+y ;low relative dir
	push a
	inc y
	mov a,(ReadSeq)+y ;high relative dir
	push a
;	mov a,#$5b ;add brackets to signify re-use
;	call RoutineWriter
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeqMacA,ya ;store a backup for macro return
---	pop a
	mov y,a
	pop a
	addw ya,ReadSeq ;calc relative to absolute
	movw ReadSeq,ya
	jmp ReadSequence


+++	inc DPMacroFlag ;enable macro flag
	inc y
	mov a,(ReadSeq)+y ;low relative dir
	push a
	inc y
	mov a,(ReadSeq)+y ;high relative dir
	push a
;	mov a,#$5b ;add brackets to signify re-use
;	call RoutineWriter
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeqMacB,ya ;store a backup 2 for macro return
	bra ---
	

VCMDMacroEnd: ;only end if macros were active
	cmp DPMacroFlag,#$00
	bne +
	inc y
	call RoutineUpdateWord
	jmp ReadSequence
+	dec DPMacroFlag
	bne +++
;	mov a,#$5d ;end macro bracket
;	call RoutineWriter
	movw ya,BackSeqMacA
---	movw ReadSeq,ya
	jmp ReadSequence
+++	movw ya,BackSeqMacB
	bra ---

VCMDTrackEnd:
	jmp VCMDJump

VCMDPan:
	mov a,#$db
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	clrc
	adc a,#$40 ;centered -> 00 -> 40 -> 80 -> 08 -> 0A
	asl a
	xcn a
	mov DPStack,a
	mov a,#$10
	setc
	sbc a,DPStack
	and a,#$0f
	inc a
	inc a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDTune:
	mov a,#$ee
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y 
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDExpOn:
	mov a,#$de
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;duration
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;amplitude
	call RoutineWriteHex
	inc y ;flags (skipped)
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDExpOff:
	mov a,#$df
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDBend:
	mov a,#$dd
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;duration
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;target (note from octave)
	and a,#$0f
	asl a
	mov x,a
	mov a,PresetNotes+x
	call RoutineWriter
	mov a,PresetNotes+1+x
	beq +
	call RoutineWriter
+	mov a,#$20 ;add empty space
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDEnvPitch:
	mov a,#$eb
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;duration
	call RoutineWriteHex
	inc y ;skip unknown
	inc y 
	mov a,(ReadSeq)+y ;transpose
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDEnvChan:
-	nop
	bra -

VCMDEnvDis:
	mov a,#$fe
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDEcho1:
	mov a,#$f1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,#$01 ;avoid FIR overflow
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDEcho2:
	mov a,#$ef
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDEchoOf2:
	inc y
VCMDEchoOff:
	mov a,#$f0
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


RoutineCloseLoop:
	mov a,#$5d ;close bracket
	call RoutineWriter
	mov a,DPSubFlag
	call RoutineHexDecimal
	mov DPSubFlag,#$00
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