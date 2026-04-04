norom
arch 65816
dpbase $0000
optimize dp always


org $000000
base $008000 ;SFC_MAIN

KonsoleInit:
	clc
	xce
	sei
	rep #$39
	ldx #$1fff
	txs
	lda #$4200
	tcd
	sep #$20
	pha
	plb
	lda #$01
	sta $4200
	sta $00
	lda #$8f
	sta $2100
	stz $00
	stz $0c
	stz $0b
	stz $0d
	stz $07
	stz $08
	stz $09
	stz $0a
	stz $02
	stz $03
	stz $04
	stz $05
	stz $06
	lda #$21
	xba
	lda #$00
	tcd
	stz $01
	stz $05
	stz $06
	lda #$10
	sta $07
	stz $08
	stz $09
	stz $0a
	lda #$02
	sta $0b
	stz $0c
	stz $0d
	stz $0d
	stz $0e
	stz $0e
	stz $0f
	stz $0f
	stz $10
	stz $10
	stz $11
	stz $11
	stz $12
	stz $12
	stz $13
	stz $13
	stz $14
	stz $14
	lda #$80
	sta $15
	stz $1a
	lda #$01
	stz $1b
	sta $1b
	stz $1c
	stz $1c
	stz $1d
	stz $1d
	stz $1e
	sta $1e
	stz $1f
	stz $1f
	stz $20
	stz $20
	stz $21
	stz $22
	stz $22
	lda #$ff
	sta $22
	sta $22
	stz $23
	stz $24
	stz $25
	stz $26
	stz $27
	stz $28
	stz $29
	stz $2a
	stz $2b
	lda #$01
	sta $2c
	stz $2d
	stz $2e
	stz $2f
	lda #$30
	sta $30
	stz $31
	lda #$e0
	sta $32
	stz $33
	ldx #$2000
	stx $16
	ldx #$0000
-	lda $a000,x
	sta $18
	stz $19
	inx
	cpx #$0400
	bne -
	ldx #$1000
	stx $16
	ldx #$0000
-	lda $9000,x ;upload tiles to screen
	sta $18
	stz $19
	sta $1000,x
	inx
	cpx #$0380
	bne -
	lda #$0f
	sta $00
	rep #$20
	lda #$bbaa
-	cmp $40		;apuIO0
	bne -
	lda #$0002
	sta $42
	lda #$01cc
	sta $40		;apuIO0
	sep #$20
-	cmp $40
	bne -
	rep #$20
	ldx #$003c
	ldy #$0000
	sep #$20
-	lda $8800,y
	sta $41		;apuIO1
	tya
	sta $40		;apuIO0
--	cmp $40		;apuIO0
	bne --
	iny
	dex
	bne -
	
	rep #$20
	lda #$0002
	sta $42		;apuIO2
	sep #$20
	stz $41		;apuIO1
	lda $40		;apuIO0
	adc #$02
	sta $40		;apuIO0
	ldx #$0100
-	dex
	bne -
	lda #$ff
	sta $43		;apuIO3
-	cmp $43		;apuIO3
	bne -
-	inc
--	cmp $43		;apuIO3
	bne --
	ldy $8c00,x
	sty $40		;apuIO0
	sta $43		;apuIO3
	inx
	inx
	cpy #$ffff
	bne - ;8151
	lda #$01
	pha
	plb
	lda #$ff
	sta $43		;apuIO3
	ldx #$0100
-	inc
--	cmp $43		;apuIO3
	bne --
	ldy $8000,x
	sty $40		;apuIO0
	sta $43		;apuIO3
	inx
	bpl -
	pha
	lda #$02
	pha
	plb
	pla
	ldx #$0000
-	inc
--	cmp $43		;apuIO3
	bne --
	ldy $8000,x
	sty $40		;apuIO0
	sta $43		;apuIO3
	inx
	bpl -
	lda #$01
	pha
	plb
	lda #$ff
	sta $43		;apuIO3
	ldx #$0000
	sep #$10
