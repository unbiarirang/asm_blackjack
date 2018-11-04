;===============================================================================
;		client.asm
;===============================================================================
.586
.model		flat, stdcall
option		casemap: none

includelib  \masm32\lib\wsock32.lib
includelib	\masm32\lib\kernel32.lib
includelib	\masm32\lib\user32.lib
includelib	\masm32\lib\gdi32.lib
includelib	\masm32\lib\comctl32.lib
includelib	\masm32\lib\comdlg32.lib

include		\masm32\include\wsock32.inc
include		\masm32\include\kernel32.inc
include		\masm32\include\comctl32.inc
include		\masm32\include\comdlg32.inc
include		\masm32\include\user32.inc
include		\masm32\include\gdi32.inc
include		\masm32\include\windows.inc
include		client.inc
; for debug
include		\masm32\include\msvcrt.inc
includelib	\masm32\lib\msvcrt.lib


WinMain				PROTO	STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
WndProc				PROTO	STDCALL	:DWORD, :DWORD, :DWORD, :DWORD
InitControls		PROTO	STDCALL	:DWORD
InitBitmaps			PROTO	STDCALL	:DWORD
DeleteBitmaps		PROTO	STDCALL
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

	startbtn		equ		1
	stay			equ		2
	draw			equ		3
	displayp1		equ		4
	displayp2		equ		5
	displayp3		equ		6
	displayp4		equ		7
	displayp5		equ		8
	money			equ		9
	showmoney		equ		10
	betting			equ		11

	; upper-left, upper-right, lower-left 
	USER1			POINT <20,0>,<93,10>,<0,98>

atoi PROTO C strptr:DWORD


.data
	AppName				db		"BLACKJACK",0
	ClassName			db		"BKACKJACK",0
	ClassStatic         db     "STATIC",0
	StatusParts         dd      90, 170, -1
	DefaultStatusText   db      "Blackjack 1.0",0

	FontFace            db  "Arial",0
	DebugStr			BYTE	"debug: %d",0ah,0dh,0
	randomState		dd	0
	randomSeed		dd	100711433
	NumberFormat    db      "%lu",0
	Rect200         RECT    <0,0,200,200>
	drawFlag			db	0
	ButtonClassName	db "button",0
	TextClassName db "static",0
	EditClassName db "edit",0
	ButtonText1		db "Start",0
	ButtonText2		db "Draw",0
	ButtonText3		db "Stay",0
	YouText			db "You",0
	ConvertInt		db "%d",0
	
	howmuchmoney	db "10000",0
	howmuchmoney2	db "100",0
	bettingmoney	DWORD ?
	displaymoney		db	"The money you have",0
	connect_comment BYTE "Player[%d] connected.", 0dh, 0ah, 0
	tmp_comment BYTE "TMP = %d",0dh,0ah,0
	string_comment BYTE "Yes/no = %d",0dh,0ah,0
	id_comment BYTE "Your ID number is %d",0dh,0ah,0
	test_comment BYTE "[%d]  [%d]", 0dh, 0ah, 0
	wait_comment BYTE "Please wait for other players",0dh,0ah,0
	debug_comment BYTE "send:%d", 0dh, 0ah, 0
	nofp_comment BYTE "nofp:%d", 0dh, 0ah, 0
	sendyes	BYTE "1"
	sendno BYTE "0"
	wsadata WSADATA <>
	sock dd ?
	sockList DWORD 4 DUP(0)
			
	hMemory dd ?
	available_data dd ?
	actual_data_read dd ?
	sin sockaddr_in <>
	IPAddress db "127.0.0.1",0
	Port equ 9999
	buffer db 10 DUP(3)
	rbuffer db 10 DUP(0)
	maxsocket BYTE 0
	number BYTE 1
	rbf BYTE ?
	htext BYTE ?
	sbf BYTE ?
	nofp BYTE ?
	
	cardtype dd ?
	cardnumber dd ?
	ThreadID DWORD ?


	
	hInstance			dd		?
	playerid			db		?
	userid				db		?
	hMenu				dd		?
	hStatic             dd		?
	hUserWin1			dd		?
	hUserWin2			dd		?
	hUserWin3			dd		?
	hUserWin4			dd		?
	hUserWin5			dd		?
	hStatus             dd		?
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
	mflag				dd		0
	playernum			dd		?
	ifdrawD				dd		1
	ifdrawU1			dd		1
	ifdrawU2			dd		1
	ifdrawU3			dd		1
	ifdrawU4			dd		1
	ifdrawU5			dd		1
	hwndButton			HWND	?
	hwndText			HWND	?
	GetMoney			HWND	?
	cntifdraw			dd		1
	tempif				dd		0
	drawcnt				dd		1
