;===============================================================================
;		Mosaic.asm
;===============================================================================
.586
.model		flat, stdcall
option		casemap: none

includelib	\masm32\lib\kernel32.lib
includelib	\masm32\lib\user32.lib
includelib	\masm32\lib\gdi32.lib
includelib	\masm32\lib\comctl32.lib
includelib	\masm32\lib\comdlg32.lib
include		\masm32\include\kernel32.inc
include		\masm32\include\comctl32.inc
include		\masm32\include\comdlg32.inc
include		\masm32\include\user32.inc
include		\masm32\include\gdi32.inc
include		\masm32\include\windows.inc
include		mosaic.inc
; for debug
include		\masm32\include\msvcrt.inc
includelib	\masm32\lib\msvcrt.lib


WinMain				PROTO	STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
WndProc				PROTO	STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
InitControls		PROTO	STDCALL	:DWORD
InitBitmaps			PROTO	STDCALL	:DWORD
DeleteBitmaps		PROTO	STDCALL
ProcessMenuItems 	PROTO	STDCALL	:DWORD, :DWORD
DrawCard			PROTO	STDCALL	:DWORD, :DWORD
GetRandomNumber		PROTO	STDCALL	:DWORD
SetBitmap			PROTO	STDCALL	:DWORD, :DWORD
GetCoordinates		PROTO	STDCALL	:DWORD
DrawNumbers			PROTO	STDCALL
CreateTiles			PROTO	STDCALL
DrawProc			PROTO   STDCALL :DWORD, :DWORD, :DWORD
DrawOneMore			PROTO   STDCALL :DWORD, :DWORD, :DWORD
DealerDraw			PROTO   STDCALL :DWORD, :DWORD
DealerDrawOneMore	PROTO   STDCALL :DWORD, :DWORD
InitGame			PROTO   STDCALL :DWORD
SetColors           PROTO   STDCALL :DWORD
DisplayCard			PROTO	STDCALL :DWORD, :DWORD, :DWORD, :DWORD, :DWORD, :DWORD


.const
	; Main window
	WinWidth		DWORD	932
	WinHeight		DWORD	800
	; Child window to put dealer's card
	WinChildX		DWORD	380
	WinChildY		DWORD	50
	WinChildWidth	DWORD	156 ; CardWidth*2 + 20 - 10
	WinChildHeight	DWORD	128	; CardHeight + 30
	; User card window
	WinCardWidth	DWORD	83	; CardWidth + 2 * 5
	WinCardHeight	DWORD	168	; CardHeight + 30 * 2 + 2 * 5
	; Child window to put user1's card
	WinChildX1		DWORD	417
	WinChildY1		DWORD	178
	; Child window to put user2's card
	WinChildX2		DWORD	280
	WinChildY2		DWORD	145
	; Child window to put user3's card
	WinChildX3		DWORD	554
	WinChildY3		DWORD	145
	; Child window to put user4's card
	WinChildX4		DWORD	150
	WinChildY4		DWORD	70
	; Child window to put user5's card
	WinChildX5		DWORD	684
	WinChildY5		DWORD	70

	CardWidth		DWORD	73
	CardHeight		DWORD	98

	ButtonID		equ		1

	; upper-left, upper-right, lower-left 
	USER1			POINT <20,0>,<93,10>,<0,98>