-
--	cpx $43		;apuIO3
;	bne --
	lda $8000,x
	sta $40		;apuIO0
	stx $43		;apuIO3
	inx
	cpx #$f0
	bne -
	lda #$10
-	dec
	bne -
	lda #$00
	pha
	plb
	lda $8d00
	sta $40
	lda $8d01
	sta $41
	lda $8d02
	sta $42
	lda $8d03
	sta $43
KonsoleLoop:
; ensure auto-read has finished

-	nop
	lda #$01
	sta $42
	bra -




org $000800
base $008800 ;SFC_IPL1
	db $cd,$ff,$d8,$f7,$3e,$f7,$d0,$fc,$3d,$d8,$f7,$3e,$f7,$d0,$fc,$ba
	db $f4,$68,$ff,$f0,$06,$c4,$f2,$cb,$f3,$2f,$ed,$8f,$00,$00,$8f,$01
	db $01,$8d,$ff,$7e,$f7,$d0,$fc,$fc,$cb,$f7,$7e,$f7,$d0,$fc,$e4,$f4
	db $d7,$00,$fc,$d0,$f3,$ab,$01,$d0,$ef,$5f,$00,$90


org $000C00
base $008C00 ;SFC_DS
	db $00,$00,$01,$00,$02,$00,$03,$00,$04,$00,$05,$00,$06,$00,$07,$00
	db $10,$43,$11,$63,$12,$69,$13,$31,$14,$00,$15,$00,$16,$00,$17,$00
	db $20,$00,$21,$00,$22,$00,$23,$00,$24,$00,$25,$00,$26,$00,$27,$00
	db $30,$00,$31,$00,$32,$00,$33,$00,$34,$00,$35,$00,$36,$00,$37,$00
	db $40,$00,$41,$00,$42,$00,$43,$00,$44,$00,$45,$00,$46,$00,$47,$00
	db $50,$00,$51,$00,$52,$00,$53,$00,$54,$00,$55,$00,$56,$00,$57,$00
	db $60,$00,$61,$8f,$62,$f2,$63,$03,$64,$6b,$65,$43,$66,$0d,$67,$dd
	db $70,$60,$71,$a0,$72,$8d,$73,$5d,$74,$5f,$75,$90,$76,$23,$77,$b0
	db $0f,$00,$1f,$00,$2f,$00,$3f,$00,$4f,$00,$5f,$00,$6f,$00,$7f,$00
	db $0c,$00,$1c,$00,$2c,$00,$3c,$00,$5c,$00,$7c,$00,$0d,$00,$2d,$00
	db $3d,$00,$4d,$00,$5d,$00,$6d,$00,$7d,$00,$ff,$ff


org $000D00
base $008D00 ;SFC_CPUIO
	db $00,$00,$01,$00


org $001000
base $009000 ;SFC_INIT_TEXT

KonsoleScreen:
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20
	db $20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20,$20