.code
encode PROC, n ;transfer 32bit to 8bit,so that send information to clients.
mov eax,0
mov sbf,0

.while eax < n
	inc eax
	inc sbf
.endw
    ret
encode ENDP

recvndraw PROC,nHwnd:DWORD;if all user have pushed start button,receive card information and draw them
	invoke recv,sock,addr rbf,20,0
	invoke GetDlgItem,nHwnd,draw
	invoke ShowWindow,eax,SW_SHOW
	invoke GetDlgItem,nHwnd,stay
	invoke ShowWindow,eax,SW_SHOW
	invoke InvalidateRect, nHwnd, NULL, FALSE;draw all button and window(card each user have)
	ret
recvndraw ENDP
	
decodeif PROC,n:byte;transfer 8bit to 32bit,so that send information to clients.
mov bl,0
mov tempif,0
.while bl < n
	inc bl
	inc tempif
.endw
    ret
decodeif ENDP

recvifdraw PROC,nHwnd:DWORD
invoke recv,sock,addr rbf,20,0
mov ebx,0
mov cntifdraw,0
.while ebx < playernum				;receive the information
	invoke recv,sock,addr rbf,20,0
	invoke decodeif,rbf
	.if cntifdraw == 0
		mov eax,tempif
		mov ifdrawU1,eax
		inc tempif
	.elseif cntifdraw == 1
		mov eax,tempif
		mov ifdrawU2,eax
		inc tempif
	.elseif cntifdraw == 2
		mov eax,tempif
		mov ifdrawU3,eax
		inc tempif
	.elseif cntifdraw == 3
		mov eax,tempif
		mov ifdrawU4,eax
		inc tempif
	.elseif cntifdraw == 4
		mov eax,tempif
		mov ifdrawU5,eax
		inc tempif
	.endif
	inc cntifdraw
	mov ebx,cntifdraw
.endw

invoke	InvalidateRect, nHwnd, NULL, FALSE	
ret
recvifdraw ENDP



decode PROC,n:byte;transfer 8bit to 32bit,so that send information to clients.
mov bl,0
mov playernum,0
.while bl < n
	inc bl
	inc playernum
.endw
    ret
decode ENDP

start:
;====================connect to server==================
invoke WSAStartup,0101h,addr wsadata
.if eax
	invoke ExitProcess,0
.endif

invoke socket,AF_INET,SOCK_STREAM,0
.if eax != INVALID_SOCKET
	mov sock,eax
.endif
invoke RtlZeroMemory, addr sin,sizeof sin
invoke htons,Port
mov sin.sin_port,ax
mov sin.sin_family,AF_INET
invoke inet_addr,addr IPAddress
mov sin.sin_addr,eax
invoke connect,sock,addr sin,sizeof sin
invoke recv,sock,addr rbf,20,0
mov bl,rbf
mov playerid,bl
mov rbf,0


mov bl,playerid
mov userid,bl

