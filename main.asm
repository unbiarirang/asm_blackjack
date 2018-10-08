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
DrawProc			PROTO   STDCALL :DWORD, :DWORD
InitGame			PROTO   STDCALL :DWORD
SetColors           PROTO   STDCALL :DWORD


.const
	WinWidth		DWORD	932
	WinHeight		DWORD	800
	WinChildX		DWORD	380
	WinChildY		DWORD	50
	WinChildWidth	DWORD	172 ; CardWidth*2
	WinChildHeight	DWORD	138	; CardHeight+20
	CardWidth		DWORD	86
	CardHeight		DWORD	118


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
	temp			dd	0


.data?
	hInstance			dd		?
	hMenu				dd		?
	hStatic             dd		?
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


.code
start:
	; Get module handle and save it
	invoke 	GetModuleHandle, NULL
	mov 	hInstance, eax
	invoke LoadBitmap,hInstance,BMP_TABLE
	
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
	
	; Create static window for mosaic:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX, WinChildY, WinChildWidth, WinChildHeight,\
	        hWnd, CID_STATIC, hInstance, NULL
	mov     hStatic, eax
	
	; Create toolbar:
	invoke  CreateToolbarEx, hWnd, WS_CHILD + WS_VISIBLE + TBSTYLE_FLAT + WS_BORDER,\
	            CID_TOOLBAR, 6, hInstance, BMP_TOOLBAR, ADDR ToolbarButtons,\
	            8, 32, 32, 32, 32, SIZEOF TBBUTTON
	mov     hToolbar, eax
	invoke  SendMessage, eax, TB_AUTOSIZE, NULL, NULL
	
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
	LOCAL hMemDC:HDC 
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
		invoke CreateCompatibleDC,hdc 
		mov    hMemDC,eax 
		invoke SelectObject,hMemDC,hTable
		invoke GetClientRect,hWnd,addr rect 

		invoke BitBlt,hdc,0,0,rect.right,rect.bottom,hMemDC,0,0,SRCCOPY 
		invoke DeleteDC,hMemDC 
		invoke EndPaint,hWnd,addr ps 
	.ELSEIF eax==WM_COMMAND
		mov 	eax, wParam
		shr 	ax, 16
		.IF		ax==0 ; menu notification
			invoke	ProcessMenuItems, hWnd, wParam
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
            invoke  DrawProc, hWnd, [ebx].hdc
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
		invoke	InvalidateRect, hWnd, NULL, FALSE
	;-------------------------------------------------------------------------------
	; New game
	;-------------------------------------------------------------------------------
	.ELSEIF ax==MI_NEWGAME
		invoke	DrawCard, hWnd, 1
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
	invoke GetRandomNumber,10
	invoke crt_printf,addr DebugStr,eax
	
    invoke  CreateCompatibleDC, NULL
    mov     CardDC, eax

	invoke LoadBitmap,hInstance,BMP_CARD_A1
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
        invoke  DrawNumbers
        ;--- Create the 3D effect on the bitmap ---
        invoke  CreateTiles
    ;.ENDIF
    ;--- Set the new image type ---
    mov     eax, ImageType
    mov     CurImageType, eax
ret
SetBitmap   endp

;======================================================================
;                           Draw Numbers
;======================================================================
DrawNumbers proc uses ebx edi
LOCAL   TempRect:RECT
    ; --- Set the textcolor of ImageDC to TextColor ---
    invoke  SetTextColor, ImageDC, TextColor
    ; --- Fill the imageDC with the tile color brush ---
    invoke  FillRect, ImageDC, ADDR Rect200, hTileColor
    ; --- Set the background mode to transparent (for the text) ---
    invoke  SetBkMode, ImageDC, TRANSPARENT

    ; --- Loop through all the numbers and draw them one by one ---
    xor     ebx, ebx
    .WHILE  ebx<16
        mov     eax, ebx
        inc     eax
        invoke  GetCoordinates, eax
        mov     dx, ax      ; dx  = row
        shr     eax, 16     ; ax  = column
        and     edx, 0ffffh ; make sure that edx = dx
        imul    edx, edx, 50;} Multipy edx as well as eax with 50
        imul    eax, 50     ;}
        mov     TempRect.left, eax
        mov     TempRect.top, edx
        add     eax, 50
        add     edx, 50
        mov     TempRect.right, eax
        mov     TempRect.bottom, edx
        mov     eax, ebx
        inc     eax
        invoke  wsprintf, ADDR Buffer, ADDR NumberFormat, eax
        invoke  DrawText, ImageDC, ADDR Buffer, -1, ADDR TempRect,\
                DT_CENTER or DT_SINGLELINE or DT_VCENTER
    inc ebx
    .ENDW
ret
DrawNumbers endp

;======================================================================
;                           GetCoordinates
;======================================================================
GetCoordinates proc dwTile:DWORD
    mov     eax, dwTile
    dec     eax
    cdq
    mov     ecx, 4
    div     ecx
    ;eax=quotient = row
    ;edx=remainder = column
    shl     edx, 16
    add     eax, edx
ret
GetCoordinates endp

;======================================================================
;                           Create Tiles
;======================================================================
CreateTiles proc uses ebx esi edi
    invoke  GetStockObject, BLACK_PEN
    invoke  SelectObject, ImageDC, eax
; Dark lines, vertical. x = 50k - 1 (k=1,2,3,4)
; ebx = k
; esi = x
    xor     ebx, ebx
    inc     ebx
    ; ebx is 1 now

    .WHILE  ebx<5   ; (ebx= 1,2,3,4)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        dec     esi
        invoke  MoveToEx, ImageDC, esi, 0, NULL
        invoke  LineTo, ImageDC, esi, 199
    inc ebx
    .ENDW

; Dark lines, horizontal. y = 50k - 1 (k=1,2,3,4)
; ebx = k
; esi = y
    xor     ebx, ebx
    inc     ebx
    ; ebx is 1 now
    .WHILE  ebx<5   ; (ebx= 1,2,3,4)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        dec     esi
        invoke  MoveToEx, ImageDC, 0, esi, NULL
        invoke  LineTo, ImageDC, 199, esi
    inc ebx
    .ENDW
    invoke  GetStockObject, WHITE_PEN
    invoke  SelectObject, ImageDC, eax
; Light lines, vertical. x = 50k  (k=0,1,2,3)
; ebx = k
; esi = x
    xor     ebx, ebx

    .WHILE  ebx<4   ; (ebx= 0,1,2,3)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        invoke  MoveToEx, ImageDC, esi, 0, NULL
        invoke  LineTo, ImageDC, esi, 199
    inc ebx
    .ENDW

; Light lines, horizontal. y = 50k (k=0,1,2,3)
; ebx = k
; esi = y
    xor     ebx, ebx

    ; ebx is 1 now

    .WHILE  ebx<4   ; (ebx= 0,1,2,3)
        mov     eax, 50
        mul     ebx
        mov     esi, eax
        invoke  MoveToEx, ImageDC, 0, esi, NULL
        invoke  LineTo, ImageDC, 199, esi
    inc ebx
    .ENDW

ret
CreateTiles endp

;======================================================================
;                           Draw Numbers
;======================================================================
DrawProc proc uses ebx edi esi hWnd:DWORD, hDC:DWORD
	invoke crt_printf,addr DebugStr,100
    ;invoke  BitBlt, hDC, 9, 9, 220, 220, ImageDC, 0, 0, SRCCOPY
	invoke  BitBlt, hDC, 9, 9, 220, 220, CardDC, 0, 0, SRCCOPY
ret
DrawProc endp

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