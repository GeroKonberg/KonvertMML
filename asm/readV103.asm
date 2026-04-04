norom
arch spc700-raw
dpbase $0000
optimize dp always

;direct page


org $01016C
db $E0 ;disable audio/echo writes at all cost



org $000000
incbin "asm/SPCBase.bin" ;insert SPC header here
org $000025
dw KonvertInit
org $000100
base $000000 ;zero page


ReadSeq:
skip 2
BackSeq: ;backup for subroutine calls
skip 2

ReadPat:
skip 2
ReadTrackX: ;0-7,1-8
skip 2

WriteOut:
skip 2
DPSubFlag:
skip 1
DParamSize:
skip 1

DPNoteLatest:
skip 1
DPNoteLength:
skip 1
DPNoteOctave:
skip 1
DPOctLatest:
skip 1



DPNoteKey:
skip 1
DPNoteTrans:
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
DPatTracks:
skip 1

DPSum1:
skip 1
DPSum2:
skip 1
DPQuant:
skip 1
DPEchoVol:
skip 1



DPRestFlag:
skip 1
DPNoteFlag:
skip 1
DPBendFlag:
skip 1

org $0300
base $0200
	db "#amk 2 #samples {#default }"
	db $20
	db $20
	db "#0 "

org $8100
base $8000 ;bypass driver code with a converter
	incbin "inputSQ.hex"

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
	mov a,y
	mov y,#$80
	movw ReadSeq,ya
	mov y,#$02
	mov a,#$20
	movw WriteOut,ya
	jmp KonvertReadPattern


KonvertReadPattern:
	;distinguish between tracks
---	mov y,#$00
	mov a,(ReadSeq)+y
	beq +++
	cmp a,#$cc
	bne +
	mov DPNoteOctave,#$00
	mov DPNoteLatest,#$00
	mov DPNoteLength,#$00
	mov DPNoteKey,#$00
	mov DPRestFlag,#$00
	mov DPNoteFlag,#$00
	mov DPBendFlag,#$00
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	inc ReadTrackX
	jmp ReadSequence
+	cmp a,#$cd
	bne +
+++	inc y
	call RoutineUpdateWord
	bra ---
+
-	nop
	bra -

ReadSequence:
	mov y,#$00
	mov a,(ReadSeq)+y
	and a,#$e0
	xcn a
	mov x,a
	mov a,VoiceCategory+1+x
	push a
	mov a,VoiceCategory+x
	push a
	ret

VoiceCategory:
	dw VoiceNoteRel ;00-1f
	dw VoiceInvalid ;20-3f
	dw VoiceDurTie ;40-5f
	dw VoiceDurRest ;60-7f
	dw VoiceForceRest ;80-9f
	dw VoiceBendA ;a0-bf
	dw VoiceCommandRun ;c0-df
	dw VoiceBendE ;e0-ff

VoiceBendA:
	mov DPNoteFlag,#$00
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VoiceBendE:
	mov a,(ReadSeq)+y
	and a,#$e0
	mov (ReadSeq)+y,a
	mov DPNoteFlag,#$00

	call RoutineUpdateWord
	inc DPBendFlag
	mov DPNoteFlag,#$00
	jmp VoiceForceTie
	inc y
	call RoutineUpdateWord
	jmp ReadSequence
	jmp VoiceDurTie
	
VoiceNoteRel:
	inc DPNoteFlag
	mov a,(ReadSeq)+y
	beq ++
	cmp a,#$10 ;10-1f -> subtract note
	bmi +
	eor a,#$e0
+	clrc
	adc a,DPNoteLatest
	mov DPNoteLatest,a
VoiceNoteEvent: 
++	mov DPNoteOctave,#$00
	mov a,DPNoteLatest
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
++	mov y,#$01
	call RoutineUpdateWord
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence


VoiceInvalid:
-	nop
	bne -

VoiceDurTie:
	cmp DPNoteFlag,#$00
	bne +++
	cmp DPRestFlag,#$00 ;if preceded by rest, use rest instead of a tie
	beq +
	mov DPRestFlag,#$00
	mov a,#$72 ;r
	bra ++
VoiceForceTie:
--
+	mov a,#$5e ;^
++	call RoutineWriter
	bra +++