.data
	AppName				db		"BLACKJACK",0
	ClassName			db		"BKACKJACK",0
	ClassStatic         db     "STATIC",0
	StatusParts         dd      90, 170, -1
	DefaultStatusText   db      "Blackjack 1.0",0
	ToolbarButtons  TBBUTTON <0, MI_OPENBITMAP, TBSTATE_ENABLED, \
	                          TBSTYLE_BUTTON, 0, NULL, NULL>
	                TBBUTTON <1, MI_NEWGAME, TBSTATE_ENABLED, \
	                          TBSTYLE_BUTTON,0, NULL, NULL>
	                TBBUTTON <NULL, NULL, NULL, \
	                          TBSTYLE_SEP, NULL, NULL> ;--- separator
	                TBBUTTON <2, MI_USESTANDARD, TBSTATE_ENABLED or TBSTATE_CHECKED, \
	                          TBSTYLE_CHECKGROUP,0, NULL, NULL>
	                TBBUTTON <3, MI_USENUMBERS, TBSTATE_ENABLED, \
	                          TBSTYLE_CHECKGROUP,0, NULL, NULL>
	                TBBUTTON <4, MI_USEFILE, TBSTATE_ENABLED, \
	                          TBSTYLE_CHECKGROUP,0, NULL, NULL>
	                TBBUTTON <NULL, NULL, NULL, \
	                          TBSTYLE_SEP, NULL, NULL> ;--- separator
	                TBBUTTON <5, MI_ABOUT, TBSTATE_ENABLED, \
	                          TBSTYLE_BUTTON,0, NULL, NULL>
	FontFace            db  "Arial",0
	DebugStr			BYTE	"debug: %d",0ah,0dh,0
	randomState		dd	0
	randomSeed		dd	100711433
	NumberFormat    db      "%lu",0
	Rect200         RECT    <0,0,200,200>
	drawFlag			db	0
	ButtonClassName	db "button",0
	ButtonText1		db "Stay",0
	ButtonText2		db "Draw",0



.data?
	hInstance			dd		?
	hMenu				dd		?
	hStatic             dd		?
	hUserWin1			dd		?
	hUserWin2			dd		?
	hUserWin3			dd		?
	hUserWin4			dd		?
	hUserWin5			dd		?
	hStatus             dd		?
	hToolbar			dd      ?
	BackBufferDC        dd		?
	hBackBuffer         dd		?
	ImageDC             dd		?
	hImage              dd		?
	hBackgroundColor    dd		?
	hTileColor          dd		?
	hFont               dd		?
	TextColor           dd		?
	hTable				dd		?
	CurImageType        dd      ?
	Buffer				db      200 dup (?)
	CardDC				dd		?
	hCard				dd		?
	mainhdc				dd		?
	hMemDC				dd		?
	User1DC				dd		?
	temp				dd		6 dup (?)
	hwndButton			HWND	?


.code
start:
	; Get module handle and save it
	invoke 	GetModuleHandle, NULL
	mov 	hInstance, eax
	
	; Init Common Controls library
	invoke	InitCommonControls
	
    ; Run winmain procedure and exit program
    invoke  WinMain, hInstance, NULL, NULL, SW_SHOWNORMAL
	invoke 	ExitProcess,eax

;======================================================================
;                           Init Controls
;======================================================================
InitControls proc hWnd:DWORD
LOCAL DefaultFont:DWORD
	;--- Create a static control ---
	
	;--- save default font ---
	invoke  GetStockObject, DEFAULT_GUI_FONT
	mov     DefaultFont, eax
	
	; Create statusbar window:
	invoke  CreateStatusWindow, WS_CHILD + WS_VISIBLE,\
	         ADDR DefaultStatusText, hWnd, CID_STATUS
	mov     hStatus, eax
	invoke  SendMessage, hStatus, WM_SETFONT, DefaultFont, TRUE
	invoke  SendMessage, hStatus, SB_SETPARTS,3, ADDR StatusParts
	
	; Create static window for dealer card:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX, WinChildY, WinChildWidth, WinChildHeight,\
	        hWnd, CID_STATIC, hInstance, NULL
	mov     hStatic, eax

	; Create static window for user1 cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX1, WinChildY1, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN1, hInstance, NULL
	mov     hUserWin1, eax

	; Create static window for user2 cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX2, WinChildY2, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN2, hInstance, NULL
	mov     hUserWin2, eax

	; Create static window for user3 cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX3, WinChildY3, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN3, hInstance, NULL
	mov     hUserWin3, eax

	; Create static window for user cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX4, WinChildY4, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN4, hInstance, NULL
	mov     hUserWin4, eax

	; Create static window for user cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX5, WinChildY5, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN5, hInstance, NULL
	mov     hUserWin5, eax
	
	; Create toolbar:
	invoke  CreateToolbarEx, hWnd, WS_CHILD + WS_VISIBLE + TBSTYLE_FLAT + WS_BORDER,\
	            CID_TOOLBAR, 6, hInstance, BMP_TOOLBAR, ADDR ToolbarButtons,\
	            8, 32, 32, 32, 32, SIZEOF TBBUTTON
	mov     hToolbar, eax
	invoke  SendMessage, eax, TB_AUTOSIZE, NULL, NULL

	invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText1,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        300,500,140,25,hWnd,ButtonID,hInstance,NULL 
    mov  hwndButton,eax
	
