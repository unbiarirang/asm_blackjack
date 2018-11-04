;===============================================================================
;		Mosaic.asm
;===============================================================================
.586
.model		flat, stdcall
option		casemap: none

includelib	\masm32\lib\wsock32.lib
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
	ClassStatic         db      "STATIC",0
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
	ButtonText1		db "Stay",0
	ButtonText2		db "Draw",0
	wsadata WSADATA <>
	sock dd ?
	sockList DWORD 4 DUP(0)
	ScoreD	DWORD		3	DUP (-1)
	ScoreP	DWORD		12	DUP (0)
	ScoreT	DWORD		5	DUP (-1)
	TempScore1 DWORD		0
	TempScore2 DWORD		0
	TempScore3 DWORD		0
	TempScore4 DWORD		0
	TotalScore DWORD	5	DUP (0)
	DTotalScore DWORD	0
	CountArray	DWORD	0
	ResultOfGame	DWORD 0
	hMemory dd ?
	buffer BYTE 10 DUP(1)
	rbuffer BYTE 10 DUP(0)
	available_data dd ?
	actual_data_read dd ?
	sin sockaddr_in <>
	Port equ 9999
	nofp_comment BYTE "nofp:%d", 0dh, 0ah, 0
	debug_comment BYTE "send:%d", 0dh, 0ah, 0
	connect_comment BYTE "Player[%d] connected.", 0dh, 0ah, 0
	test_comment BYTE "[%d]  [%d]", 0dh, 0ah, 0
	setnumber_comment BYTE "Please set the number of players(Max:5,Min:1)", 0dh, 0ah, 0
	wait_comment BYTE "Please wait for players join the game",0dh,0ah,0
	warning BYTE "The number does not meet the requirements.", 0dh, 0ah, 0
	setnumber BYTE "%c", 0
	string_comment BYTE "Yes/no = %d",0dh,0ah,0
	here_comment BYTE "here %d",0dh,0ah,0
	nofp BYTE 0  ;the number of player
	playernum DWORD 0
	number BYTE 1
	cntyes DWORD 0

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

	CountScore			dd		0
	CardDC				dd		?
	hCard				dd		?
	mainhdc				dd		?
	hMemDC				dd		?
	User1DC				dd		?
	temp				dd		6 dup (?)
	hi					dd		?
	ifdrawU1			dd		1
	ifdrawU2			dd		1
	ifdrawU3			dd		1
	ifdrawU4			dd		1
	ifdrawU5			dd		1
	hwndButton			HWND	?
	cnt db ?
	cntconn dd ?
	sbf db ?
	rbf db ?
	CT dd ?
	CN dd ?
	ThreadID DWORD ?
	yesorno dd 0

.code
ThreadRecv PROC, k:DWORD
	mov ebx,k
	invoke recv,sockList[ebx * 4],addr rbf,20,0	
	inc cntconn
	ret
ThreadRecv ENDP

decode PROC,n:byte;transfer 8bit to 32bit,so that send information to clients.
mov bl,"0"
mov yesorno,0
.while bl < n
	inc bl
	inc yesorno
.endw
    ret
decode ENDP

decodenofp PROC,n:byte;transfer 8bit to 32bit,so that send information to clients.
mov bl,"0"
mov playernum,0
.while bl < n
	inc bl
	inc playernum
.endw
    ret
decodenofp ENDP

ThreadRecvDraw PROC, k:DWORD;;ïÈâ¥êó??ìÑé©õÎø«
	mov ebx,k
	invoke recv,sockList[ebx * 4],addr rbf,20,0	
	invoke decode,rbf
	.if k == 0
		mov eax,yesorno
		mov ifdrawU1,eax
	.elseif k == 1
		mov eax,yesorno
		mov ifdrawU2,eax
	.elseif k == 2
		mov eax,yesorno
		mov ifdrawU3,eax
	.elseif k == 3
		mov eax,yesorno
		mov ifdrawU4,eax
	.else 
		mov eax,yesorno
		mov ifdrawU5,eax
	.endif
	inc cntconn
	ret
ThreadRecvDraw ENDP



encode PROC, tempN:DWORD ;transfer 32bit to 8bit,so that send information to clients.
mov eax,0
mov sbf,0

.while eax < tempN
	inc eax
	inc sbf
.endw

    ret
encode ENDP

send_all PROC info;send information to all clients.
mov ebx,0
invoke encode,info

.while ebx < playernum
	invoke send,sockList[ebx * 4],addr sbf,20,0
	inc ebx
.endw
	ret
send_all ENDP

start:
;=====================connect clients to server==========================
invoke crt_printf, addr setnumber_comment
invoke crt_scanf, addr setnumber, addr nofp
invoke crt_printf, addr wait_comment

invoke decodenofp,nofp
sub nofp, 48
.if nofp <= 0 || nofp >= 6
	invoke crt_printf, addr warning
	invoke Sleep,5000
	invoke ExitProcess,0
.endif

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
mov sin.sin_addr,INADDR_ANY