org $002000
base $00A000 ;SFC_TILES

	db $3c,$66,$6e,$7e,$76,$66,$3c,$00,$18,$38,$18,$18,$18,$18,$3c,$00
	db $7c,$06,$06,$3c,$60,$60,$7e,$00,$7c,$06,$06,$1c,$06,$06,$7c,$00
	db $66,$66,$66,$3e,$06,$06,$06,$00,$7e,$60,$60,$7c,$06,$06,$7c,$00
	db $3e,$60,$60,$7c,$66,$66,$3c,$00,$7e,$06,$06,$0c,$18,$18,$18,$00
	db $3c,$66,$66,$3c,$66,$66,$3c,$00,$3c,$66,$66,$3e,$06,$06,$7c,$00
	db $18,$3c,$66,$66,$7e,$66,$66,$00,$7c,$66,$66,$7c,$66,$66,$7c,$00
	db $3e,$60,$60,$60,$60,$60,$3e,$00,$7c,$66,$66,$66,$66,$66,$7c,$00
	db $7e,$60,$60,$7c,$60,$60,$7e,$00,$7e,$60,$60,$78,$60,$60,$60,$00

	db $c0,$f0,$fc,$ff,$fc,$f0,$c0,$00,$03,$0f,$3f,$ff,$3f,$0f,$03,$00
	db $18,$3c,$7e,$18,$18,$7e,$3c,$18,$e7,$e7,$e7,$e7,$e7,$e7,$e7,$00
	db $7f,$db,$db,$7b,$1b,$1b,$1b,$00,$3e,$63,$38,$6c,$6c,$38,$cc,$78
	db $00,$00,$00,$00,$7e,$7e,$7e,$00,$18,$3c,$7e,$18,$7e,$3c,$18,$ff
	db $00,$18,$3c,$7e,$18,$18,$18,$18,$18,$18,$18,$18,$7e,$3c,$18,$00
	db $00,$08,$0c,$fe,$0c,$08,$00,$00,$00,$10,$30,$7f,$30,$10,$00,$00
	db $00,$00,$c0,$c0,$c0,$fe,$00,$00,$00,$24,$66,$ff,$66,$24,$00,$00
	db $00,$18,$3c,$7e,$ff,$00,$ff,$00,$7c,$82,$ba,$a2,$ba,$82,$7c,$00



	db $00,$00,$00,$00,$00,$00,$00,$00,$18,$18,$18,$18,$18,$00,$18,$00
	db $6c,$6c,$6c,$00,$00,$00,$00,$00,$6c,$6c,$fe,$6c,$fe,$6c,$6c,$00
	db $18,$3e,$60,$3c,$06,$7c,$18,$00,$00,$63,$66,$0c,$18,$33,$63,$00
	db $1c,$36,$1c,$3b,$6e,$66,$3b,$00,$0c,$18,$30,$00,$00,$00,$00,$00
	db $0c,$18,$30,$30,$30,$18,$0c,$00,$30,$18,$0c,$0c,$0c,$18,$30,$00
	db $00,$66,$3c,$ff,$3c,$66,$00,$00,$00,$30,$30,$fc,$30,$30,$00,$00
	db $00,$00,$00,$00,$00,$18,$18,$30,$00,$00,$00,$7e,$00,$00,$00,$00
	db $00,$00,$00,$00,$00,$18,$18,$00,$02,$06,$0c,$18,$30,$60,$40,$00
	
	db $3c,$66,$6e,$7e,$76,$66,$3c,$00,$18,$38,$18,$18,$18,$18,$3c,$00
	db $7c,$06,$06,$3c,$60,$60,$7e,$00,$7c,$06,$06,$1c,$06,$06,$7c,$00
	db $66,$66,$66,$3e,$06,$06,$06,$00,$7e,$60,$60,$7c,$06,$06,$7c,$00
	db $3e,$60,$60,$7c,$66,$66,$3c,$00,$7e,$06,$06,$0c,$18,$18,$18,$00
	db $3c,$66,$66,$3c,$66,$66,$3c,$00,$3c,$66,$66,$3e,$06,$06,$7c,$00
	db $00,$18,$18,$00,$00,$18,$18,$00,$00,$18,$18,$00,$00,$18,$18,$30
	db $0c,$18,$30,$60,$30,$18,$0c,$00,$00,$00,$7e,$00,$00,$7e,$00,$00
	db $30,$18,$0c,$06,$0c,$18,$30,$00,$3c,$66,$06,$0c,$18,$00,$18,$00



	db $3e,$63,$6f,$69,$6f,$60,$3e,$00,$18,$3c,$66,$66,$7e,$66,$66,$00
	db $7c,$66,$66,$7c,$66,$66,$7c,$00,$3e,$60,$60,$60,$60,$60,$3e,$00
	db $7c,$66,$66,$66,$66,$66,$7c,$00,$7e,$60,$60,$7c,$60,$60,$7e,$00
	db $7e,$60,$60,$78,$60,$60,$60,$00,$3e,$60,$60,$6e,$66,$66,$3e,$00
	db $66,$66,$66,$7e,$66,$66,$66,$00,$3c,$18,$18,$18,$18,$18,$3c,$00
	db $06,$06,$06,$06,$66,$66,$3c,$00,$66,$66,$6c,$78,$6c,$66,$66,$00
	db $60,$60,$60,$60,$60,$60,$7e,$00,$63,$77,$7f,$7f,$6b,$63,$63,$00
	db $66,$66,$76,$7e,$6e,$66,$66,$00,$3c,$66,$66,$66,$66,$66,$3c,$00

	db $7c,$66,$66,$7c,$60,$60,$60,$00,$3c,$66,$66,$66,$66,$6e,$3c,$06
	db $7c,$66,$66,$7c,$6c,$66,$66,$00,$3c,$66,$60,$3c,$06,$66,$3c,$00
	db $7e,$18,$18,$18,$18,$18,$18,$00,$66,$66,$66,$66,$66,$66,$3c,$00
	db $66,$66,$66,$66,$66,$3c,$18,$00,$63,$63,$63,$6b,$7f,$77,$63,$00
	db $63,$63,$36,$1c,$1c,$36,$63,$00,$66,$66,$66,$3c,$18,$18,$18,$00
	db $7e,$06,$0c,$18,$30,$60,$7e,$00,$3c,$30,$30,$30,$30,$30,$3c,$00
	db $40,$60,$30,$18,$0c,$06,$02,$00,$3c,$0c,$0c,$0c,$0c,$0c,$3c,$00
	db $08,$1c,$36,$63,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$00,$ff



	db $30,$18,$0c,$00,$00,$00,$00,$00,$00,$00,$3e,$66,$66,$66,$3e,$00
	db $60,$60,$7c,$66,$66,$66,$7c,$00,$00,$00,$3e,$60,$60,$60,$3e,$00
	db $06,$06,$3e,$66,$66,$66,$3e,$00,$00,$00,$3c,$66,$7e,$60,$3e,$00
	db $1c,$36,$30,$78,$30,$30,$30,$00,$00,$00,$3e,$66,$66,$3e,$06,$7c
	db $60,$60,$7c,$66,$66,$66,$66,$00,$18,$00,$18,$18,$18,$18,$18,$00
	db $06,$00,$06,$06,$06,$66,$66,$3c,$60,$60,$66,$6c,$78,$6c,$66,$00
	db $18,$18,$18,$18,$18,$18,$18,$00,$00,$00,$66,$7f,$7f,$6b,$63,$00
	db $00,$00,$7c,$66,$66,$66,$66,$00,$00,$00,$3c,$66,$66,$66,$3c,$00

	db $00,$00,$7c,$66,$66,$7c,$60,$60,$00,$00,$3e,$66,$66,$3e,$06,$06
	db $00,$00,$6c,$76,$60,$60,$60,$00,$00,$00,$3e,$60,$3c,$06,$7c,$00
	db $18,$18,$7e,$18,$18,$18,$18,$00,$00,$00,$66,$66,$66,$66,$3e,$00
	db $00,$00,$66,$66,$66,$3c,$18,$00,$00,$00,$63,$6b,$7f,$7f,$36,$00
	db $00,$00,$63,$36,$1c,$36,$63,$00,$00,$00,$66,$66,$66,$3e,$06,$7c
	db $00,$00,$7e,$0c,$18,$30,$7e,$00,$0e,$18,$18,$70,$18,$18,$0e,$00
	db $0c,$0c,$0c,$00,$0c,$0c,$0c,$00,$70,$18,$18,$0e,$18,$18,$70,$00
	db $3b,$6e,$00,$00,$00,$00,$00,$00,$00,$08,$1c,$36,$63,$7f,$00,$00


