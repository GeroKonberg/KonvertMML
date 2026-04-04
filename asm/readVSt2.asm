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
BackSeqA: ;backup for subroutine calls
skip 2
BackSeqB:
skip 2
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
DPEchoDelay:
skip 1
DPEchoFeed:
skip 1
DPADSR:
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
	mov y,#$02 ;skip echo FIR table pointer and set real song pointer
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
+	mov a,ReadTrackX
	asl a
	asl a
	mov y,a
	inc y ;skip status
	inc y ;skip status
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	bne +
	pop a
-	nop
	bra -
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
;	jmp ForceInterrupt
++	mov y,#$00
	mov a,(ReadSeq)+y
	bne +
	jmp VoiceInterrupt
+	bmi +
-	jmp VoiceNoteEvent
+	and a,#$7f
	cmp a,#$50
	bmi -
	or a,#$80
	jmp VoiceCommandRun



VoiceInterrupt: ;00
ForceInterrupt:
	inc ReadTrackX
	cmp ReadTrackX,#$08
	bmi +
-	nop
	bra -
+	mov DPatRuntime,#$00
	mov DPatRuntime+1,#$00
	mov DPSubFlag,#$00
	mov DPRepFlag,#$00
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
	jmp KonvertReadPattern



VoiceNoteEvent: ;01-CF
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
+++ cmp a,#$c8 ;set duration
	bne +
	inc y
	mov a,(ReadSeq)+y
	mov DPNoteLength,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence
+	cmp a,#$c9 ;compare for other types of notes
	bne +
	mov a,#$5e ;tie (^)
	call RoutineWriter
	mov a,#$3d ;=
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	bra +++ ;use a custom length specific to tied notes
+	cmp a,#$ca
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
	
VoiceCommandRun: ;D0-FF
	mov DParamSize,#$00
	setc
	sbc a,#$d0
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
	db $DA ;d0 program change
	db $E0 ;d1 global volume
	db $00 ;d2 ADSR1
	db $00 ;d3 ADSR2
	db $00 ;d4 GAIN(Release)
	db $f4 ;d5 restore ADSR
	db $00 ;d6 set quantization
	db $DB ;d7 pan
	db $DC ;d8 pan fade
	db $E2 ;d9 tempo
	db $E3 ;da tempo fade
	db $E7 ;db volume
	db $E8 ;dc volume fade
	db $E5 ;dd tremolo
	db $00 ;de panbrello
	db $00 ;df panbrello off
	db $FD ;e0 tremolo off
	db $E4 ;e1 global transpose
	db $00 ;e2 (h) channel transpose
	db $EE ;e3 finetune
	db $DE ;e4 vibrato on
	db $DF ;e5 vibrato off
	db $00 ;e6 pitch base
	db $DD ;e7 pitch bend
	db $F4 ;e8 legato on
	db $F4 ;e9 legato off
	db $00 ;ea echo delay
	db $00 ;eb echo feedback
	db $00 ;ec echo FIR (01)
	db $00 ;ed echo vol
	db $F4 ;ee echo on
	db $F4 ;ef echo off
	db $00 ;f0 noise note
	db $00 ;f1 noise fade
	db $00 ;f2 noise off
	db $00 ;f3 pmod on
	db $00 ;f4 pmod off
	db $00 ;f5 loop
	db $00 ;f6 call macro
	db $00 ;f7 end macro
	db $00 ;f8 loop start
	db $00 ;f9 loop end
	
	
PresetVCMDIndex:
	dw $0100 ;d0 program change
	dw $0100 ;d1 global volume
	dw SetADSR1 ;d2 ADSR1
	dw SetADSR2 ;d3 ADSR2
	dw SetGAIN ;d4 GAIN(Release)
	dw SetRestore ;d5 restore ADSR
	dw SetQuant ;d6 set quantization
	dw $0100 ;d7 pan
	dw $0200 ;d8 pan fade
	dw $0100 ;d9 tempo
	dw $0200 ;da tempo fade
	dw $0100 ;db volume
	dw $0200 ;dc volume fade
	dw $0300 ;dd tremolo
	dw VCMDSkip2 ;de panbrello
	dw VCMDSkip0 ;df panbrello off
	dw $0000 ;e0 tremolo off
	dw $0100 ;e1 global transpose
	dw VCMDTranspose ;e2 (h) channel transpose
	dw $0100 ;e3 finetune
	dw $0300 ;e4 vibrato on
	dw $0000 ;e5 vibrato off
	dw VCMDSkip1 ;e6 pitch base
	dw $0300 ;e7 pitch bend
	dw SetLegato ;e8 legato on
	dw SetLegato ;e9 legato off
	dw SetEchoDelay ;ea echo delay
	dw SetEchoFeed ;eb echo feedback
	dw SetEchoFIR ;ec echo FIR (01)
	dw SetEchoVolume ;ed echo vol
	dw SetEchoToggle ;ee echo on
	dw SetEchoToggle ;ef echo off
	dw VCMDSkip1 ;f0 noise note
	dw VCMDSkip2 ;f1 noise fade
	dw VCMDSkip0 ;f2 noise off
	dw VCMDSkip0 ;f3 pmod on
	dw VCMDSkip0 ;f4 pmod off
	dw VoiceInterrupt ;f5 terminate
	dw VCMDMacroCall ;f6 call macro
	dw VCMDMacroEnd ;f7 end macro
	dw VCMDLoopStart ;f8 loop start
	dw VCMDLoopEnd ;f9 loop end


