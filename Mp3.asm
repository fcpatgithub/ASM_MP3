;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
DEBUG		=	0
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;	
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.386
		.model flat, stdcall
		option casemap :none   ; case sensitive

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

include		windows.inc
include		user32.inc
include		kernel32.inc
include		comctl32.inc
include		comdlg32.inc
include		winmm.inc
include     msgstruct.inc
;include     GraphWin.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

DLG_MAIN	equ		1000
ID_BROWSE	equ		1001
ID_FILE		equ		1002

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.data?

dwFlag		dd	?
;hWinMain	dd	?
;hInstance	dd	?
hDevice		dd	?
szBuffer	db	256 dup	(?)
stOpenFileName	OPENFILENAME	<?>

		.data

szCaption	db	"Error...",0
szError		db	"Error to play MP3 file!",0
szPlay		db	"&Play",0
szStop		db	"&Stop",0
szDevice	db	"MPEGVideo",0
szTitleSave	db	"Open MP3 file...",0
szExt		db	'*.mp3',0
szFilter	db	'MP3 Files(*.mp3)',0,'*.mp3',0,'All Files(*.*)',0,'*.*',0,0

AppLoadMsgTitle BYTE "Application Loaded",0
AppLoadMsgText  BYTE "This window displays when the WM_CREATE "
	            BYTE "message is received",0

PopupTitle BYTE "Popup Window",0
PopupText  BYTE "This window was activated by a "
	       BYTE "WM_LBUTTONDOWN message",0

PopupTitle2 BYTE "Welcome", 0
PopupText2  BYTE "This window was activated by a "
	       BYTE "WM_KEYDOWN message",0

GreetTitle BYTE "Main Window Active",0
GreetText  BYTE "This window is shown immediately after "
	       BYTE "CreateWindow and UpdateWindow are called.",0

CloseMsg   BYTE "Bye",0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>
hWinMain  DWORD ?
hInstance DWORD ?
;hMenu	DWORD ?

MyMenu BYTE "FirstMenu", 0
Test_string BYTE "You selected Test menu item",0 
Hello_string BYTE "Hello, my friend",0 
Goodbye_string BYTE "See you again, bye",0 

IDM_TEST equ 200                   ; Menu IDs 
IDM_HELLO equ 201
IDM_GOODBYE equ 202 
IDM_EXIT equ 203

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcDlgMain	PROTO	:DWORD,:DWORD,:DWORD,:DWORD

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

		.code

if		DEBUG
	include		Debug.asm
endif

;include		Win.asm

;********************************************************************
_GetFileName	proc

		mov	stOpenFileName.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
		mov	stOpenFileName.lStructSize,SIZEOF stOpenFileName
		mov	eax,hWinMain
		mov	stOpenFileName.hWndOwner,eax
		mov	stOpenFileName.lpstrFilter,offset szFilter	;
		mov	stOpenFileName.lpstrFile,offset szBuffer	;
		mov	stOpenFileName.nMaxFile,255			;
		mov	stOpenFileName.lpstrInitialDir,0
		mov	stOpenFileName.lpstrTitle,offset szTitleSave
		mov	stOpenFileName.lpstrDefExt,offset szExt
		invoke	GetOpenFileName,offset stOpenFileName
		.if	eax == FALSE
			ret
		.endif
		invoke	SetDlgItemText,hWinMain,ID_FILE,addr szBuffer
		;INVOKE MessageBox, hWinMain, ADDR Test_string, OFFSET WindowName, MB_OK 
		call	_StopPlayMP3

		ret

_GetFileName	endp
;********************************************************************
_PlayMP3	proc
		local	@stMCIOpen:MCI_OPEN_PARMS
		local	@stMCIPlay:MCI_PLAY_PARMS

		mov	@stMCIOpen.lpstrDeviceType,offset szDevice
		mov	@stMCIOpen.lpstrElementName,offset szBuffer
		invoke	mciSendCommand,0,MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,addr @stMCIOpen
		mov	eax,@stMCIOpen.wDeviceID
		mov	hDevice,eax
		mov	eax,hWinMain
		mov	@stMCIPlay.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
		.if	eax == 0
			invoke	SetDlgItemText,hWinMain,IDOK,offset szStop
			mov	dwFlag,1
		.else
			invoke	MessageBox,hWinMain,addr szError,addr szCaption,MB_OK
		.endif
		ret
        
_PlayMP3	endp
;********************************************************************
_StopPlayMP3	proc
		local	@stMCIStop:MCI_GENERIC_PARMS
		
		mov	eax,hWinMain
		mov	@stMCIStop.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_STOP,MCI_NOTIFY,addr @stMCIStop
		invoke	mciSendCommand,hDevice,MCI_CLOSE,MCI_NOTIFY,addr @stMCIStop
		invoke	SetDlgItemText,hWinMain,IDOK,offset szPlay
		mov	dwFlag,0
		ret

_StopPlayMP3	endp
;********************************************************************
_ProcDlgMain	proc	uses ebx edi esi, \
		hWnd:DWORD,wMsg:DWORD,wParam:DWORD,lParam:DWORD

		mov	eax,wMsg
		.if	eax == WM_CLOSE
			invoke	EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			mov	eax,hWnd
			mov	hWinMain,eax