org $002000
base $00A000 ;SFC_



org $007FC0
base $00FFC0
	db "SPC PLAYER"

org $007FD5
base $00FFD5 ;SFC_ROMMETA
	db $00,$01,$08,$00, $01,$01,$00,$00, $00,$FF,$FF
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00
	db $00,$00,$00,$00, $00,$00,$00,$00, $00,$00,$00,$00, $00,$80,$00,$00

org $017F84
base $027F84 ;SFC_IPL2
	db $cd,$ff,$3e,$f7,$d0,$fc,$3d,$d8,$f7,$3e,$f7,$d0
	db $fc,$e4,$f4,$c6,$c8,$ef,$d0,$f2,$8f,$6c,$f2,$8f,$00,$f3,$8f,$4c
	db $f2,$8f,$00,$f3,$8f,$00,$fc,$8f,$00,$fb,$8f,$00,$fa,$8f,$00,$f2
	db $8f,$00,$f1,$cd,$f3,$bd,$e8,$00,$8d,$00,$cd,$04,$8e,$5f,$00,$90
	

org $008000
base $000000

	incbin "driver.spc":$0100..$8100

org $010000
base $008000
	incbin "driver.spc":$8100..$10100

org $00DA54
	incbin "input.spc":$002B54..$004FFF ;insert addmusic SPC here

