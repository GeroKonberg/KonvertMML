norom
arch spc700-raw
dpbase $0000
optimize dp always

;direct page

org $000000
incbin "input.spc":$000000..$010000 ;insert original SPC here
org $010000
incbin "input.spc":$010000..$010200 ;insert original SPC here


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
DPNotePan:
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
	;read 2 byte pattern pointer
	mov a,DPatPhrase
	asl a
	mov y,a
	mov a,DPatLength+y
	push y
	push a
	mov a,DPatLength+1+y
	mov y,a
	pop a
	movw DPatMirror,ya
	pop y
	inc y
	mov a,(ReadSeq)+y ;if high bit is 00, run a command instead
	bne +++
	dec y
	mov a,(ReadSeq)+y ;if zero, skip two further positions away
	bmi ++
	inc DPatPhrase
	inc DPatPhrase
	jmp KonvertReadPattern
++	inc ReadTrackX
	cmp ReadTrackX,#$08 ;do not read more than 8 channels
	bmi +
-	nop
	bra -
+	cmp DPSubFlag,#$00
	beq +
	call RoutineCloseLoop
+	mov DPatPhrase,#$00
	mov DPNoteOctave,#$00
	mov DPNoteLength,#$00
	mov DPNoteKey,#$00
	mov DPNoteTrans,#$00
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
;-	nop
;	bra -
-	jmp KonvertReadPattern


+++	dec y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	mov y,a
	pop a
	movw ReadSeq,ya

	;read 2x8 pattern index from channel 0-7
	mov a,ReadTrackX
	asl a
	mov y,a
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	bne +
	pop a
	inc DPatPhrase
	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern
+	mov y,a
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
	jmp ForceInterrupt
++	mov y,#$00
	mov a,(ReadSeq)+y
	bne +
	jmp VoiceInterrupt
+	bmi +
-	jmp VoiceNoteEvent
+	and a,#$7f
	cmp a,#$60
	bmi -
	or a,#$80
	jmp VoiceCommandRun



VoiceInterrupt: ;00
	cmp DPSubFlag,#$00 ;check for subroutines
	bne ++
ForceInterrupt:
	inc DPatPhrase
	mov DPatRuntime,#$00
	mov DPatRuntime+1,#$00
	cmp DPSubFlag,#$00
	beq +
	call RoutineCloseLoop
+	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern

++	call RoutineCloseLoop
	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence


VoiceNoteEvent: ;01-DF
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
	call RoutineWriteItself
	inc y
	mov a,(ReadSeq)+y
+++ cmp a,#$c8 ;compare for other types of notes
	bne +
	mov a,#$5e ;tie (^)
	call RoutineWriter
	bra ++
+	cmp a,#$c9
	bne +
	mov a,#$72 ;rest (r)
	call RoutineWriter
	bra ++
+	and a,#$7f
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
+	mov DPNoteOctave,#$01
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
	beq +
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
	
VoiceCommandRun: ;E0-FF
	mov DParamSize,#$00
	and a,#$1f
	mov x,a
	mov a,PresetVCMD+x
	beq +
	call RoutineWriteHex
+	mov a,x
	asl a
	mov x,a
	mov a,PresetVCMDIndex+1+x ;read command length/sub command
	and a,#$f0
	beq	++
	mov a,PresetVCMDIndex+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMDIndex+x
	push a
	ret
++ 	mov a,PresetVCMDIndex+1+x
	mov DParamSize,a
	;if left is zero, read the remainders (if any) as parameters directly
VoiceCommandParam:
-	cmp DParamSize,#$00
	beq ++
	dec DParamSize
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	bra -
++	inc y
	call RoutineUpdateWord
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

PresetVCMD: ;N-SPC to SMW VCMD conversion table [$E0-$FF]
			;if zero, the writer will skip it immediatly
	db $DA ;e0 instrument
	db $DB ;e1 pan
	db $DC ;e2 pan fade
	db $DE ;e3 vibrato on

	db $DF ;e4 vibrato off
	db $E0 ;e5 song volume
	db $E1 ;e6 song volume fade
	db $E2 ;e7 tempo

	db $E3 ;e8 tempo fade
	db $E4 ;e9 global transposition
	db $00 ;ea ($FA $02) channel transposition 
	db $E5 ;eb tremolo on

	db $DF ;ec tremolo off
	db $E7 ;ed volume
	db $E8 ;ee volume fade
	db $00 ;ef subroutine (handle externally)



	db $EA ;f0 vibrato fade
	db $EB ;f1 pitch env to
	db $EC ;f2 pitch env from
	db $DF ;f3 pitch enb disable

	db $EE ;f4 fine etune
	db $EF ;f5 echo p1
	db $F0 ;f6 echo off
	db $F1 ;f7 echo p2

	db $F2 ;f8 echo vol fade
	db $DD ;f9 pitch slide
	db $00 ;fa percussion base (skip)
	db $00 ;fb

	db $00 ;fc
	db $00 ;fd
	db $00 ;fe
	db $00 ;ff
	