ret
InitControls endp

;===============================================================================
; WinMain
;===============================================================================
WinMain proc hInst:HINSTANCE,hPrevInst:HINSTANCE,CmdLine:LPSTR,CmdShow:DWORD
LOCAL wc:WNDCLASSEX
LOCAL msg:MSG
LOCAL hwnd:HWND
	mov   	wc.cbSize,SIZEOF WNDCLASSEX
	mov   	wc.style, CS_HREDRAW or CS_VREDRAW
	mov   	wc.lpfnWndProc, OFFSET WndProc
	mov   	wc.cbClsExtra,NULL
	mov   	wc.cbWndExtra,NULL
	push  	hInstance
	pop   	wc.hInstance
	mov   	wc.hbrBackground,COLOR_WINDOW
	mov   	wc.lpszMenuName, NULL
	mov   	wc.lpszClassName, OFFSET ClassName
	invoke 	LoadIcon, hInstance, ICON_CHIP
	mov   	wc.hIcon, eax
	invoke 	LoadIcon, hInstance, ICON_CHIP
	mov   	wc.hIconSm, eax
	invoke 	LoadCursor,NULL,IDC_ARROW
	mov   	wc.hCursor,eax
	invoke 	RegisterClassEx, addr wc
	invoke  LoadMenu, hInstance, MAINMENU ;load menu
	mov     hMenu, eax                    ;store handle
	INVOKE  CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
	        WS_OVERLAPPEDWINDOW-WS_MAXIMIZEBOX-WS_SIZEBOX,\
	        CW_USEDEFAULT, CW_USEDEFAULT,932,800,NULL,hMenu,\
	        hInst,NULL
	        ;NOTE: notice addition of the hMenu parameter
	        ;      in the CreateWindowEx call.
	mov   	hwnd,eax
	invoke 	ShowWindow, hwnd, CmdShow
	invoke 	UpdateWindow, hwnd
	.WHILE 	TRUE
		invoke 	GetMessage, ADDR msg,NULL,0,0
		.BREAK 	.IF (!eax)
		invoke 	TranslateMessage, ADDR msg
		invoke 	DispatchMessage, ADDR msg
	.ENDW
	mov     eax,msg.wParam
	ret
WinMain endp