SetADSR1: ;store
	inc y
	mov a,(ReadSeq)+y
	mov DPADSR,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetADSR2: ;write
	mov a,#$ed
	call RoutineWriteHex
	mov a,DPADSR
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetGAIN:
;	mov a,#$ed
;	call RoutineWriteHex
;	mov a,#$80
;	call RoutineWriteHex
	inc y
;	mov a,(ReadSeq)+y
;	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetRestore:
	mov a,#$09 ;f4 09
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetQuant:
	mov a,#$71 ;q, write 00-7F param 2 as quantization
	call RoutineWriter
	inc y
	mov a,(ReadSeq)+y
	call RoutineWriteItself
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetLegato:
	mov a,#$01 ;f4 01
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetEchoDelay:
	inc y
	mov a,(ReadSeq)+y
	mov DPEchoDelay,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetEchoFeed:
	inc y
	mov a,(ReadSeq)+y
	mov DPEchoFeed,a
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetEchoFIR:
	mov a,#$f1
	call RoutineWriteHex
	mov a,DPEchoDelay
	call RoutineWriteHex
	mov a,DPEchoFeed
	call RoutineWriteHex
	mov a,#$01
	call RoutineWriteHex
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetEchoVolume:
	mov a,#$f2
	call RoutineWriteHex
	inc y
	mov a,(ReadSeq)+y
	inc a
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	mov a,(ReadSeq)+y
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

SetEchoToggle:
	mov a,#$03
	call RoutineWriteHex
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDMacroCall:
	inc y
	mov a,(ReadSeq)+y
	push a
	inc y
	mov a,(ReadSeq)+y
	push a

;	mov a,#$5b ;start bracket
;	call RoutineWriter
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	cmp DPSubFlag,#$00
	beq ++
	movw BackSeqB,ya
	mov a,#$5b ;start double bracket
	call RoutineWriter
	bra +
++	movw BackSeqA,ya ;store a backup for return
+	inc DPSubFlag ;store repeat calls for later
	pop a
	mov y,a
	pop a
	movw ReadSeq,ya ;read from subroutine
	jmp ReadSequence

VCMDMacroEnd:
;	mov a,#$5d ;end bracket
;	call RoutineWriter
	dec DPSubFlag
	cmp DPSubFlag,#$00
	beq ++
	mov a,#$5d ;end double bracket
	call RoutineWriter
	movw ya,BackSeqB
	bra +
++	movw ya,BackSeqA
+	movw ReadSeq,ya
	jmp ReadSequence

VCMDLoopStart:
	inc y
	mov a,(ReadSeq)+y
	cmp DPRepFlag,#$00
	beq ++
	mov DPRepValB,a
;	mov a,#$5b
;	call RoutineWriter ;start double bracket
	bra +
++	mov DPRepValA,a ;store repeat calls for later
+	mov a,#$20
	call RoutineWriter
	mov a,#$5b
	call RoutineWriter ;start double bracket
	mov a,#$5b
	call RoutineWriter
	mov a,#$20
	call RoutineWriter
	inc DPRepFlag
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VCMDLoopEnd:
	mov a,#$20
	call RoutineWriter
	mov a,#$5d
	call RoutineWriter ;end double bracket
	mov a,#$5d
	call RoutineWriter
	dec DPRepFlag
	cmp DPRepFlag,#$00
	beq ++
;	mov a,#$5d ;end double bracket
;	call RoutineWriter
	mov a,DPRepValB
	bra +
++	mov a,DPRepValA
+	call RoutineHexDecimal
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




VCMDSkip3:
	inc y
VCMDSkip2:
	inc y
VCMDSkip1:
	inc y ;skip parameter 1 from $FA, etc.
VCMDSkip0:
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
	mov a,ReadTrackX
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