.DEFINE EQU	=
.DEFINE DB	.BYTE
.DEFINE DW	.WORD
	.CODE
PISLOT	EQU	$00
;*
;* ACIA REGISTERS
;*
ACIADR	EQU	$C088+PISLOT*16
ACIASR	EQU	$C089+PISLOT*16
ACIACR	EQU	$C08A+PISLOT*16
ACIAMR	EQU	$C08B+PISLOT*16
;*
;* APPLE I/O LOCATIONS
;*
KEYBD	EQU	$C000
STROBE	EQU	$C010
;*
;* UTIL ROUTINES
;*
WAIT	EQU	$FCA8
COUT	EQU	$FDED
CROUT	EQU	$FD8E
PRBYTE	EQU	$FDDA
PRHEX	EQU	$FDE3
PRNTAX	EQU	$F941
RDKEY	EQU	$FD0C
RDCHAR	EQU	$FD35
GETLN	EQU	$FD6A
;*
;* ZERO PAGE PARAMETERS
;*
PDCMD	EQU	$42
PDUNIT	EQU	$43
PDBUFF	EQU	$44
PDBUFL	EQU	$44
PDBUFH	EQU	$45
PDBLKL	EQU	$46
PDBLKH	EQU	$47
;*
;* SLOT INDEX = SLOT # * 16
;*
SLOTIDX	EQU	$0300
;*
;* DRIVER SCRATCHPAD
;*
TMP	EQU	$0478+PISLOT
PAD0	EQU	$0478+PISLOT
PAD1	EQU	$04F8+PISLOT
PAD2	EQU	$0578+PISLOT
PAD3	EQU	$05F8+PISLOT
PAD4	EQU	$0678+PISLOT
PAD5	EQU	$06F8+PISLOT
PAD6	EQU	$0778+PISLOT
PAD7	EQU	$07F8+PISLOT
;*
;* PRODOS COMMANDS
;*
PDSTAT	EQU	0
PDREAD	EQU	1
PDWRITE	EQU	2
PDFORMT	EQU	3
;*
;* PRODOS ERRORS
;*
PDNOERR	EQU	$00
PDIOERR	EQU	$27
PDNODEV	EQU	$28
PDWRPRT	EQU	$2B
;*
;* PRODOS GLOBAL PAGE LOCATIONS
;*
CLKJMP	EQU	$BF06
DEV1L	EQU	$BF10
DEV1H	EQU	$BF11
DEV2L	EQU	$BF20
DEV2H	EQU	$BF21
DEVCNT	EQU	$BF31
DEVLST	EQU	$BF32
PDTIME	EQU	$BF90
;*
;* ZERO PAGE LOCATIONS FOR LOADER
;*
DSTPTR	EQU	$06
DSTL	EQU	$06
DSTH	EQU	$07
SRCPTR	EQU	$08
SRCL	EQU	$08
SRCH	EQU	$09
;*
;* DRIVER LOADER
;*
DRVRDST	EQU	$D742
DRVRLEN	EQU	125
	LDA	SLOTIDX
	LSR
	LSR
	LSR
	LSR
	STA	SLOTNUM
	LDA	#$60
	STA	CLKJMP		; UNHOOK CLOCK DRIVER (WITH RTS)
	LDA	#<DRVRELOC
	STA	SRCL
	LDA	#>DRVRELOC
	STA	SRCH
	LDA	#<DRVRDST
	STA	DSTL
	LDA	#>DRVRDST
	STA	DSTH
	LDY	#DRVRLEN-1
	BIT	$C08B		; ENABLE LCRAM & WRITE
	BIT	$C08B
CPYLP:	LDA	(SRCPTR),Y
	STA	(DSTPTR),Y
	DEY
	BPL	CPYLP
	INY
	LDX	#SFIXUPTBL-IFIXUPTBL-1
IFIXLP:	LDA	IFIXUPTBL,X
	STA	DSTH
	DEX
	LDA	IFIXUPTBL,X
	STA	DSTL
	LDA	(DSTPTR),Y
	ORA	SLOTIDX
	STA	(DSTPTR),Y
	DEX
	BPL	IFIXLP
	LDX	#DRVRELOC-SFIXUPTBL-1
SFIXLP:	LDA	SFIXUPTBL,X
	STA	DSTH
	DEX
	LDA	SFIXUPTBL,X
	STA	DSTL
	LDA	SLOTNUM
	CLC
	ADC	(DSTPTR),Y
	STA	(DSTPTR),Y
	DEX
	BPL	SFIXLP
	BIT	$C08A		; EBABLE ROM
	LDA	SLOTNUM
	ASL
	TAX
	LDA	DEV1H,X
	CMP	#$DE		; GNODEV
	BNE	INSDEV2
	LDA	#<DRVRDST
	STA	DEV1L,X
	LDA	#>DRVRDST
	STA	DEV1H,X
	LDY	#$00