PresetVCMDIndex:
	dw $0100 ;e0
	dw VCMDPan ;e1
	dw $0200 ;e2
	dw $0300 ;e3

	dw $0000 ;e4
	dw $0100 ;e5
	dw $0300 ;e6
	dw $0100 ;e7

	dw $0200 ;e8
	dw $0100 ;e9
	dw VCMDTranspose ;ea
	dw $0300 ;eb

	dw $0000 ;ec
	dw $0100 ;ed
	dw $0200 ;ee
	dw VCMDSubroutine ;ef

	dw $0100 ;f0
	dw $0300 ;f1
	dw $0300 ;f2
	dw $0000 ;f3

	dw $0100 ;f4
	dw $0300 ;f5
	dw $0000 ;f6
	dw $0300 ;f7

	dw $0300 ;f8
	dw VCMDBend ;f9
	dw VCMDSkip1 ;fa
	dw VoiceCommandParam ;fb

	dw VoiceCommandParam ;fc
	dw VoiceCommandParam ;fd
	dw VoiceCommandParam ;fe
	dw VCMDHectMeta ;ff

VCMDHectMeta:
	inc y
	mov a,(ReadSeq)+y
	cmp a,#$ff
	bne +
-	nop
	bra -
+	and a,#$0f
	asl a
	mov x,a
	mov a,PresetMetaIndex+1+x ;jump to meta command
	push a
	mov a,PresetMetaIndex+x
	push a
	ret
	
PresetMetaIndex:
	dw MetaNOP ;00
	dw MetaNOP ;01
	dw MetaNOP ;02
	dw MetaNOP ;03
	dw MetaNOP ;04
	dw MetaNOP ;05
	dw MetaNOP ;06
	dw MetaNOP ;07
	dw MetaNOP ;08
	dw MetaNOP ;09
	dw MetaNOP ;0A
	dw MetaNOP ;0B
	dw MetaNOP ;0C
	dw MetaNOP ;0D
	dw MetaNOP ;0E
	dw MetaNOP ;0F

MetaNOP:
-	nop
	bra -

MetaSkip3:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

MetaJump:
;	mov a,#$2f ;slash loop from here
;	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeq,ya
	pop a
	mov y,a
	pop a
	movw ReadSeq,ya ;read from subroutine
	jmp ReadSequence
	
MetaBreak:
;	cmp DPatFlag,#$00
;	beq +
;-	nop
;	bra -
+	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence


MetaEnd:
	inc ReadTrackX
	cmp ReadTrackX,#$08
	bmi +
-	nop
	bra -
+	mov DPatRuntime,#$00
	mov DPatRuntime+1,#$00
	mov DPatFlag,#$00
	cmp DPSubFlag,#$00
	beq +
	call RoutineCloseLoop
+	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	movw ya,ReadPat
	movw ReadSeq,ya
	jmp KonvertReadPattern

MetaLoopSet:
	mov a,#$5b ;open loop bracket
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	mov DPatFlag,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


MetaLoopEnd:
	mov a,#$5d ;end loop bracket
	call RoutineWriter
	mov a,DPatFlag
	call RoutineHexDecimal
	mov DPatFlag,#$00
	inc y ;skip word pointer
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

MetaSurround: ;panning with surround enabled
	and DPNotePan,#$3f
	inc y
	mov a,(ReadSeq)+y
	beq +
	eor DPNotePan,#$80
+	inc y
	mov a,(ReadSeq)+y
	beq +
	eor DPNotePan,#$40
+	mov a,#$db ;pan
	call RoutineWriteHex
	mov a,DPNotePan
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

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

VCMDPan:
	inc y
	mov a,(ReadSeq)+y
	mov DPNotePan,a
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDTranspose: ;fa 02 -> hx (V120)
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


VCMDSkip1:
	inc y ;skip parameter 1 from $FA
	jmp VoiceCommandParam


RoutineCloseLoop:
	mov a,#$5d ;close bracket
	call RoutineWriter
	mov a,DPSubFlag
	call RoutineHexDecimal
	mov DPSubFlag,#$00
	ret

RoutineMeasurePat:
	mov a,DPNoteLength
	clrc
	adc a,DPatRuntime
	bcc +
	inc DPatRuntime+1
+	mov DPatRuntime,a
	cmp ReadTrackX,#$00 ;measure initial pattern lengths on track 0 per phrase
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
	beq +
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write tens (if given)
+	mov a,DPSum1
	and a,#$0f
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter ;write ones (mandatory)
	ret