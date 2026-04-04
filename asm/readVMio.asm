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
BackSeq: ;backup for subroutine calls
skip 2
DPSubFlag:
skip 1
ReadPat:
skip 2
ReadTrackX: ;0-7,1-8
skip 2
WriteOut:
skip 2
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
DPatLength: ;measure total pattern lengths for channel 0
skip 32
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
DPRepFlag:
skip 1

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
	mov y,#$00
-	mov a,(ReadSeq)+y ;skip until ff has been encountered
	cmp a,#$ff
	beq +
	inc y
	bra -
+	inc y
	mov a,(ReadSeq)+y ;register amount of tracks to read from
	mov DPatTracks,a
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
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
	movw ya,ReadPat
	movw ReadSeq,ya
	mov a,ReadTrackX
	asl a
	mov y,a
	call RoutineUpdateWord
	mov y,#$00
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	call RoutineUpdateWord
	pop a
	mov y,a
	pop a
	addw ya,ReadSeq
	movw ReadSeq,ya
	jmp ReadSequence

ReadSequence:
	mov y,#$00
	mov a,(ReadSeq)+y
	bne +
	jmp VoiceInterrupt ;interrupt on 00
+	bmi +
-	jmp VoiceNoteEvent
+	and a,#$7f
	cmp a,#$5a ;80-D9 -> notes, DA-FF -> VCMDs
	bmi -
	or a,#$80
	jmp VoiceCommandRun



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
 

VoiceNoteEvent: ;01-D9
	mov a,(ReadSeq)+y ;read note
	bmi +++
	mov DPNoteLength,a ;store 00-7F param 1 as note length for later
	inc y
	mov a,(ReadSeq)+y
	bmi +++
	push a
	mov a,#$71 ;q, write 00-7F param 2 as quantization
	call RoutineWriter
	pop a
	push a
	call RoutineWriteItself
	pop a
	and a,#$70
	mov DPQuant,a
	inc y
	mov a,(ReadSeq)+y
+++ cmp a,#$c8 ;compare for other types of notes
	bne +
++	mov a,#$5e ;tie (^)
	call RoutineWriter
	bra ++
+	cmp a,#$c9
	bne +
	mov a,#$72 ;rest (r)
	call RoutineWriter
	bra ++
+	mov DPNoteOctave,#$01
	and a,#$7f
	cmp a,#$4a ;drums (4A-59)
	bmi +
	dec y
	cmp a,#$5a ;anything above 5A/DA is a command
	bpl ---
	inc y 
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
+	clrc
	adc a,DPNoteTrans ;adjust to transposition
	mov DPNoteLatest,a ;store latest note for bends
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
++	mov a,#$3d ;=
	call RoutineWriter
	mov DPNoteTens,#$00
	mov DPNoteHund,#$00
	mov a,DPNoteLength ;convert hex to decimal length (up to =127 supported)
-	cmp a,#$0b
	bmi +
	inc DPNoteTens
	setc
	sbc a,#$0a
	bra -
+	mov DPStack,a
	mov a,DPNoteTens
	xcn a
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
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence
-	nop
	bra -
	
VoiceCommandRun: ;DA-FF
	mov DParamSize,#$00
	setc
	sbc a,#$da
	asl a
	mov x,a
	mov a,PresetVCMD+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMD+x
	push a
	ret

PresetVCMD:
	dw VcmdDA
	dw VcmdSkip2 ;todo: DB volume echoes
	dw VcmdSkip2
	dw VcmdSkip2
	dw VcmdDE
	dw VcmdTempo
	dw VcmdSkip2
	dw VcmdGlobeVol
	dw VcmdE2
	dw VcmdEchoVol
	dw VcmdE4
	dw VcmdSkip2
	dw VcmdE6
	dw VcmdEchoSet
	dw VcmdInst
	dw VcmdSkip2
	dw VcmdKey
	dw VcmdVolume
	dw VcmdVolFade
	dw VcmdPan
	dw VcmdEE
	dw VcmdEchoOn
	dw VcmdEchoOff
	dw VcmdDetune
	dw VcmdVibrato
	dw VcmdVibOff
	dw VcmdTremolo
	dw VcmdTremOff
	dw VcmdPortaSet
	dw VcmdPortaOn
	dw VcmdPortaOff
	dw VcmdQuant
	dw VcmdLegOn
	dw VcmdLegOff
	dw VcmdRoutine
	dw VcmdLoopStart
	dw VcmdLoopEnd
	dw ForceInterrupt

VcmdDA:
-	nop
	bra -

VcmdDB:
-	nop
	bra -

VcmdDC:
-	nop
	bra -

VcmdDD:
-	nop
	bra -

VcmdDE:
-	nop
	bra -

VcmdTempo:
	mov a,#$e2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	lsr a
	lsr a
	lsr a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE0:
-	nop
	bra -

VcmdGlobeVol:
	mov a,#$e0
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	asl a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE2:
-	nop
	bra -