;===============================================================================
;	Window procedure
;===============================================================================	
WndProc proc	hWnd:DWORD, uMsg:DWORD, wParam:DWORD, lParam:DWORD
	LOCAL ps:PAINTSTRUCT 
	LOCAL hdc:HDC 
	;LOCAL hMemDC:HDC 
	LOCAL rect:RECT 
	mov eax, uMsg
	.IF 	eax==WM_CREATE
		invoke InitControls, hWnd
		invoke InitBitmaps, hWnd
		invoke InitGame, hWnd
		invoke LoadBitmap,hInstance,BMP_TABLE
		mov hTable,eax

	.ELSEIF	eax==WM_PAINT
		invoke BeginPaint,hWnd,addr ps 
		mov    hdc,eax 
		mov	   mainhdc,eax
		invoke CreateCompatibleDC,hdc 
		mov    hMemDC,eax 
		invoke SelectObject,hMemDC,hTable
		invoke GetClientRect,hWnd,addr rect 

		invoke BitBlt,hdc,0,0,rect.right,rect.bottom,hMemDC,0,0,SRCCOPY
		invoke DeleteDC,hMemDC
		invoke EndPaint,hWnd,addr ps

	.ELSEIF eax==WM_COMMAND
		mov 	eax, wParam
		.IF ax==ButtonID
			shr ax,16
			.IF ax==BN_CLICKED
				invoke crt_printf, addr DebugStr, 111
			.ENDIF
		.ELSE
			shr 	ax, 16
			.IF		ax==0 ; menu notification
				invoke	ProcessMenuItems, hWnd, wParam
			.ENDIF
		.ENDIF
	.ELSEIF	eax==WM_DESTROY
		invoke  DeleteBitmaps
		invoke	PostQuitMessage, NULL
    .ELSEIF eax==WM_DRAWITEM
        mov     eax, wParam
        .IF     eax==CID_STATIC
            push    ebx
            mov     ebx, lParam
            assume  ebx:ptr DRAWITEMSTRUCT
			.IF drawFlag==0
				invoke  DealerDraw, hWnd, [ebx].hdc
			.ELSE
				invoke	DealerDrawOneMore, hWnd, [ebx].hdc
			.ENDIF
            assume  ebx:nothing
            pop     ebx
            xor     eax, eax
            inc     eax
		.ELSEIF     eax==CID_USERWIN1 || eax==CID_USERWIN2 || eax==CID_USERWIN3 || eax==CID_USERWIN4 || eax==CID_USERWIN5
            push    ebx
            mov     ebx, lParam
            assume  ebx:ptr DRAWITEMSTRUCT
			.IF drawFlag==0
				invoke  DrawProc, hWnd, [ebx].hdc, eax
			.ELSE
				invoke DrawOneMore, hWnd, [ebx].hdc, eax
			.ENDIF
            assume  ebx:nothing
            pop     ebx
            xor     eax, eax
            inc     eax
		.ELSE
            xor     eax, eax
        .ENDIF
	.ELSE
		invoke 	DefWindowProc,hWnd,uMsg,wParam,lParam		
		ret
	.ENDIF
ret
WndProc endp

;======================================================================
;                           Init Bitmaps
;======================================================================
InitBitmaps proc hWnd:DWORD
; Create DC's for backbuffer and current image
    invoke  CreateCompatibleDC, NULL
    mov     BackBufferDC, eax

    invoke  CreateCompatibleDC, NULL
    mov     ImageDC, eax

; Create bitmap for backbuffer:
    invoke  GetDC, hWnd
    push    eax
    invoke  CreateCompatibleBitmap, eax, 200+20,200+20
    mov     hBackBuffer, eax
    pop     eax
    invoke  ReleaseDC, hWnd, eax
    invoke  SelectObject, BackBufferDC, hBackBuffer

; Create Arial font for the numbers
    invoke  CreateFont, -30, NULL, NULL, NULL, FW_EXTRABOLD, \
            FALSE, FALSE, FALSE, NULL, NULL, NULL, NULL, \
            NULL, ADDR FontFace
    mov     hFont, eax

; Select font in Image DC
	invoke   SelectObject, ImageDC, hFont

	invoke   CreateSolidBrush, 0FF8000h
	mov      hBackgroundColor, eax
	invoke   CreateSolidBrush, 0FF8080h
	mov      hTileColor, eax

	mov      TextColor, 0800000h
ret
InitBitmaps endp

DeleteBitmaps   PROTO STDCALL
;======================================================================
;                           Delete Bitmaps
;======================================================================
DeleteBitmaps proc
    invoke  DeleteDC, BackBufferDC
    invoke  DeleteDC, ImageDC
    invoke  DeleteObject, hImage
    invoke  DeleteObject, hBackBuffer
    invoke  DeleteObject, hFont
    invoke  DeleteObject, hBackgroundColor
    invoke  DeleteObject, hTileColor
ret
DeleteBitmaps endp