DEV1LP:	LDA	DEVLST,Y
	BNE	NXTDEV1
	LDA	SLOTIDX
	ORA	#$01
	STA	DEVLST,Y
	INC	DEVCNT
	INC	PIVDCNT
        BNE	INSDEV2
NXTDEV1:
	INY
	CPY	#14
	BNE	DEV1LP
	BEQ	EXIT
INSDEV2:
	LDA	DEV2H,X
	CMP	#$DE
	BNE	PRSLOT
	LDA	#<DRVRDST
	STA	DEV2L,X
	LDA	#>DRVRDST
	STA	DEV2H,X
	INY
INCDEV2:
	LDY	#$00
DEV2LP:	LDA	DEVLST,Y
	BNE	NXTDEV2
	LDA	SLOTIDX
	ORA	#$81
	STA	DEVLST,Y
	INC	DEVCNT
	INC	PIVDCNT
        BNE	PRSLOT
NXTDEV2:
	INY
	CPY	#14
	BNE	DEV2LP
PRSLOT:	LDY	PIVDCNT
	BEQ	EXIT		; NOTHING TO BE DONE HERE
	LDA	SLOTNUM
	ORA	#'0'
	STA	DR1
	STA	DR2
	LDY	#$00
	JSR	PRMSG
	DEC	PIVDCNT
	BEQ	EXIT
	INY
PRMSG:	LDA	MSG,Y
	BEQ	EXIT
	ORA	#$80
	JSR	COUT
	INY
	BNE	PRMSG
EXIT:  	RTS
MSG:	DB	"PIDRIVES AVAILABLE AT ,S"
DR1:	DB	"0,D1"
	DB	0
	DB	" AND ,S"
DR2:	DB	"0,D2"
	DB	0
SLOTNUM: DB	0
PIVDCNT: DB	0
;*
;* FIXUP TABLE
;*
IFIXUPTBL:
	DW	FIXUP1+1
	DW	FIXUP2+1
	DW	FIXUP3+1
	DW	FIXUP4+1
SFIXUPTBL:
	DW	FIXUP5+1
	DW	FIXUP6+1
DRVRELOC:
;*
;* PRODOS INTELLIGENT DEVICE ENTRYPOINT (OVERWRITE CLOCK DRIVER)
;*
	.ORG	DRVRDST
DOCMD:	LDA	PDUNIT
	ASL
	LDA	PDCMD
	ROL
	ASL
	ORA	#$A0
	LDX	PDBLKL
	LDY	PDBLKH
	PHP
FIXUP5:	STA	PAD0
	SEI
	JSR	SENDACC
	TXA
	JSR	SENDACC
	TYA
	JSR	SENDACC
CHKACK: JSR	RECVACC
	TAX
	DEX
FIXUP6:	CPX	PAD0
	BNE	CHKACK
 	LDY	PDCMD
	BEQ	STATUS
	LDX	#$02		; # OF PAGES TO XFER
	DEY			; CPY #PDREAD
	BEQ	RDBLK
	DEY			; CMP #PDWRITE
	BEQ	WRBLK
IOERR:	LDA	#PDIOERR
CMDERR:	PLP
	SEC
DOCLK:	RTS			; NO OP CLOCK ROUTINE
RDBLK:	JSR	RECVACC
	STA	(PDBUFF),Y
	INY
	BNE	RDBLK
	INC	PDBUFH
	DEX
	BNE	RDBLK
STATUS: LDX	#$FF
        DEY			; LDY	#$FF
CMDEX:	JSR	RECVACC
	BNE	CMDERR
	PLP
	CLC
	RTS
WRBLK:	LDA	(PDBUFF),Y
	JSR	SENDACC
	INY
	BNE	WRBLK
	INC	PDBUFH
	DEX
	BNE	WRBLK
        BEQ	CMDEX
;*
;* ACIA I/O ROUTINES
;*
SENDACC:
	PHA
FIXUP1:
SENDWT:	LDA	ACIASR
	AND	#$10
	BEQ	SENDWT
	PLA
FIXUP2:	STA	ACIADR
	RTS
RECVACC:
FIXUP3:
RECVWT:	LDA	ACIASR
	AND	#$08
	BEQ	RECVWT
FIXUP4:	LDA	ACIADR
	RTS
