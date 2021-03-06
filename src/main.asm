
INCLUDE "gbhardware.inc" ; standard hardware definitions from devrs.com
INCLUDE "ibmpc1.inc" ; ASCII character set from devrs.com
INCLUDE "interrupts.inc"

lcd_WaitVBlank: MACRO
	ld      a,[rLY]
	cp      145           ; Is display on scan line 145 yet?
	jr      nz,@-4        ; no, keep waiting
	ENDM

; ROM location $0100 is also the code execution starting point
SECTION	"start",ROM0[$0100]
    nop
    jp	begin

; ROM header
	ROM_HEADER	ROM_NOMBC, ROM_SIZE_32KBYTE, RAM_SIZE_0KBYTE

; ****************************************************************************************
; Initialization
; ****************************************************************************************
begin:
	di                  ; disable interrupts
	ld	sp, $ffff		; set the stack pointer to highest mem location we can use + 1

init:
	call int_Reset      ; Set all interrupt routines to do nothing
	ld	a, %11100100 	; Set window palette colors, from darkest to lightest
	ld	[rBGP], a		

	ld	a, 0			; Set the background scroll to (0,0)
	ld	[rSCX], a
	ld	[rSCY], a

; Next we shall turn the LCD off so that we can safely copy data to video RAM. 

	call	StopLCD		
	
	ld	hl, TileData
	ld	de, _VRAM		
	ld	bc, 8*256 		; the ASCII character set: 256 characters, each with 8 bytes of display data
	call	mem_CopyMono	; load tile data
	
; Turn the LCD back on. 
; Parameters are explained in the I/O registers section of The GameBoy reference under I/O register LCDC
	ld	a, LCDCF_ON|LCDCF_BG8000|LCDCF_BG9800|LCDCF_BGON|LCDCF_OBJ16|LCDCF_OBJOFF 
	ld	[rLCDC], a	

; Clear the background to all white by setting every tile to whitespace.
          
	ld	a, 186		; Actually, this is the || character     (ASCII FOR BLANK SPACE = 32)
	ld	hl, _SCRN0
	ld	bc, SCRN_VX_B * SCRN_VY_B
	call	mem_SetVRAM

	
; ****************************************************************************************
; Loading
; Print the title to two places on the screen.
; ****************************************************************************************

	ld	hl, Title
	ld	de, _SCRN0 + 3 + (SCRN_VY_B*7) ; 
	ld	bc, TitleEnd-Title
	call	mem_CopyVRAM

	ld	hl, Title
	ld	de, _SCRN0 + 3 + (SCRN_VY_B*12) ; 
	ld	bc, TitleEnd-Title
	call	mem_CopyVRAM

; ****************************************************************************************
; Effects
; ****************************************************************************************
effects:
	call effect1_Run
	call int_Reset
.wait
	halt
	nop 
	jr .wait
	
; ****************************************************************************************
; StopLCD:
; turn off LCD if it is on
; and wait until the LCD is off
; ****************************************************************************************
StopLCD:
	ld  a,[rLCDC]
	rlca                    ; Put the high bit of LCDC into the Carry flag
	ret  nc                 ; Screen is off already. Exit.
	lcd_WaitVBlank
; Turn off the LCD
	ld      a,[rLCDC]
	res     7,a             ; Reset bit 7 of LCDC
	ld      [rLCDC],a

	ret

; ****************************************************************************************
; hard-coded data
; ****************************************************************************************
Title:
	DB	"I'm freaking out."
TitleEnd:
    nop

TileData:
    chr_IBMPC1  1,8 ; LOAD ENTIRE CHARACTER SET