;======================================================================
;                           Process Menu Items
;======================================================================
ProcessMenuItems proc hWnd:DWORD, wParam:DWORD
	mov		eax, wParam
	;-------------------------------------------------------------------------------
	; Open Bitmap
	;-------------------------------------------------------------------------------
	.IF ax==MI_OPENBITMAP
		;--- delete old image ---
        invoke  DeleteObject, CardDC
		invoke	DeleteObject, temp
		invoke	DeleteObject, [temp + 4]
		invoke	DeleteObject, [temp + 8]
		invoke	DeleteObject, [temp + 12]
		invoke	DeleteObject, [temp + 16]
		invoke	DeleteObject, [temp + 20]
		invoke	InvalidateRect, hWnd, NULL, FALSE
	;-------------------------------------------------------------------------------
	; New game
	;-------------------------------------------------------------------------------
	.ELSEIF ax==MI_NEWGAME
		mov drawFlag,0
		invoke	DrawCard, hWnd, 1
		invoke	InvalidateRect, hWnd, NULL, FALSE	
	;-------------------------------------------------------------------------------
	; Draw One More
	;-------------------------------------------------------------------------------
	.ELSEIF ax==MI_ABOUT
		mov drawFlag,1
		invoke	InvalidateRect, hWnd, NULL, FALSE	
	;-------------------------------------------------------------------------------
	; Image type
	;-------------------------------------------------------------------------------
	.ELSEIF ax==MI_USEFILE
	    invoke    CheckMenuItem, hMenu, MI_USEFILE, MF_CHECKED
	    invoke    CheckMenuItem, hMenu, MI_USENUMBERS, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_USESTANDARD, MF_UNCHECKED
	    invoke    SendMessage, hToolbar, TB_CHECKBUTTON, MI_USEFILE, TRUE
	    ;--- yet to do ---
	.ELSEIF ax==MI_USENUMBERS
	    invoke    CheckMenuItem, hMenu, MI_USEFILE, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_USENUMBERS, MF_CHECKED
	    invoke    CheckMenuItem, hMenu, MI_USESTANDARD, MF_UNCHECKED
	    invoke    SendMessage, hToolbar, TB_CHECKBUTTON, MI_USENUMBERS, TRUE
	    invoke    SetBitmap, hWnd, IMAGETYPE_NUMBERS
	    invoke    InvalidateRect, hWnd, NULL, FALSE
	.ELSEIF ax==MI_USESTANDARD
	    invoke    CheckMenuItem, hMenu, MI_USEFILE, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_USENUMBERS, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_USESTANDARD, MF_CHECKED
	    invoke    SendMessage, hToolbar, TB_CHECKBUTTON, MI_USESTANDARD, TRUE
	    invoke    SetBitmap, hWnd, IMAGETYPE_STANDARD
	    invoke    InvalidateRect, hWnd, NULL, FALSE
	;-------------------------------------------------------------------------------
	; Color Scheme
	;-------------------------------------------------------------------------------
	.ELSEIF ax==MI_COLORBLUE
	    invoke    SetColors, eax
	    invoke    CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORBLUE, MF_CHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORUGLY, MF_UNCHECKED
	    invoke    SetBitmap, hWnd, CurImageType
	    invoke    InvalidateRect, hWnd, NULL, FALSE
	.ELSEIF ax==MI_COLORRED
	    invoke    SetColors, eax
	    invoke    CheckMenuItem, hMenu, MI_COLORRED, MF_CHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORUGLY, MF_UNCHECKED
	    invoke    SetBitmap, hWnd, CurImageType
	    invoke    InvalidateRect, hWnd, NULL, FALSE
	.ELSEIF ax==MI_COLORGREEN
	    invoke    SetColors, eax
	    invoke    CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORGREEN, MF_CHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORUGLY, MF_UNCHECKED
	    invoke    SetBitmap, hWnd, CurImageType
	    invoke    InvalidateRect, hWnd, NULL, FALSE
	.ELSEIF ax==MI_COLORUGLY
	    invoke    SetColors, eax
	    invoke    CheckMenuItem, hMenu, MI_COLORRED, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORBLUE, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORGREEN, MF_UNCHECKED
	    invoke    CheckMenuItem, hMenu, MI_COLORUGLY, MF_CHECKED
	    invoke    SetBitmap, hWnd, CurImageType
	    invoke    InvalidateRect, hWnd, NULL, FALSE
		.ENDIF