arch spc700-raw
dpbase $0000
optimize dp always

org $0080d6
base $0000d6 ;zero page

ReadSeq:
skip 2
BackSeq: ;backup for subroutine calls
skip 2
CopySeq:
skip 2
DPSubFlag:
skip 1
ReadPat:
skip 2
ReadTrackX: ;0-7,1-8
skip 1
WriteOut:
skip 2
PadOut:
skip 2
SubPos:
skip 2


org $011000
base $009000 ;drive page

KonvertInit:
	mov DPSubFlag,#$00
	mov ReadTrackX,#$00
	mov y,#$c0
	mov a,#$30
	movw WriteOut,ya

	mov y,#$c0
	mov a,#$10
	movw PadOut,ya

	mov y,#$5a
	mov a,#$54
	movw ReadPat,ya

	mov y,#$00
	mov a,(ReadPat)+y
	push a
	inc y
	mov a,(ReadPat)+y
	clrc
	adc a,#$30
	mov y,a
	pop a
	movw ReadPat,ya

KonvertReadPattern: ;8x2-byte word pattern
	cmp ReadTrackX,#$08
	bmi +
--	mov a,#$00
	mov x,a
	mov y,a
	jmp $0500
+	mov a,ReadTrackX
	asl a
	mov y,a
	inc y
	mov a,(ReadPat)+y
	bne +
	jmp ForceInterrupt
+	dec y
	mov a,WriteOut
	mov (PadOut)+y,a
	mov a,(ReadPat)+y
	push a
	inc y
	mov a,WriteOut+1
	mov (PadOut)+y,a
	mov a,(ReadPat)+y
	clrc
	adc a,#$30
	mov y,a
	pop a
	movw ReadSeq,ya
	jmp ReadSequence

ReadSequence:
---	cmp WriteOut+1,#$ff
	beq --
	mov y,#$00
	mov a,(ReadSeq)+y
	bmi ++
	bne +
	jmp ReadInterrupt
+
--	call RoutineWriter
	inc y
	call RoutineUpdateWord
	bra ---

++	and a,#$7f
	cmp a,#$5a ;da-ff = VCMDS
	bmi +
	jmp ReadVoiceCommands
+	cmp a,#$46   ;c6-d9 = ties, rests & drum notes
	bmi +
	inc a
	inc a
+	eor a,#$80
	bra --

ReadInterrupt:
	cmp DPSubFlag,#$00
	bne +
ForceInterrupt:
	mov DPSubFlag,#$00
	call RoutineWriter
	inc ReadTrackX
	jmp KonvertReadPattern


-	nop
	bra -
+	cmp DPSubFlag,#$01
	bne +
	mov DPSubFlag,#$00
	movw ya,BackSeq
	movw ReadSeq,ya
	jmp ReadSequence

+	dec DPSubFlag
	movw ya,SubPos
	movw ReadSeq,ya
	jmp ReadSequence

