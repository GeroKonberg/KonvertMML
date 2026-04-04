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
DPBetopID:
skip 1
DPRepValA:
skip 1
DPRepValB:
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
	mov y,#$00
	mov a,(ReadSeq)+y
	mov DPBetopID,a
--	mov y,#$04
	mov a,(ReadSeq)+y
	cmp a,DPBetopID ;compare for the intended track
	beq ++
	mov a,ReadSeq
	clrc
	adc a,#$11
	bcc +
	inc ReadSeq+1
+	bra --
++	inc y
	mov a,y
	clrc
	adc a,ReadSeq
	bcc +
	inc ReadSeq+1
+	mov ReadSeq,a
	movw ya,ReadSeq
	movw ReadSeq,ya 
	movw ReadPat,ya ;write pattern location for above song
	mov a,KonvertSet+4
	mov y,a
	mov a,KonvertSet+3
	movw WriteOut,ya
	mov y,#$00
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	mov y,a
	pop a
	movw ReadOffset,ya
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
	cmp a,#$64
	bmi ++
	jmp VoiceBetopRun
++
-	jmp VoiceNoteEvent
+	and a,#$7f
	cmp a,#$60
	bmi -
	or a,#$80
	jmp VoiceCommandRun



VoiceBetopRun:
	and a,#$0f
	asl a
	mov x,a
	mov a,PresetBetopIndex+1+x ;jump to special Betop VCMD
	push a
	mov a,PresetBetopIndex+x
	push a
	ret

PresetBetopIndex:
	dw VoiceCommandParam ;60
	dw VoiceCommandParam ;61
	dw VoiceCommandParam ;62
	dw VoiceCommandParam ;63
	dw VCMDBetopJump ;64
	dw VCMDBetopCall ;65
	dw VCMDBetopReturn ;66
	dw VCMDRepStart ;67
	dw VCMDRepEnd ;68
	dw VoiceCommandParam ;69

VCMDBetopJump: ;64 mark end of track
	jmp ForceInterrupt

VCMDBetopCall: ;65
	inc y
	mov a,(ReadSeq)+y ;dir lsb
	push a
	inc y
	mov a,(ReadSeq)+y ;dir msb
	push a
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeq,ya ;store a backup for return
	pop a
	mov y,a
	pop a
	addw ya,ReadOffset
	movw ReadSeq,ya ;read from subroutine
	jmp ReadSequence
	
VCMDBetopReturn: ;66
	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence

VCMDRepStart: ;67, store value
	inc y
	mov a,(ReadSeq)+y
	cmp DPRepValA,#$00
	bne +
	mov DPRepValA,a ;value 1 (solo bracket)
	bra ++
+	mov DPRepValB,a ;value 2 (double bracket)
	mov a,#$20 ;start bracket
	call RoutineWriter
	mov a,#$5b ;start bracket
	call RoutineWriter
++	mov a,#$5b ;start bracket
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VCMDRepEnd:
	cmp DPRepValB,#$00
	bne ++
	mov a,#$5d ;end single bracket
	call RoutineWriter
	mov a,DPRepValA
	call RoutineHexDecimal
	mov DPRepValA,#$00
	bra +++
++	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,#$5d ;end double bracket
	call RoutineWriter
	mov a,DPRepValB
	call RoutineHexDecimal
	mov DPRepValB,#$00
+++	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VoiceInterrupt: ;00
	cmp DPSubFlag,#$00 ;check for subroutines
	bne ++
ForceInterrupt:
	inc ReadTrackX
	cmp ReadTrackX,#$08
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
	cmp a,#$64
	bmi +
	jmp VoiceBetopRun
+	clrc
	adc a,DPNoteLength
	mov DPNoteLength,a
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
	db $DA ;instrument
	db $DB ;pan
	db $DC ;pan fade
	db $DE ;vibrato on

	db $DF ;vibrato off
	db $E0 ;song volume
	db $E1 ;song volume fade
	db $E2 ;tempo

	db $E3 ;tempo fade
	db $E4 ;global transposition
	db $00 ;($FA $02) channel transposition 
	db $E5 ;tremolo on

	db $DF ;tremolo off
	db $E7 ;volume
	db $E8 ;volume fade
	db $00 ;subroutine (handle externally)



	db $EA ;vibrato fade
	db $EB ;pitch env to
	db $EC ;pitch env from
	db $FE ;pitch enb disable

	db $EE ;fine etune
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
	db $00 ;
	
PresetVCMDIndex:
	dw $0100 ;e0
	dw $0100 ;e1
	dw $0200 ;e2
	dw $0300 ;e3

	dw $0000 ;e4
	dw $0100 ;e5
	dw $0200 ;e6
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
	dw VCMDSkip1 ;fa percussion base (skip)
	dw VCMDSkip1 ;fb

	dw VoiceCommandParam ;fc
	dw VCMDSkip1 ;fd
	dw VoiceCommandParam ;fe
	dw VoiceCommandParam ;ff

VCMDPorta:
	mov a,#$26 ;and sign
	call RoutineWriter
	mov DPNoteOctave,#$01
	inc y
	mov a,(ReadSeq)+y
	and a,#$7f
	call RoutineGetNote
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