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
DPatOuttime: ;measure lengths for splitting
skip 2
DPatOutpost: ;when to split output
skip 2

org !OutAddr+256
base !OutAddr
	db "#amk 4  #0  "

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
	dw !OutAddr+12

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
	mov DPatOuttime,#$00
	mov DPatOuttime+1,#$00
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
	mov a,#$da ;\@ setup drum kits
	call RoutineWriteHex
	pop a
	setc
	sbc a,#$4a
	call RoutineWriteHex
	mov a,#$24
+	call RoutineGetNote 
++	mov a,#$3d ;=
	call RoutineWriter
	mov a,DPNoteLength ;convert hex to decimal length (up to =127 supported)
-	call RoutineHexDecimal 
	inc y
	call RoutineUpdateWord
	call RoutineMeasurePat
	mov DPOctLatest,DPNoteOctave
	jmp ReadSequence
	
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
	db $00 ;D7 volume

	db $ED ;D8 ADSR
	db $00 ;D9 pan
	db $DC ;DA pan fade
	db $DD ;DB global transposition
	db $00 ;DC (h) channel transposition 
	db $00 ;DD loop point, handle externally
	db $00 ;DE Terminate current track, increase ReadTrackX and continue up to 8
	db $00 ;DF tempo

	db $DD ;E0 pitch slide
	db $DE ;E1 vibrato on
	db $DF ;E2 vibrato off
	db $00 ;E3 skip2
	db $00 ;E4 skip2
	db $00 ;E5 skip2

	db $00 ;E6 quant 0
	db $00 ;E7 quant 1
	db $00 ;E8 quant 2
	db $00 ;E9 quant 3

	db $00 ;EA quant 4
	db $00 ;EB quant 5
	db $00 ;EC quant 6
	db $00 ;ED quant 7

	db $00 ;EE quant 8
	db $00 ;EF quant 9
	db $00 ;F0 quant A
	db $00 ;F1 quant B

	db $00 ;F2 quant C
	db $00 ;F3 quant D
	db $00 ;F4 quant E
	db $00 ;F5 quant F

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
	dw VCMDVolume ;d7

	dw VCMDADSR ;d8
	dw VCMDPan ;d9
	dw $0200 ;da
	dw $0100 ;db

	dw VCMDTranspose ;dc
	dw VCMDLoopStart ;dd
	dw VCMDLoopEnd ;de
	dw VCMDTempo ;df

	dw $0300 ;e0
	dw $0300 ;e1
	dw $0000 ;e2
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

	dw VCMDEchoSetup ;f8
	dw VoiceCommandParam ;f9
	dw VCMDSkip1 ;fa
	dw VCMDSkip2 ;fb

	dw VCMDSkip1 ;fc


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
	jmp FinishCom

VCMDSongVol:
	mov a,#$77  ;w
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	call RoutineHexDecimal
	jmp FinishCom

VCMDPan:
	mov a,#$79  ;y
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	and a,#$3f ;todo: account for surround flags
	call RoutineHexDecimal
	jmp FinishCom

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
	jmp FinishCom

VCMDTempo:
	mov a,#$74 ;t
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	dec a ;adapt tempo for carry
	call RoutineHexDecimal
	jmp FinishCom

VCMDEchoSetup:
	inc y
	mov a,(ReadSeq)+y ;delay
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y ;feedback
	call RoutineWriteHex
	inc y
	mov a,#$01 ;FIR filter
	call RoutineWriteHex
	jmp FinishCom

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
	call RoutineLineBreak
	call RoutineLineBreak
	mov a,#$23 ;# start a new channel
	call RoutineWriter
	mov a,ReadTrackX
	mov x,a
	mov a,PresetHex+x
	call RoutineWriter
	call RoutineLineBreak
	movw ya,ReadPat
	movw ReadSeq,ya 
+	jmp KonvertReadPattern

VCMDTranspose: ;fa 02 -> h
	mov a,#$68 ;h
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	bpl +
	mov DPStack,a
	mov a,#$2d  ;if negative, add a subtraction sign
	call RoutineWriter
	mov a,#$00
	setc
	sbc a,DPStack
+	call RoutineHexDecimal
	jmp FinishCom

VCMDADSR:
	inc y
	mov a,(ReadSeq)+y
	and a,#$7f ;fix ADSR
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
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
	call RoutineLineBreak
	ret

RoutineMeasurePat:
	mov a,DPNoteLength ;measure length of output
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
	call RoutineLineBreak
	bra --
++	ret

RoutineLineBreak:
	mov DPNoteOctave,#$7f
	mov a,#$20
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
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