invoke bind, sock, addr sin, sizeof sin
    .if eax == SOCKET_ERROR
        invoke ExitProcess, 0
    .else 
        invoke listen, sock, 5
    .endif

mov ebx,0
.while bl < nofp
	invoke accept, sock,NULL,NULL
	.continue .if eax == INVALID_SOCKET
	mov sockList[ebx * 4],eax
	invoke crt_printf, addr connect_comment, ebx
	invoke encode,ebx
	invoke send,sockList[ebx * 4],addr sbf,20,0
	inc ebx
.endw

mov ebx,0
.while bl < nofp
	invoke send,sockList[ebx * 4],addr nofp,20,0
	inc ebx
.endw


mov ebx,0
.while bl < nofp
	invoke CreateThread,NULL,NULL,OFFSET ThreadRecv,ebx,NULL,ADDR ThreadID
	inc ebx
.endw



mov ebx,0
mov bl,nofp
.while TRUE
	.IF (cntconn == ebx)
		invoke send_all,1	
		.BREAK
	.ENDIF
.endw


mov ebx,0
invoke GetRandomNumber,4
mov CT,eax
invoke send_all,CT


invoke GetRandomNumber,13
mov CN,eax
invoke send_all,CN
mov eax,CN
.if eax >= 10
	mov ScoreD[0 * 4],9
.else
	mov ScoreD[0 * 4],eax
.endif

invoke crt_printf,addr debug_comment,ScoreD[0 * 4]

invoke GetRandomNumber,4
mov CT,eax
invoke send_all,CT


invoke GetRandomNumber,13
mov CN,eax
invoke send_all,CN
mov eax,CN
.if eax >= 10
	mov ScoreD[1 * 4],9
.else
	mov ScoreD[1 * 4],eax
.endif


mov cnt,0
mov ebx,0
mov CountScore,0

.while	bl < nofp
	invoke GetRandomNumber,4
	mov CT,eax
	invoke send_all,CT


	invoke GetRandomNumber,13
	mov CN,eax
	mov ebx,CountScore
	.if eax >= 10
		mov ScoreP[ebx * 4],9
	.else
		mov ScoreP[ebx * 4],eax
	.endif
	invoke crt_printf,addr test_comment,ScoreP[ebx * 4],ebx
	invoke send_all,CN


	invoke GetRandomNumber,4
	mov CT,eax
	invoke send_all,CT
		
	inc CountScore
	invoke GetRandomNumber,13
	mov CN,eax
	mov ebx,CountScore
	.if eax >= 10
		mov ScoreP[ebx * 4],9
	.else
		mov ScoreP[ebx * 4],eax
	.endif
	invoke crt_printf,addr test_comment,ScoreP[ebx * 4],ebx
	invoke send_all,CN

	inc cnt
	inc CountScore
	mov bl,cnt
	;invoke crt_printf,addr DebugStr,bl
.endw

mov cntconn,0
mov ebx,0
.while bl < nofp
	invoke CreateThread,NULL,NULL,OFFSET ThreadRecvDraw,ebx,NULL,ADDR ThreadID
	inc ebx
.endw
mov ebx,0
mov bl,nofp
;Mark which player will draw cards
invoke crt_printf,addr DebugStr,nofp
.while TRUE
	.IF (cntconn == ebx)
		invoke send_all,1
		.BREAK
	.ENDIF
.endw

.if ifdrawU1 == 1
	inc cntyes
	mov ScoreT[0 * 4],1
.endif
invoke send_all,ifdrawU1

.if playernum > 1
	.if ifdrawU2 == 1
		inc cntyes
		mov ScoreT[1 * 4],1
	.endif
	invoke send_all,ifdrawU2
	

.endif
.if playernum > 2
	.if ifdrawU3 == 1
		inc cntyes
		mov ScoreT[2 * 4],1
	.endif
	invoke send_all,ifdrawU3

.endif
.if playernum > 3
	.if ifdrawU4 == 1
		inc cntyes
		mov ScoreT[3 * 4],1
	.endif
	invoke send_all,ifdrawU4

.endif
.if playernum > 4
	.if ifdrawU5 == 1
		inc cntyes
		mov ScoreT[4 * 4],1
	.endif
	invoke send_all,ifdrawU5

.endif


mov eax,ScoreD[0 * 4]
.if eax == 0
	add DTotalScore, 10
.elseif 
	add DTotalScore, eax
.endif

mov eax,ScoreD[1 * 4]
.if eax == 0 && DTotalScore != 10
	add DTotalScore, 10
.elseif 
	add DTotalScore, eax
.endif


invoke GetRandomNumber,4
mov CT,eax
invoke send_all,CT

.if DTotalScore < 14
	invoke GetRandomNumber,13
	mov CN,eax
	invoke send_all,CN
	mov eax,CN
	.if eax >= 10
		mov ScoreD[2 * 4],9
	.else
		mov ScoreD[2 * 4],eax
	.endif
	mov eax,ScoreD[2 * 4]
	add DTotalScore,eax