ret
ProcessMenuItems endp

;======================================================================
;                           Draw Card
;======================================================================
DrawCard proc hWnd:DWORD, wParam:DWORD
	mov		eax, wParam
	
    invoke  CreateCompatibleDC, NULL
    mov     CardDC, eax
	invoke  CreateCompatibleDC, NULL
    mov     temp, eax
	invoke  CreateCompatibleDC, NULL
    mov     [temp+4], eax
	invoke  CreateCompatibleDC, NULL
    mov     [temp+8], eax
	invoke  CreateCompatibleDC, NULL
    mov     [temp+12], eax
	invoke  CreateCompatibleDC, NULL
    mov     [temp+16], eax
	invoke  CreateCompatibleDC, NULL
    mov     [temp+20], eax

	invoke LoadBitmap,hInstance,BMP_CARD
	mov hCard,eax
	
	invoke SelectObject,CardDC,hCard
ret
DrawCard endp

;================================================================================
;							GetRandomNumber
;================================================================================
GetRandomNumber PROC range:DWORD
    ; count the number of cycles since
    ; the machine has been reset
    rdtsc

    ; accumulate the value in eax and manage
    ; any carry-spill into the x state var
    adc eax, edx
    adc eax, randomState

    ; multiply this calculation by the seed
    mul randomSeed

    ; manage the spill into the x state var
    adc eax, edx
    mov randomState, eax

    ; put the calculation in range of what
    ; was requested
    mul range

    ; ranged-random value in eax
    mov eax, edx

ret
GetRandomNumber ENDP

;======================================================================
;                           Set Bitmap
;======================================================================
SetBitmap   proc hWnd:DWORD, ImageType:DWORD
    mov     eax, ImageType
    ;.IF eax==IMAGETYPE_NUMBERS
        ;--- delete old image ---
        invoke  DeleteObject, hImage
        ;--- Get DC ---
        invoke  GetDC, hWnd
        push    eax
        ;--- Create new bitmap for the numbers bitmap ---
        invoke  CreateCompatibleBitmap, eax, 200, 200
        mov     hImage, eax
        pop     eax
        ;--- Release DC ---
        invoke  ReleaseDC, hWnd, eax
        ;--- Select new bitmap in DC ---
        invoke  SelectObject, ImageDC, hImage
        ;--- Draw numbers on the bitmap ---
        ;invoke  DrawNumbers
        ;--- Create the 3D effect on the bitmap ---
        ;invoke  CreateTiles
    ;.ENDIF
    ;--- Set the new image type ---
    mov     eax, ImageType
    mov     CurImageType, eax
ret
SetBitmap   endp

;======================================================================
;                           Dealer Draw 2 Cards
;======================================================================
DealerDraw proc uses ebx edi esi hWnd:DWORD, hDC:DWORD
LOCAL cardType:DWORD
	; create bitmap object for memoryDC
	invoke  CreateCompatibleBitmap, hDC, WinChildWidth, WinChildHeight
	invoke SelectObject, temp, eax

	; the first card
	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	invoke DisplayCard, hWnd, temp, 9, 9, cardType, eax

	; the second card
	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	invoke DisplayCard, hWnd, temp, 39, 19, cardType, eax
		
	invoke  BitBlt, hDC, 0, 0, WinChildWidth, WinChildHeight, temp, 0, 0, SRCCOPY
ret
DealerDraw endp

;======================================================================
;                           Dealer Draw One More
;======================================================================
DealerDrawOneMore proc uses ebx edi esi hWnd:DWORD, hDC:DWORD
LOCAL cardType:DWORD
	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	invoke DisplayCard, hWnd, temp, 69, 29, cardType, eax

	invoke  BitBlt, hDC, 0, 0, WinChildWidth, WinChildHeight, temp, 0, 0, SRCCOPY
ret
DealerDrawOneMore endp