VcmdEchoVol:
	inc y
	mov a,(ReadSeq)+y
	asl a
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
	mov DPEchoVol,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE4:
-	nop
	bra -

VcmdE6:
	inc y
	mov a,(ReadSeq)+y ;repeat parameters
	push a
	inc y
	call RoutineUpdateWor 
	pop a



-	nop
	bra -

VcmdEchoSet:
	mov a,#$f1
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;echo delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;echo feedback
	call RoutineWriteHex
	inc y
	mov a,#$01 ;echo fir
	call RoutineWriteHex
	mov a,#$f2
	call RoutineWriteHex
	mov a,#$02
	call RoutineWriteHex
	mov a,DPEchoVol
	call RoutineWriteHex
	mov a,DPEchoVol
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdInst:
	mov a,#$da
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdSkip2:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdKey: ;transpose for note conversion
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteTrans,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdVolume:
	mov a,#$e7
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	asl a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdVolFade:
	mov a,#$e8
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	asl a
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdPan:
	mov a,#$db
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
	clrc
	adc a,#$0a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEE:
-	nop
	bra -

VcmdEchoOn:
	mov a,#$f4
	call RoutineWriteHex
	mov a,#$03
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEchoOff:
	mov a,#$f4
	call RoutineWriteHex
	mov a,#$03
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDetune:
	mov a,#$ee
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	bpl +
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
+	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdVibrato:
	mov a,#$de
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;delay
	setc
	sbc a,#$c0
	lsr a
	call RoutineWriteHex
	inc y
	inc y
	mov a,(ReadSeq)+y ;speed
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;value
	and a,#$7f
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdVibOff:
	mov a,#$df
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdTremolo:
	mov a,#$e5
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;delay
	setc
	sbc a,#$c0
	call RoutineWriteHex
	inc y
	inc y
	mov a,(ReadSeq)+y ;speed
	mov DPStack,a
	mov a,#$00
	setc
	sbc a,DPStack
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;value
	and a,#$7f
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdTremOff:
	mov a,#$fd
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdPortaSet:
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdPortaOn:
	mov a,#$26 ;& slider
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdPortaOff:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdQuant:
	mov a,#$71  ;q
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y ;quant 11-63 -> 01-53
	setc
	sbc a,#$10
	lsr a ;26
	lsr a ;13
	lsr a ;0a
	lsr a ;05
	inc a
	inc a
	inc a
	xcn a
	dec a
	call RoutineWriteItself
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdLegOn:
	mov a,#$f4
	call RoutineWriteHex
	mov a,#$01
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdLegOff:
	mov a,#$f4
	call RoutineWriteHex
	mov a,#$01
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdRoutine: ;subroutine
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	call RoutineUpdateWord
	mov y,#$00
	mov a,(ReadSeq)+y
	mov DPSubFlag,a
	movw ya,ReadSeq
	movw BackSeq,ya
	pop a
	mov y,a
	pop a
	addw ya,ReadSeq
	movw ReadSeq,ya
	mov a,#$5b ;start bracket
	call RoutineWriter
	jmp ReadSequence

VcmdLoopStart:
	inc y
	mov a,(ReadSeq)+y
	mov DPRepFlag,a ;store repeat calls for later
	mov a,#$20
	call RoutineWriter
	mov a,#$5b
	call RoutineWriter ;start double bracket
	mov a,#$5b
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdLoopEnd:
	mov a,#$20
	call RoutineWriter
	mov a,#$5d
	call RoutineWriter ;end double bracket
	mov a,#$5d
	call RoutineWriter
	mov a,DPRepFlag
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFF:
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

VCMDQuantifier:
	mov a,#$71 ;q
	call RoutineWriter
	mov a,(ReadSeq)+y
	setc
	sbc a,#$e6
	and a,#$0f
	clrc
	adc a,DPQuant ;inherit previous quantization
	call RoutineWriteItself
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDLoopStart:
	mov a,#$2f
	call RoutineWriter
;	jmp todo

VCMDLoopEnd:
	inc ReadTrackX
	cmp ReadTrackX,#$08
	bmi +
-	nop
	bra -
+	mov DPatPhrase,#$00
	mov DPNoteOctave,#$00
	mov DPNoteLength,#$00
	mov DPNoteKey,#$00
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	movw ya,ReadPat
	movw ReadSeq,ya 
+	jmp KonvertReadPattern

VCMDTranspose: ;fa 02
	mov a,#$02
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDADSR:
	inc y
	mov a,(ReadSeq)+y
	and a,#$7f ;fix ADSR
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDSubroutine:
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
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

-	nop
	bra -

VCMDSkip2:
	inc y
VCMDSkip1:
	inc y ;skip parameter 1 from $FA
;	jmp VoiceCommandParam


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
-	cmp a,#$0b
	bmi +
	inc DPSum1
	setc
	sbc a,#$0a
	bra -
+	mov DPStack,a
	mov a,DPSum1
	xcn a
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
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write tens (if given)
+	mov a,DPSum1
	and a,#$0f
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write ones (mandatory)
	ret