.elseif
	invoke send_all,20
	sub DTotalScore,1
.endif

mov ebx,0
mov cnt,0
mov CountScore,0
mov CountArray,0
.while ebx < cntyes
	invoke GetRandomNumber,4
	mov CT,eax
	invoke send_all,CT

	
	invoke GetRandomNumber,13
	mov CN,eax
	invoke send_all,CN
	
	mov ebx,CountArray
	.while ScoreT[ebx * 4] == -1
		invoke crt_printf,addr DebugStr,ebx
		inc ebx
	.endw
	mov CountArray,ebx
	inc CountArray

	mov eax,CN
	.if eax >= 10
		mov ScoreT[ebx * 4],9
	.else
		mov ScoreT[ebx * 4],eax
	.endif
	invoke crt_printf,addr test_comment,ScoreT[ebx * 4],ebx
	
	inc cnt
	mov bl,cnt
.endw

;==========
mov ebx,0
mov CountScore,0
mov CountArray,0
.while bl < nofp
	mov TempScore1,0
	mov TempScore2,0
	mov TempScore3,0
	mov TempScore4,0

;get all situations of score,and choose the biggest one
	mov ebx,CountArray
	mov eax,ScoreP[ebx * 4]
	mov ebx,CountScore
	add TotalScore[ebx * 4],eax
	add TempScore2,eax
	add TempScore3,eax
	.if eax == 0
		add TempScore1,10
		add TempScore4,10
	.elseif
		add TempScore1,eax
		add TempScore4,eax
	.endif

	inc ebx
	inc CountArray
	
	mov ebx,CountArray
	mov eax,ScoreP[ebx * 4]
	mov ebx,CountScore
	add TotalScore[ebx * 4],eax
	add TempScore1,eax
	add TempScore3,eax
	.if eax == 0
		add TempScore2,10
		add TempScore4,10
	.elseif 
		add TempScore2,eax
		add TempScore4,eax
	.endif
	
	mov ebx,CountScore
	mov eax,ScoreT[ebx * 4]
	.if eax == -1
		invoke crt_printf, ADDR warning
		sub TotalScore[ebx * 4],1
		sub TempScore3,1
		sub TempScore1,1
		sub TempScore2,1
		sub TempScore4,1
	.else
		add TotalScore[ebx * 4],eax
		add TempScore1,eax
		add TempScore2,eax
		add TempScore4,eax
	.endif
	.if eax == 0
		add TempScore3,10
	.elseif 
		add TempScore3,eax
	.endif
	
	
	mov eax,TotalScore[ebx * 4]
	.if ((TempScore1 > eax&&TempScore1 < 19))
		mov eax,TempScore1
		mov TotalScore[ebx * 4],eax
	.endif

	mov eax,TotalScore[ebx * 4]
	.if (TempScore2 > eax&&TempScore2 < 19)
		mov eax,TempScore2
		mov TotalScore[ebx * 4],eax
	.endif

	mov eax,TotalScore[ebx * 4]
	.if (TempScore3 > eax)&&(TempScore3 < 19)
		mov eax,TempScore3
		mov TotalScore[ebx * 4],eax
	.endif

	mov eax,TotalScore[ebx * 4]
	.if (TempScore4 > eax)&&(TempScore4 < 19)
		mov eax,TempScore4
		mov TotalScore[ebx * 4],eax
	.endif

	invoke crt_printf,addr test_comment,TotalScore[ebx * 4],ebx
	invoke crt_printf,addr test_comment,TempScore1,ebx
	invoke crt_printf,addr test_comment,TempScore2,ebx
	invoke crt_printf,addr test_comment,TempScore3,ebx
	invoke crt_printf,addr test_comment,TempScore4,ebx
	inc CountScore
	inc CountArray
	mov ebx,CountScore
.endw
invoke crt_printf,addr test_comment,DTotalScore,ebx
;========
mov ebx,0
.while bl < nofp
	mov eax,TotalScore[ebx]
	.if eax > 18
		invoke encode,3
		invoke send,sockList[ebx * 4],addr sbf,20,0
	.elseif 
		mov eax,TotalScore[ebx]
		.if DTotalScore > eax && DTotalScore < 19
			invoke encode,3
			invoke send,sockList[ebx * 4],addr sbf,20,0
		.elseif DTotalScore == eax
			invoke encode,2
			invoke send,sockList[ebx * 4],addr sbf,20,0
		.else
			invoke encode,1
			invoke send,sockList[ebx * 4],addr sbf,20,0
		.endif
	.endif
	inc ebx
.endw


.while TRUE
.endw

;==============================================

	; Get module handle and save it
	;invoke 	GetModuleHandle, NULL
	;mov 	hInstance, eax
	
	; Init Common Controls library
	;invoke	InitCommonControls
	
    ; Run winmain procedure and exit program
    ;invoke  WinMain, hInstance, NULL, NULL, SW_SHOWNORMAL
	invoke 	ExitProcess,eax



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

end start