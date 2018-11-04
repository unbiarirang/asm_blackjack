;===============================================================================
; Include file for mosaic.asm - the mosaic game lesson
;===============================================================================


;--- constants ---

EASY				equ		20
MEDIUM				equ		80
HARD				equ		200

CID_TOOLBAR			equ		602
CID_STATIC 			equ		601
CID_STATUS 			equ 	600
CID_USERWIN1		equ		603
CID_USERWIN2		equ		604
CID_USERWIN3		equ		605
CID_USERWIN4		equ		606
CID_USERWIN5		equ		607

IMAGETYPE_STANDARD	equ		0
IMAGETYPE_NUMBERS	equ		1
IMAGETYPE_BITMAP	equ		2

TILE_ABOVE			equ		0
TILE_BELOW			equ		1
TILE_LEFT			equ		2
TILE_RIGHT			equ		3


ID_TIMER1			equ		220
ID_ABOUTDIALOG		equ		700
;--- resource equates ---

ICON1_BIG	equ	400
ICON2_SMALL	equ	401
ICON_CHIP	equ 402


MAINMENU        equ 301

MI_NEWGAME      equ 101
MI_OPENBITMAP   equ 102
MI_EASY         equ 103
MI_MEDIUM       equ 104
MI_HARD         equ 105
MI_USESTANDARD  equ 106
MI_USENUMBERS   equ 107
MI_USEFILE      equ 108
MI_COLORBLUE    equ 109
MI_COLORRED     equ 110
MI_COLORGREEN   equ 111
MI_COLORUGLY    equ 112
MI_ABOUT        equ 113

BMP_TOOLBAR		equ	801
BMP_DEMOBITMAP	equ	802
BMP_TABLE		equ 200
BMP_CARD_A1		equ 201
BMP_CARD		equ 202


;---- msgbox macro: usage MSGBOX "string to display" -------
MSGBOX MACRO msg:REQ
LOCAL @msg
.data
@msg	db	msg, 0
.code
invoke	MessageBox, NULL, ADDR @msg, ADDR AppName, MB_OK 
ENDM