;			invoke	_CenterWindow,eax
			invoke	SendDlgItemMessage,hWinMain,ID_FILE,EM_SETREADONLY,TRUE,NULL
		.elseif	eax == WM_COMMAND
			mov	eax,wParam
			.if	eax == ID_BROWSE
				call	_GetFileName
			.elseif eax == IDOK
				.if	dwFlag == 0
					call	_PlayMP3
				.else
					call	_StopPlayMP3
				.endif
			.endif
		.else
;********************************************************************
;	
;	
;********************************************************************
			mov	eax,FALSE
			ret
		.endif		   
		mov	eax,TRUE
		ret
		
_ProcDlgMain	endp
;********************************************************************
;-----------------------------------------------------
WinProc PROC,
	hWnd:DWORD, localMsg:DWORD, wParam:DWORD, lParam:DWORD
; The application's message handler, which handles
; application-specific messages. All other messages
; are forwarded to the default Windows message
; handler.
;-----------------------------------------------------
	mov eax, localMsg
	push ebx
	mov ebx, wParam
	.IF ebx == IDM_TEST
;		INVOKE MessageBox, hWnd, ADDR Test_string, OFFSET WindowName, MB_OK 
		.IF dwFlag == 0
			call _PlayMP3
		.ELSE
			call _StopPlayMP3
		.ENDIF
	.ELSEIF ebx == ID_BROWSE
;		INVOKE MessageBox, hWnd, ADDR Hello_string, OFFSET WindowName, MB_OK 
		call _GetFileName
	.ELSEIF ebx == IDM_GOODBYE
		INVOKE MessageBox, hWnd, ADDR Goodbye_string, OFFSET WindowName, MB_OK 
	.ENDIF
	pop ebx
	.IF eax == WM_LBUTTONDOWN		; mouse button?
;	  INVOKE MessageBox, hWnd, ADDR PopupText,
;	    ADDR PopupTitle, MB_OK 
	  jmp WinProcExit
	.ELSEIF eax == WM_KEYDOWN       ; keyboard button?
;		INVOKE MessageBox, hWnd, ADDR PopupText2,
;		ADDR PopupTitle2, MB_OK
		jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?
;	  INVOKE MessageBox, hWnd, ADDR AppLoadMsgText,
;	    ADDR AppLoadMsgTitle, MB_OK
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
;	  INVOKE MessageBox, hWnd, ADDR CloseMsg,
;	    ADDR WindowName, MB_OK
	  INVOKE PostQuitMessage,0
	  jmp WinProcExit
	.ELSE		; other message?
	  INVOKE DefWindowProc, hWnd, localMsg, wParam, lParam
	  jmp WinProcExit
	.ENDIF

WinProcExit:
	ret
WinProc ENDP
;********************************************************************
;---------------------------------------------------
ErrorHandler PROC
; Display the appropriate system error message.
;---------------------------------------------------
.data
pErrorMsg  DWORD ?		; ptr to error message
messageID  DWORD ?
.code
	INVOKE GetLastError	; Returns message ID in EAX
	mov messageID,eax

	; Get the corresponding message string.
	INVOKE FormatMessage, FORMAT_MESSAGE_ALLOCATE_BUFFER + \
	  FORMAT_MESSAGE_FROM_SYSTEM,NULL,messageID,NULL,
	  ADDR pErrorMsg,NULL,NULL

	; Display the error message.
	INVOKE MessageBox,NULL, pErrorMsg, ADDR ErrorTitle,
	  MB_ICONERROR+MB_OK

	; Free the error message string.
	INVOKE LocalFree, pErrorMsg
	ret
ErrorHandler ENDP
;********************************************************************
start:
		invoke	InitCommonControls
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax

; Load the program's icon and cursor.
		INVOKE LoadIcon, NULL, IDI_APPLICATION
		mov MainWin.hIcon, eax
		INVOKE LoadCursor, NULL, IDC_ARROW
		mov MainWin.hCursor, eax

; Menu
		mov MainWin.lpszMenuName, OFFSET MyMenu

; Register the window class.
		INVOKE RegisterClass, ADDR MainWin
		.IF eax == 0
		  call ErrorHandler
		  jmp Exit_Program
		.ENDIF

; Create the application's main window.
; Returns a handle to the main window in EAX.
		INVOKE CreateWindowEx, 0, ADDR className,
		  ADDR WindowName,WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME,
		  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
		  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
		mov hWinMain,eax

; If CreateWindowEx failed, display a message & exit.
		.IF eax == 0
		  call ErrorHandler
		  jmp  Exit_Program
		.ENDIF

; Show and draw the window.
		INVOKE ShowWindow, hWinMain, SW_SHOW
		INVOKE UpdateWindow, hWinMain

; Display a greeting message.
;		INVOKE MessageBox, hWinMain, ADDR GreetText,
;		  ADDR GreetTitle, MB_OK

; Begin the program's message-handling loop.
	Message_Loop:
		; Get next message from the queue.
		INVOKE GetMessage, ADDR msg, NULL,NULL,NULL

		; Quit if no more messages.
		.IF eax == 0
		  jmp Exit_Program
		.ENDIF

		; Relay the message to the program's WinProc.
		INVOKE DispatchMessage, ADDR msg
		jmp Message_Loop

	Exit_Program:
;		invoke	DialogBoxParam,hInstance,DLG_MAIN,NULL,offset _ProcDlgMain,0
		invoke	ExitProcess,NULL

		end	start