;======================================================================
;                           User Draw Cards
;======================================================================
DrawProc proc uses ebx edi esi hWnd:DWORD, hDC:DWORD, userID:DWORD
LOCAL cardType:DWORD
LOCAL index:DWORD
	sub userID,602
	mov eax,userID
	mov ebx,SIZEOF DWORD
	mul ebx
	mov index,eax
	invoke crt_printf, addr DebugStr, index

	; create bitmap object for memoryDC
	invoke  CreateCompatibleBitmap, hDC, WinCardWidth, WinCardHeight
	mov ebx,index
	invoke SelectObject, [temp+ebx], eax

	; the first card
	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	mov ebx,index
	invoke DisplayCard, hWnd, [temp+ebx], 3, 3, cardType, eax

	; the second card
	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	mov ebx,index
	invoke DisplayCard, hWnd, [temp+ebx], 3, 33, cardType, eax

	mov ebx,index
	invoke  BitBlt, hDC, 0, 0, WinCardWidth, WinCardHeight, [temp+ebx], 0, 0, SRCCOPY
ret
DrawProc endp

;======================================================================
;                           User Draw One More
;======================================================================
DrawOneMore proc uses ebx edi esi hWnd:DWORD, hDC:DWORD, userID:DWORD
LOCAL cardType:DWORD
LOCAL index:DWORD
	sub userID,602
	mov eax,userID
	mov ebx,SIZEOF DWORD
	mul ebx
	mov index,eax

	invoke GetRandomNumber,4
	mov cardType,eax
	invoke GetRandomNumber,13
	mov ebx,index
	invoke DisplayCard, hWnd, [temp+ebx], 3, 63, cardType, eax

	mov ebx,index
	invoke  BitBlt, hDC, 0, 0, WinCardWidth, WinCardHeight, [temp+ebx], 0, 0, SRCCOPY
ret
DrawOneMore endp

;======================================================================
;                           Display a Card
;======================================================================
; cardType	: CARDTYPE1,2,3,4
; cardNum	: 0 ~ 12
DisplayCard proc uses ebx edi esi eax edx hWnd:DWORD, hDC:DWORD, leftTopX:DWORD, leftTopY:DWORD, cardType:DWORD, cardNum:DWORD
	LOCAL X:DWORD
	LOCAL Y:DWORD

	; compute X pos
	mov eax,CardWidth
	mul cardNum
	mov X,eax

	; compute Y pos
	mov eax,CardHeight
	mul cardType
	mov Y,eax
	
	invoke  BitBlt, hDC, leftTopX, leftTopY, CardWidth, CardHeight, CardDC, X, Y, SRCCOPY

	;mov esi,OFFSET USER1
	;invoke PlgBlt,hDC,esi,CardDC,0,0,CardWidth,CardHeight,NULL,0,0
	

ret
DisplayCard endp

;======================================================================
;                           InitGame
;======================================================================
InitGame    proc    hWnd:DWORD
    invoke  SetBitmap, hWnd, IMAGETYPE_NUMBERS
ret
InitGame    endp

;======================================================================
;                            Set Colors
;======================================================================
SetColors proc uses ebx cType:DWORD
    invoke  DeleteObject, hBackgroundColor
    invoke  DeleteObject, hTileColor
; ebx = background
; edx = text
; eax = tile
    mov     eax, cType
    .IF     ax==MI_COLORRED
        mov     eax, 00000A0h
        mov     edx, 00000FFh
        mov     ebx, 05050E0h
    .ELSEIF ax==MI_COLORBLUE
        mov     eax, 0FF8080h
        mov     edx, 0800000h
        mov     ebx, 0FF8000h
    .ELSEIF ax==MI_COLORGREEN
        mov     eax, 000A000h
        mov     edx, 000FF00h
        mov     ebx, 050E050h
    .ELSEIF ax==MI_COLORUGLY
        mov     eax, 0FF00FFh
        mov     edx, 000FF00h
        mov     ebx, 00000FFh
    .ENDIF
    mov     TextColor, edx

    invoke  CreateSolidBrush, eax
    mov     hTileColor, eax

    invoke  CreateSolidBrush, ebx
    mov     hBackgroundColor, eax
ret
SetColors endp



end start