ReadVoiceCommands:
-	setc
	sbc a,#$5a
	asl a
	mov x,a
	mov a,PresetVCMD+1+x ;jump to special VCMD
	push a
	mov a,PresetVCMD+x
	push a
	ret

PresetVCMD:
	dw VcmdDA
	dw VcmdDB
	dw VcmdDC
	dw VcmdDD
	dw VcmdDE
	dw VcmdDF
	dw VcmdE0
	dw VcmdE1
	dw VcmdE2
	dw VcmdE3
	dw VcmdE4
	dw VcmdE5
	dw VcmdE6
	dw VcmdE7
	dw VcmdE8
	dw VcmdE9
	dw VcmdEA
	dw VcmdEB
	dw VcmdEC
	dw VcmdED
	dw VcmdEE
	dw VcmdEF
	dw VcmdF0
	dw VcmdF1
	dw VcmdF2
	dw VcmdF3
	dw VcmdF4
	dw VcmdF5
	dw VcmdF6
	dw VcmdF7
	dw VcmdF8
	dw VcmdF9
	dw VcmdFA
	dw VcmdFB
	dw VcmdFC
	dw VcmdFD
	dw VcmdFE
	dw VcmdFF

VcmdDA:
	mov a,#$e0
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDB:
	mov a,#$e1
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDC:
	mov a,#$e2
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDD:
	mov a,#$f9
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDE:
	mov a,#$e3
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdDF:
	mov a,#$e4
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE0:
	mov a,#$e5
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE1:
	mov a,#$e6
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE2:
	mov a,#$e7
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdE3:
	mov a,#$e8
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE4:
	mov a,#$e9
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE5:
	mov a,#$eb
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE6:
	inc y ;arg 1
	mov a,(ReadSeq)+y
	bne ++
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw CopySeq,ya
	jmp ReadSequence
++	dec a
	mov (ReadSeq)+y,a
	movw ya,CopySeq
	movw ReadSeq,ya
	jmp ReadSequence

VcmdE7:
	mov a,#$ed
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdE8:
	mov a,#$ee
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdE9: ;subroutines
	mov a,#$ef
	inc y ;arg 1
	mov a,(ReadSeq)+y
	push a
	inc y ;arg 2
	mov a,(ReadSeq)+y
	clrc
	adc a,#$30
	push a
	inc y ;arg 3
	mov a,(ReadSeq)+y
;	inc a
	mov DPSubFlag,a
	inc y
	call RoutineUpdateWord
	movw ya,ReadSeq
	movw BackSeq,ya
	pop a
	mov y,a
	pop a
	movw ReadSeq,ya
	movw SubPos,ya
	jmp ReadSequence

VcmdEA:
	mov a,#$f0
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEB:
	mov a,#$f1
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEC:
	mov a,#$f2
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdED:
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEE:
	mov a,#$f4
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdEF:
	mov a,#$f5
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF0:
	mov a,#$f6
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF1:
	mov a,#$f7
	call RoutineWriter
	inc y ;arg 1
	mov a,#$02
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,#$00
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF2:
	mov a,#$f8
	call RoutineWriter
	inc y ;arg 1
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 2
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y ;arg 3
	mov a,(ReadSeq)+y
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdF3:
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF4:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence


VcmdF5:
	inc y
	inc y
	inc y
	inc y
	inc y
	inc y
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF6:
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF7:
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF8:
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdF9:
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFA:
	inc y
	mov a,(ReadSeq)+y
	inc y
	cmp a,#$02
	bne +
	mov a,#$ea
	call RoutineWriter
	mov a,(ReadSeq)+y
	call RoutineWriter
+	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFB:
	inc y
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFC:
	inc y
	inc y
	inc y
	inc y
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFD:
	mov a,#$ec
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFE:
	mov a,#$f3
	call RoutineWriter
	inc y
	call RoutineUpdateWord
	jmp ReadSequence

VcmdFF:
-	nop
	bra -




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
	