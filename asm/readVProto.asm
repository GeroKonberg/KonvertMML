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

ReadSeq: ;00-01
skip 2
BackSeq: ;02-03 backup for subroutine calls
skip 2
DPSubFlag: ;04
skip 1
ReadPat: ;05-06
skip 2
ReadTrackX: ;07
skip 1
WriteOut: ;08-09
skip 2
DParamSize: ;0A
skip 1
DPNoteLength: ;0B
skip 1
DPNoteOctave: ;0C
skip 1
DPOctLatest: ;0D
skip 1
DPNoteKey: ;0E
skip 1
DPNoteTens: ;0F
skip 1
DPNoteHund: ;10
skip 1
DPNoteTrans: ;11
skip 1
DPStack: ;12
skip 1
DPStack2: ;13
skip 1
DPatPhrase: ;14 which phrase to take place at currently
skip 1
DPatMirror: ;15-16
skip 2
DPatFlag: ;17 how many repeats are left, if specified
skip 1
DPSum1: ;18
skip 1
DPSum2: ;19
skip 1
DPQuant: ;1A
skip 1
DPBypass: ;1B
skip 1
DPatRuntime: ;1C-1D calculate pattern length on runtime for comparisons
skip 2
DPatSubtime: ;1E-1F calculate pattern length on subtime for comparisons
skip 2
DPatOuttime: ;20-21 measure lengths for splitting
skip 2
DPatOutpost: ;22-23 when to split output
skip 2
DPatLength: ;24-xx measure total pattern lengths for channel 0
skip 128


org !OutAddr+256
base !OutAddr
	db "#amk 4 #0"


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
	mov a,#$60
	mov y,#$00
	movw DPatOutpost,ya ;length of one bar (output)
	jmp KonvertReadPattern


KonvertSet:
	dw !ReadAddr
	db !ReadIndex
	dw !OutAddr+9


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
	beq ++
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
	jmp ForceInterrupt
++	mov y,#$00
	mov a,(ReadSeq)+y
	bne +
	jmp VoiceInterrupt
+	bmi +
-	jmp VoiceNoteEvent
+	and a,#$7f
	cmp a,#$5a
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
	mov DPatSubtime,#$00
	mov DPatSubtime+1,#$00
	mov DPatOuttime,#$00
	mov DPatOuttime+1,#$00
	cmp DPSubFlag,#$00
	beq +
	call RoutineCloseLoop
+	mov a,#$20
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	mov a,#$20
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
+++ cmp a,#$c6 ;compare for other types of notes
	bne +
	mov a,#$5e ;tie (^)
	call RoutineWriter
	bra ++
+	cmp a,#$c7
	bne +
	mov a,#$72 ;rest (r)
	call RoutineWriter
	bra ++
+	and a,#$7f
	cmp a,#$60 ;jump to voice command
	bmi +
	eor a,#$80
	jmp VoiceCommandRun
+	cmp a,#$50 ;drums (50-59)
	bmi +
	push a
	mov a,#$40 ;\@ setup drum kits
	call RoutineWriter
	mov DPStack2,#$32
	pop a
	and a,#$0f
	inc a
	cmp a,#$0a
	bmi +++
	inc DPStack2
	setc
	sbc a,#$0a
+++	mov x,a
	mov a,DPStack2
	call RoutineWriter
	mov a,PresetHex+x
	call RoutineWriter
	mov a,#$24
+	call RoutineGetNote 
++	mov a,#$3d ;=
	call RoutineWriter
	mov DPNoteTens,#$00
	mov DPNoteHund,#$00
	mov a,DPNoteLength ;convert hex to decimal length (up to =127 supported)
	call RoutineHexDecimal
	inc y
	call RoutineUpdateWord
	call RoutineMeasurePat
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence
-	nop
	bra -


VoiceCommandRun: ;DA-FF
	mov DParamSize,#$00
	setc
	sbc a,#$da
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
	db $DA ;da instrument
	db $00 ;db pan
	db $DC ;dc pan fade
	db $DD ;dd pitch slide
	db $DE ;de vibrato on
	db $DF ;df vibrato off
	db $E0 ;e0 song volume
	db $E1 ;e1 song volume fade
	db $00 ;e2 tempo
	db $E3 ;e3 tempo fade
	db $E4 ;e4 global transposition
	db $E5 ;e5 tremolo on
	db $FD ;e6 tremolo off
	db $00 ;e7 volume
	db $E8 ;e8 volume fade
	db $00 ;e9 subroutine
	db $EA ;ea vibrato fade
	db $EB ;eb pitch env to
	db $EC ;ec pitch env from
	db $FE ;ed pitch enb disable
	db $EE ;ee fine detune
	db $EF ;ef echo p1
	db $F0 ;f0 echo off
	db $F1 ;f1 echo p2
	db $F2 ;f2 echo vol fade


PresetVCMDIndex:
	dw $0100 ;da
	dw VCMDPan ;db
	dw $0200 ;dc
	dw VCMDBend ;dd
	dw $0300 ;de
	dw $0000 ;df
	dw $0100 ;e0
	dw $0200 ;e1
	dw VCMDTempo ;e2
	dw $0200 ;e3
	dw $0100 ;e4
	dw $0300 ;e5
	dw $0000 ;e6
	dw VCMDVolume ;e7
	dw $0200 ;e8
	dw VCMDSubroutine ;e9
	dw $0100 ;ea
	dw $0300 ;eb
	dw $0300 ;ec
	dw $0000 ;ed
	dw $0100 ;ee
	dw $0300 ;ef
	dw $0000 ;f0
	dw VCMDEchoSetup ;f1
	dw $0300 ;f2


FinishCom:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDVolume:
	mov a,#$76  ;v
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	call RoutineHexDecimal
	bra FinishCom


VCMDPan:
	mov a,#$79  ;y
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	and a,#$3f ;todo: account for surround flags
	call RoutineHexDecimal
	bra FinishCom


VCMDTempo:
	mov a,#$74 ;t
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
;	dec a ;adapt tempo for carry
	call RoutineHexDecimal
	bra FinishCom


VCMDEchoSetup:
	inc y
	mov a,(ReadSeq)+y ;delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;feedback
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;FIR filter
	inc a
	call RoutineWriteHex
	bra FinishCom

VCMDBend:
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	and a,#$7f
	eor a,#$80
	clrc
	adc a,DPNoteTrans ;adapt note for transposition
	call RoutineWriteHex
	jmp FinishCom


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
	jmp FinishCom


VCMDInst:
	mov a,#$40 ;at sign
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	and a,#$0f
	call RoutineHexDecimal
	jmp FinishCom


VCMDSubroutine:
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	beq +++	;force interrupt on non-standard zero calls
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
+++	jmp ForceInterrupt


VCMDSkip3:
	inc y
VCMDSkip2:
	inc y
VCMDSkip1:
	inc y
	jmp VoiceCommandParam


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
	movw ya,DPatOuttime
	addw ya,DPatSubtime
	movw DPatOuttime,ya
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
++	mov a,DPNoteLength ;measure length of output
	clrc
	adc a,DPatOuttime
	bcc +
	inc DPatOuttime+1
+	mov DPatOuttime,a
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
	mov DPNoteOctave,#$01
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
