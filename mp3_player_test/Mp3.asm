.386
.model flat, stdcall
option casemap :none   ; case sensitive

include		windows.inc
include		user32.inc
include		kernel32.inc
include		comctl32.inc
include		comdlg32.inc
include		winmm.inc
include     msgstruct.inc
include     Gdi32.inc
include		masm32rt.inc



includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib
includelib  Gdi32.lib

;include		PlayMusic.inc
include		MusicList.inc
include		Track.inc
include		Control.inc

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

DLG_MAIN	equ		1000

;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.data?
public dwFlag
public hDevice
public szBuffer
public stOpenFileName
public Pos
public hWinMain
public hInstance
public hButton
public hWinBar
public hRect
public hPlay
public hPause
public hList

dwFlag			DWORD	?
hDevice			DWORD	?
szBuffer		BYTE	256 dup	(?)
stOpenFileName	OPENFILENAME	<?>
Pos				DWORD	?
hWinMain  DWORD ?
hInstance DWORD ?
hButton DWORD ?
hWinBar DWORD ?
hRect DWORD ?
hPlay DWORD ?
hPause DWORD ?
hList  dd  ?


.data

ErrorTitle  BYTE "Error",0
WindowName  BYTE "ASM Windows App",0
className   BYTE "ASMWin",0

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>

MyMenu BYTE "FirstMenu", 0

public template
public musicList
public musicListLen
public isDraging

ListViewClassName	db "SysListView32",0
template db "%lu",0
musicList musicInfo MAX_LIST_LEN dup(<>)
musicListLen DWORD 0
isDraging byte 0

.const
IDM_EXIT equ 203
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
_ProcDlgMain	PROTO	:DWORD,:DWORD,:DWORD,:DWORD
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
;	
;>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>

.code
;********************************************************************

;********************************************************************
_ProcDlgMain	proc	uses ebx edi esi, \
		hWnd:DWORD,wMsg:DWORD,wParam:DWORD,lParam:DWORD

		mov	eax,wMsg
		.if	eax == WM_CLOSE
			invoke	EndDialog,hWnd,NULL
		.elseif	eax == WM_INITDIALOG
			mov	eax,hWnd
			mov	hWinMain,eax
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
	INVOKE SetTimer, hWinBar,1,100, ADDR _AutochangePosition
	mov eax, localMsg
	;push ebx
	mov ebx, wParam
;	.IF eax == WM_COMMAND
		.IF ebx == ID_BROWSE
			call _GetFileName
		.ELSEIF bx == playBtn_ID
			INVOKE SwitchTrackState
		.ENDIF
;	.ENDIF
	;pop ebx
	.IF eax == WM_HSCROLL
		.IF ebx == SB_ENDSCROLL
			INVOKE BarAdjust
			mov isDraging, 0
		.ELSE
			mov isDraging, 1
		.ENDIF

		jmp WinProcExit
	.ELSEIF eax == WM_LBUTTONDOWN		; mouse button?
	  jmp WinProcExit
	.ELSEIF eax == WM_KEYDOWN       ; keyboard button?
		jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?
		INVOKE CreateListWin, hWnd, hInstance	
		INVOKE CreateTrackBar, hWnd, hInstance
		INVOKE CreatePlayButton, hWnd, hInstance	
	  jmp WinProcExit
	.ELSEIF eax == WM_CLOSE		; close window?
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
	mov	hInstance,0
		invoke	InitCommonControls
		mov eax, eax
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax

; Load Bitmap
		INVOKE LoadImage, hInstance, IDB_PAUSE, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
		mov hPause, eax

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