VoiceDurRest: ;60-7f duration with rest
	inc DPRestFlag
	cmp DPBendFlag,#$00
	beq ++
	mov DPBendFlag,#$00
	bra --
++	cmp DPNoteFlag,#$00
	beq --

---
+++	mov DPNoteFlag,#$00
	mov a,#$3d  ;=
	call RoutineWriter
	mov a,(ReadSeq)+y
	and a,#$1f
	inc a
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	jmp ReadSequence
	
VoiceForceRest: ;80-9f force rest(?)
;	inc DPRestFlag
	inc y
	bra ---

VoiceCommandRun: ;C0-DF
	mov a,(ReadSeq)+y
	and a,#$1f
	asl a
	mov x,a
	mov a,PresetVCMD+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMD+x
	push a
	ret

PresetVCMD:
	dw VoiceMod ;c0
	dw VCMDSkip1 ;c1
	dw VCMDVolume ;c2
	dw VCMDPan ;c3

	dw VCMDSkip1
	dw VoiceInvalid
	dw VCMDSkip1 ;c6
	dw VCMDSkip1 ;c7

	dw VoiceInvalid
	dw VoiceInvalid
	dw VCMDSkip1 ;ca VCMDInst
	dw VoiceInvalid

	dw VoiceInvalid
	dw KonvertReadPattern ;cd
	dw VoiceInvalid
	dw VCMDSkip1 ;cf


	dw VCMDNoteAbs ;d0
	dw VoiceInvalid
	dw VoiceInvalid
	dw VoiceInvalid

	dw VoiceInvalid
	dw VoiceInvalid
	dw VCMDTune ;d6
	dw VCMDRest255 ;d7

	dw VCMDVelocity
	dw VCMDVelocity
	dw VCMDVelocity
	dw VCMDVelocity

	dw VCMDVelocity
	dw VCMDVelocity
	dw VCMDVelocity
	dw VCMDVelocity

VoiceMod: ;c0 disable/enable vibrato
	inc y
	mov a,(ReadSeq)+y
	bne ++
	mov a,#$df
	call RoutineWriteHex
	bra +++
++  mov a,#$de
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	xcn a
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	xcn a
	asl a
	asl a
	call RoutineWriteHex
+++	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDVolume: ;c2
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	asl a
	mov x,a
	mov a,PresetVolumes+x
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDPan: ;c3
	mov a,#$db
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;40 = center (00L-7FR)
	lsr a
	lsr a
	lsr a
	mov DPStack,a
	mov a,#$10
	setc
	sbc a,DPStack
	inc a
	inc a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDInst: ;ca
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;p1
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDNoteAbs: ;d0
	inc DPNoteFlag
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteLatest,a
	call RoutineUpdateWord
	jmp VoiceNoteEvent

VCMDTune: ;d6
	mov a,#$ee
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;p1
	asl a
	setc
	sbc a,#$80
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDRest255: ;d7
	mov a,#$72 ;r
	call RoutineWriter
	mov a,#$3d ;=
	call RoutineWriter
	mov a,#$ff
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDVelocity: ;d8
	mov a,#$71 ;q
	call RoutineWriter
	mov a,(ReadSeq)+y
	and a,#$07
	asl a
	inc a
	eor a,#$70
	call RoutineWriteItself
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDSkip1:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence




VoiceInterrupt: ;00, always return to a backup in third->second layer
	cmp DPSubFlag,#$00
	bne ++
ForceInterrupt:
	inc ReadTrackX
	cmp ReadTrackX,DPatTracks
	bmi +
-	nop
	bra -
+	mov DPatPhrase,#$00
	mov DPNoteOctave,#$00
	mov DPOctLatest,#$00
	mov DPNoteLength,#$00
	mov DPNoteKey,#$00
	mov DPNoteTrans,#$00
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
+	jmp KonvertReadPattern


-	nop
	bra -
++	call RoutineCloseLoop
	movw ya,BackSeq
	movw ReadSeq,ya
---	mov y,#$01
	call RoutineUpdateWord
	jmp ReadSequence
 

	




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

base off
fillbyte $ff
fill align 65536
org $010000
db $FF
fill align 256
org $0101FF
db $00
