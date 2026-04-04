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
	pop a
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
	cmp a,#$55 ;80-D4 -> notes, D5-FF -> VCMDs
	bmi -
	or a,#$80
	jmp VoiceCommandRun



VoiceInterrupt: ;00, always return to a backup in third->second layer
	call RoutineCloseLoop
	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence


VoiceNoteEvent: ;01-DF
	mov DPNoteOctave,#$01
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
	mov a,#$5e ;tie (^)
	call RoutineWriter
	bra ++
+	cmp a,#$c9
	bne +
	mov a,#$72 ;rest (r)
	call RoutineWriter
	bra ++
+	and a,#$7f
	cmp a,#$4a ;drums (4A-54)
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
+
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
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence
-	nop
	bra -
	
VoiceCommandRun: ;D5-FF
	mov DParamSize,#$00
	setc
	sbc a,#$d5
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

PresetVCMD: ;N-SPC to SMW VCMD conversion table [$D5-$FF]
			;if zero, the writer will skip it immediatly
	db $DA ;D5 instrument
	db $00 ;D6 subroutine (handle externally)
	db $E7 ;D7 song volume

	db $ED ;D8 ADSR
	db $DB ;D9 pan
	db $DC ;DA pan fade
	db $DD ;DB global transposition
	db $FA ;DC ($FA $02) channel transposition 
	db $00 ;DD loop point, handle externally
	db $00 ;DE Terminate current track, increase ReadTrackX and continue up to 8
	db $E2 ;DF tempo

	db $DD ;E0 pitch slide
	db $DE ;E1 vibrato on
	db $DF ;E2 vibrato off
	db $00 ;E3 skip2
	db $00 ;E4 skip2
	db $00 ;E5 skip2

	db $00 ;E6 skip1
	db $00 ;E7 skip1
	db $00 ;E8 skip1
	db $00 ;E9 skip1

	db $00 ;EA skip1
	db $00 ;EB skip1
	db $00 ;EC skip1
	db $00 ;ED skip1

	db $00 ;EE skip1
	db $00 ;EF skip1
	db $00 ;F0 skip1
	db $00 ;F1 skip1

	db $00 ;F2 skip1
	db $00 ;F3 skip1
	db $00 ;F4 skip1
	db $00 ;F5 skip1

	db $EF ;F6 echo p1
	db $F0 ;F7 echo off
	db $F1 ;F8 echo p2

	db $00 ;F9 skip1
	db $00 ;FA skip1
	db $00 ;FB skip3
	db $00 ;FC skip2
	
PresetVCMDIndex:
	dw $0100 ;d5
	dw VCMDSubroutine ;d6
	dw $0100 ;d7

	dw VCMDADSR ;d8
	dw $0100 ;d9
	dw $0200 ;da
	dw $0100 ;db

	dw $0100 ;dc
	dw VCMDLoopStart ;dd
	dw VCMDLoopEnd ;de
	dw $0100 ;df

	dw $0300 ;e0
	dw $0300 ;e1
	dw $0100 ;e2
	dw VCMDSkip1 ;e3

	dw VCMDSkip1 ;e4
	dw VCMDSkip1 ;e5
	dw VCMDQuantifier ;e6 quiet
	dw VCMDQuantifier ;e7

	dw VCMDQuantifier ;e8
	dw VCMDQuantifier ;e9
	dw VCMDQuantifier ;ea
	dw VCMDQuantifier ;eb

	dw VCMDQuantifier ;ec
	dw VCMDQuantifier ;ed
	dw VCMDQuantifier ;ee
	dw VCMDQuantifier ;ef

	dw VCMDQuantifier ;f0
	dw VCMDQuantifier ;f1
	dw VCMDQuantifier ;f2
	dw VCMDQuantifier ;f3

	dw VCMDQuantifier ;f4
	dw VCMDQuantifier ;f5 loud
	dw $0300 ;f6
	dw $0000 ;f7

	dw $0300 ;f8
	dw VoiceCommandParam ;f9
	dw VCMDSkip1 ;fa
	dw VCMDSkip2 ;fb

	dw VCMDSkip1 ;fc

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
	jmp VoiceCommandParam

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
	jmp VoiceCommandParam


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