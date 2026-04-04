PresetVolumesExp: ;convert volumes from linear to exponential accordingly
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