invoke crt_printf,addr id_comment,playerid
invoke crt_printf,addr wait_comment
invoke recv,sock,addr rbf,20,0
invoke decode,rbf
;invoke crt_printf,addr nofp_comment,playernum
;=====================================================================

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

	; Create static window for user4 cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX4, WinChildY4, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN4, hInstance, NULL
	mov     hUserWin4, eax

	; Create static window for user5 cards:
	invoke  CreateWindowEx, WS_EX_CLIENTEDGE, ADDR ClassStatic, NULL,\
	        WS_VISIBLE + WS_CHILD + SS_OWNERDRAW    ,\
	        WinChildX5, WinChildY5, WinCardWidth, WinCardHeight,\
	        hWnd, CID_USERWIN5, hInstance, NULL
	mov     hUserWin5, eax
	


	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR YouText,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        WinChildX1, 358,40,20,hWnd,displayp1,hInstance,NULL

	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR YouText,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        WinChildX2,	325,40,20,hWnd,displayp2,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR YouText,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        WinChildX3, 325,40,20,hWnd,displayp3,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR YouText,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        WinChildX4, 250,40,20,hWnd,displayp4,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR YouText,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        WinChildX5, 250,40,20,hWnd,displayp5,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR displaymoney,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        600, 700,200,20,hWnd,showmoney,hInstance,NULL 
	
	invoke CreateWindowEx,NULL, ADDR TextClassName,ADDR howmuchmoney,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        800, 700,100,20,hWnd,money,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR EditClassName,ADDR howmuchmoney2,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        425, 435,100,20,hWnd,betting,hInstance,NULL 


	invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText1,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        400,500,140,25,hWnd,startbtn,hInstance,NULL 

	invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText2,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        300,500,140,25,hWnd,draw,hInstance,NULL 
    mov  hwndButton,eax

	invoke CreateWindowEx,NULL, ADDR ButtonClassName,ADDR ButtonText3,\ 
				WS_CHILD or WS_VISIBLE or BS_DEFPUSHBUTTON,\ 
		        500,500,140,25,hWnd,stay,hInstance,NULL 
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

	INVOKE  CreateWindowEx,NULL,ADDR ClassName,ADDR AppName,\
	        WS_OVERLAPPEDWINDOW-WS_MAXIMIZEBOX-WS_SIZEBOX,\
	        CW_USEDEFAULT, CW_USEDEFAULT,932,800,NULL,hMenu,\
	        hInst,NULL
	        ;NOTE: notice addition of the hMenu parameter
	        ;      in the CreateWindowEx call.
	mov   	hwnd,eax
	invoke 	ShowWindow, hwnd, CmdShow
	invoke 	UpdateWindow, hwnd
	invoke GetDlgItem,hwnd,draw
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,stay
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,displayp1
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,displayp2
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,displayp3
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,displayp4
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,displayp5
	invoke ShowWindow,eax,SW_HIDE
	invoke GetDlgItem,hwnd,betting
	invoke ShowWindow,eax,SW_HIDE

	
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
	LOCAL hdc:HDC 	;LOCAL hMemDC:HDC 
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
		.IF ax==startbtn
			shr ax,16
			.IF ax==BN_CLICKED
				mov drawcnt,1
				mov cntifdraw,1
				mov tempif,0
				mov ifdrawU1,1
				mov ifdrawU2,1
				mov ifdrawU3,1
				mov ifdrawU4,1
				mov ifdrawU5,1
				invoke crt_printf, addr DebugStr, 111
				invoke send,sock,addr rbf,20,0		
				add mflag,1
				;sub nofp,48
				invoke InitGame,hWnd 
				invoke GetDlgItem,hWnd,startbtn
				invoke ShowWindow,eax,SW_HIDE
				.IF userid==0
					invoke GetDlgItem,hWnd,displayp1
					invoke ShowWindow,eax,SW_SHOW
				.ELSEIF userid==1
					invoke GetDlgItem,hWnd,displayp2
					invoke ShowWindow,eax,SW_SHOW
				.ELSEIF userid==2
					invoke GetDlgItem,hWnd,displayp3
					invoke ShowWindow,eax,SW_SHOW
				.ELSEIF userid==3
					invoke GetDlgItem,hWnd,displayp4
					invoke ShowWindow,eax,SW_SHOW
				.ELSEIF userid==4
					invoke GetDlgItem,hWnd,displayp5
					invoke ShowWindow,eax,SW_SHOW	
				.ENDIF
				invoke GetDlgItem,hWnd,betting
				invoke ShowWindow,eax,SW_SHOW
				 mov drawFlag,0
				invoke DrawCard, hWnd, 1
				invoke CreateThread,NULL,NULL,OFFSET recvndraw,hWnd,NULL,ADDR ThreadID
	
			.ENDIF
		.ELSEIF ax==stay
			shr ax,16
			.IF ax==BN_CLICKED
				;sub nofp,48
				invoke send,sock,addr sendno,20,0	
				invoke GetDlgItem,hWnd,draw
				invoke ShowWindow,eax,SW_HIDE
				invoke GetDlgItem,hWnd,stay
				invoke ShowWindow,eax,SW_HIDE		
				mov mflag,0
				mov drawFlag,1

				invoke GetDlgItem,hWnd,betting
				mov GetMoney,eax
				invoke GetWindowText,GetMoney,addr rbf,255
				lea eax, rbf
				push eax 
				call atoi 
				mov bettingmoney,eax 
				invoke GetDlgItem,hWnd,betting
				invoke ShowWindow,eax,SW_HIDE
				invoke CreateThread,NULL,NULL,OFFSET recvifdraw,hWnd,NULL,ADDR ThreadID
			.ENDIF
		.ELSEIF ax==draw
			shr ax,16
			.IF ax==BN_CLICKED
				invoke encode,1
				invoke crt_printf,addr string_comment,sbf
				invoke send,sock,addr sendyes,20,0		
				;sub nofp,48
				invoke GetDlgItem,hWnd,draw
				invoke ShowWindow,eax,SW_HIDE
				invoke GetDlgItem,hWnd,stay
				invoke ShowWindow,eax,SW_HIDE
				mov mflag,0
				mov drawFlag,1

				invoke GetDlgItem,hWnd,betting
				mov GetMoney,eax
				invoke GetWindowText,GetMoney,addr rbf,255
				lea eax, rbf
				push eax 
				call atoi 
				mov bettingmoney,eax 
				invoke GetDlgItem,hWnd,betting
				invoke ShowWindow,eax,SW_HIDE
				invoke CreateThread,NULL,NULL,OFFSET recvifdraw,hWnd,NULL,ADDR ThreadID
			
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
		.ELSEIF     eax== CID_USERWIN1 || eax==CID_USERWIN2 || eax==CID_USERWIN3 && playernum >= 3 || eax==CID_USERWIN4 && playernum >= 4 || eax==CID_USERWIN5 && playernum >= 5 
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

