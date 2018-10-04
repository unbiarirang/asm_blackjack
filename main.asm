;===============================================================================
;		Mosaic.asm
;===============================================================================
.486
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
WinMain		PROTO STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
WndProc		PROTO STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
InitControls PROTO STDCALL :DWORD
InitBitmaps  PROTO STDCALL :DWORD
DeleteBitmaps   PROTO STDCALL

.data
AppName				db		"BLACKJACK",0
ClassName			db		"BKACKJACK",0
ClassStatic         db     "STATIC",0
StatusParts            dd      90, 170, -1
DefaultStatusText      db      "Blackjack 1.0",0
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
WinWidth		DWORD	932
WinHeight		DWORD	800
WinChild		DWORD	470

.data?
hInstance		dd		?
hMenu			dd		?
hStatic             dd     ?
hStatus                dd     ?
hToolbar       dd       ?
BackBufferDC        dd  ?
hBackBuffer         dd  ?
ImageDC             dd  ?
hImage              dd  ?
hBackgroundColor    dd  ?
hTileColor          dd  ?
hFont               dd  ?
TextColor           dd  ?
hTable				dd	?


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
        0, WinChild, WinWidth, WinWidth,\
        hWnd, CID_STATIC, hInstance, NULL
mov     hStatic, eax

; Create toolbar:
invoke  CreateToolbarEx, hStatic, WS_CHILD + WS_VISIBLE + TBSTYLE_FLAT + WS_BORDER,\
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
	.ELSEIF	eax==WM_DESTROY
		invoke  DeleteBitmaps
		invoke	PostQuitMessage, NULL
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
end start