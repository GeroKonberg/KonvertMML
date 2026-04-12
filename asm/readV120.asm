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
	mov DPatSubtime,#$00
	mov DPatSubtime+1,#$00
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
	cmp a,#$60 ;jump to voice command
	bmi +
	eor a,#$80
	jmp VoiceCommandRun
+	cmp a,#$4a ;drums (4A-5F)
	bmi +
	push a
	mov a,#$40 ;\@ setup drum kits
	call RoutineWriter
	mov DPStack2,#$32
	pop a
	setc
	sbc a,#$49
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
	db $DA ;instrument
	db $DB ;pan
	db $DC ;pan fade
	db $DE ;vibrato on

	db $DF ;vibrato off
	db $E0 ;song volume
	db $E1 ;song volume fade
	db $00 ;tempo (t)

	db $E3 ;tempo fade
	db $E4 ;global transposition
	db $00 ;channel transposition (h)
	db $E5 ;tremolo on

	db $FD ;tremolo off
	db $E7 ;volume
	db $E8 ;volume fade
	db $00 ;subroutine (handle externally)

	db $EA ;vibrato fade
	db $EB ;pitch env to
	db $EC ;pitch env from
	db $FE ;pitch enb disable

	db $EE ;fine detune
	db $EF ;echo p1
	db $F0 ;echo off
	db $F1 ;echo p2

	db $F2 ;echo vol fade
	db $DD ;pitch slide
	db $00 ;percussion base (skip)
	db $00 ;

	db $00 ;
	db $00 ;
	db $00 ;
	db $ED ;ADSR envelope


PresetVCMDIndex:
	dw $0100 ;e0
	dw $0100 ;e1
	dw $0200 ;e2
	dw $0300 ;e3

	dw $0000 ;e4
	dw $0100 ;e5
	dw $0200 ;e6
	dw VCMDTempo ;e7

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
	dw VCMDEchoSetup ;f7

	dw $0300 ;f8
	dw VCMDBend ;f9
	dw VCMDSkip1 ;fa
	dw VCMDSkip3 ;fb

	dw VCMDSkip1 ;fc
	dw VCMDSkip1 ;fd
	dw VCMDSkip1 ;fe
	dw VCMDEnvelope ;ff


FinishCom:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDTempo:
	mov a,#$74 ;t
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	dec a ;adapt tempo for carry
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
	bne +++
	inc a
--- call RoutineWriteHex
	bra FinishCom
+++	and a,#$03
	xcn a
	lsr a
	mov x,a
	mov a,#$01
	call RoutineWriteHex
	mov a,#$f5 ;setup FIR preset
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	call RoutineFIREntry
	bra ---


RoutineFIREntry:
	call RoutineWriteHex
	mov a,PresetFIRs+x
	inc x
	ret


VCMDEnvelope:
	inc y
	mov a,(ReadSeq)+y ;attack/decay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;release
	mov DPSum1,a
	inc y
	mov a,(ReadSeq)+y ;sustain level
	xcn a
	asl a
	clrc
	adc a,DPSum1
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


PresetFIRs:
	db $7f,$00,$00,$00,$00,$00,$00,$00
	db $58,$bf,$db,$f0,$fe,$07,$0c,$0c
	db $0c,$21,$2b,$2b,$13,$fe,$f3,$f9
	db $34,$33,$00,$d9,$e5,$01,$fc,$eb
	db $5f,$f3,$f4,$f5,$f6,$f6,$f8,$f9