.if(mflag != 0)
		invoke  CreateCompatibleBitmap, hDC, WinChildWidth, WinChildHeight
		invoke SelectObject, temp, eax

		; the first card
		invoke recv,sock,addr rbf,20,0
		mov eax,0
		mov al,rbf
		mov cardType,eax
		invoke recv,sock,addr rbf,20,0
		mov eax,0
		mov al,rbf
		invoke DisplayCard, hWnd, temp, 9, 9, cardType, eax
		invoke crt_printf,addr test_comment,cardType,eax
		; the second card
		invoke recv,sock,addr rbf,20,0
		mov eax,0
		mov al,rbf
		mov cardType,eax
		invoke recv,sock,addr rbf,20,0
		mov eax,0
		mov al,rbf
		invoke DisplayCard, hWnd, temp, 39, 19, cardType, eax
		invoke crt_printf,addr test_comment,cardType,eax
		invoke  BitBlt, hDC, 0, 0, WinChildWidth, WinChildHeight, temp, 0, 0, SRCCOPY
.endif
ret
DealerDraw endp

;======================================================================
;                           Dealer Draw One More
;======================================================================
DealerDrawOneMore proc uses ebx edi esi hWnd:DWORD, hDC:DWORD
LOCAL cardType:DWORD
	.if ifdrawD == 1
		invoke recv,sock,addr rbf,20,0
		invoke crt_printf,addr debug_comment,rbf
		mov eax,0
		mov al,rbf
		mov cardType,eax
		invoke recv,sock,addr rbf,20,0
		
		invoke encode,20
		mov al,rbf
		.if sbf != al
			mov eax,0
			mov al,rbf
			invoke DisplayCard, hWnd, temp, 69, 29, cardType, eax
		.endif
		invoke crt_printf,addr test_comment,cardType,eax
	.endif
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

	; create bitmap object for memoryDC
	
	.if(mflag != 0)
		invoke  CreateCompatibleBitmap, hDC, WinCardWidth, WinCardHeight
		 mov ebx,index
		invoke SelectObject, [temp+ebx], eax

		; the first card

		invoke recv,sock,addr rbf,20,0
		mov eax,0
		mov al,rbf
		mov cardType,eax
		invoke recv,sock,addr rbf,20,0

		mov al,rbf
		mov ebx,index
		invoke DisplayCard, hWnd, [temp+ebx], 3, 3, cardType, eax
		
		invoke crt_printf,addr test_comment,cardType,eax
		; the second card
		invoke recv,sock,addr rbf,20,0
		
		;invoke GetRandomNumber,4
		mov eax,0
		mov al,rbf
		mov cardType,eax
		;invoke GetRandomNumber,13
		invoke recv,sock,addr rbf,20,0

		mov eax,0
		mov al,rbf
		mov ebx,index
		invoke DisplayCard, hWnd, [temp+ebx], 3, 33, cardType, eax

		invoke crt_printf,addr test_comment,cardType,eax
		mov ebx,index
		invoke  BitBlt, hDC, 0, 0, WinCardWidth, WinCardHeight, [temp+ebx], 0, 0, SRCCOPY
	  .endif
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
	
	.if((drawcnt == 1 && ifdrawU1 == 1) || (drawcnt == 2 && ifdrawU2 == 1) || (drawcnt == 3 && ifdrawU3 == 1) || (drawcnt == 4 && ifdrawU4 == 1) || (drawcnt == 5 && ifdrawU5 == 1));update the card in the order,if the user want to draw card
		invoke recv,sock,addr rbf,20,0
		invoke crt_printf,addr string_comment,rbf
		mov eax,0
		mov al,rbf
		mov cardType,eax

		invoke recv,sock,addr rbf,20,0
		invoke crt_printf,addr string_comment,rbf
		mov eax,0
		mov al,rbf
		mov ebx,index	
		invoke DisplayCard, hWnd, [temp+ebx], 3, 63, cardType, eax
		invoke crt_printf,addr test_comment,cardType,eax
	.endif

	
	invoke crt_printf,ADDR tmp_comment,playernum
	invoke crt_printf,ADDR tmp_comment,drawcnt
	mov eax,drawcnt
	.if eax == playernum
		invoke crt_printf,ADDR wait_comment
		invoke recv,sock,addr rbf,20,0
		invoke crt_printf,ADDR test_comment, rbf,userid
		.if rbf == 1
			invoke GetDlgItem,hWnd,money
			mov GetMoney,eax
			invoke GetWindowText,GetMoney,addr rbf,255
			lea eax, rbf
			push eax 
			call atoi
			add eax,bettingmoney
			add eax,bettingmoney
			;invoke SetWindowText,GetMoney,ADDR howmuchmoney,255
			invoke wsprintf,ADDR howmuchmoney,ADDR ConvertInt,eax
			invoke SetWindowText,GetMoney,ADDR howmuchmoney
			invoke crt_printf,ADDR test_comment, bettingmoney,eax
			
		.elseif rbf == 2
			invoke crt_printf,ADDR test_comment,bettingmoney,eax
		.elseif rbf == 3
		invoke GetDlgItem,hWnd,money
		mov GetMoney,eax
		invoke GetWindowText,GetMoney,ADDR rbf,255
		lea eax, rbf
		push eax 
		call atoi
		sub eax,bettingmoney
		sub eax,bettingmoney
		
		invoke wsprintf,ADDR howmuchmoney,ADDR ConvertInt,eax
		invoke SetWindowText,GetMoney,ADDR howmuchmoney
		invoke crt_printf,ADDR test_comment, bettingmoney,eax
		.endif
	.endif
	inc drawcnt
	mov ebx,index
	
	invoke BitBlt, hDC, 0, 0, WinCardWidth, WinCardHeight, [temp+ebx], 0, 0, SRCCOPY
	invoke GetDlgItem,hWnd,startbtn
	invoke ShowWindow,eax,SW_SHOW
	invoke 	GetModuleHandle, NULL
	mov 	hInstance, eax
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

end start