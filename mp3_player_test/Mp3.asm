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
include		Image.inc
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
public hPlayButton
public hNextButton
public hPreviousButton
public hWinBar
public hVolumeBar
public volumePos
public hRect
public hPlay
public hPause
public hNext
public hPrevious
public hList
public hMixer
public volume
public mxcd
public mixer_id
public currentMusicItem
public totalTime
public currentTime
public htotalTime
public hcurrentTime
public hMusicName


dwFlag				DWORD	?
hDevice				DWORD	?
szBuffer			BYTE	256 dup	(?)
stOpenFileName		OPENFILENAME	<?>
Pos					DWORD ?
volumePos			DWORD ?
hWinMain			DWORD ?
hInstance			DWORD ?
hMusicName          DWORD ?
totalTime			DWORD 0
currentTime			DWORD 0
htotalTime			DWORD ?
hcurrentTime		DWORD ?
hPlayButton			DWORD ?
hNextButton			DWORD ?
hPreviousButton		DWORD ?
hWinBar				DWORD ?
hVolumeBar			DWORD ?
hRect				DWORD ?
hPlay				DWORD ?
hPause				DWORD ?
hNext				DWORD ?
hPrevious			DWORD ?
hList				dd  ?
hMixer				DWORD ?
volume				MIXERCONTROLDETAILS_SIGNED <?>
mxcd				MIXERCONTROLDETAILS <?>
mixer_id			DWORD ?
currentMusicItem	DWORD ?
xCtr				DWORD ?
yCtr				DWORD ?

.data

DebugText	BYTE "Debug", 0

ErrorTitle  BYTE "Error",0
WindowName  BYTE "MP3 Player",0
className   BYTE "ASMWin",0
config		BYTE "config",0

workPath	BYTE 1000 dup (?)

; Define the Application's Window class structure.
MainWin WNDCLASS <NULL,WinProc,NULL,NULL,NULL,NULL,NULL, \
	COLOR_WINDOW,NULL,className>

msg	      MSGStruct <>
winRect   RECT <>

MyMenu BYTE "FirstMenu", 0

public config
public workPath
public template
public musicList
public musicListLen
public isDraging

ListViewClassName	db "SysListView32",0
template db "%lu",0
musicList musicInfo MAX_LIST_LEN dup(<>)
musicListLen DWORD 0
isDraging byte 0
extrn ListName :BYTE

.const
IDM_EXIT		EQU 203
windowWidth		EQU 360
windowHeight	EQU 650

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
comment*
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
				;call	_GetFileName
			.elseif eax == IDOK
				.if	dwFlag == 0
					INVOKE	PlayMP3, OFFSET szBuffer
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
*
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
		.ELSEIF ebx == ID_OPEN_LIST
			call GetListFileName
		.ELSEIF bx == playBtn_ID
			INVOKE SwitchTrackState
		.ELSEIF bx == nextBtn_ID
			INVOKE PlaybackButtonClicked, 1
			INVOKE NextMusic
;			INVOKE MessageBox, hWnd, ADDR DebugText, ADDR DebugText, MB_OK
		.ELSEIF bx == previousBtn_ID
			INVOKE PlaybackButtonClicked, 0
			INVOKE PreviousMusic
;			INVOKE MessageBox, hWnd, ADDR DebugText, ADDR DebugText, MB_OK
		.ENDIF
;	.ENDIF
	;pop ebx
	.IF eax == WM_HSCROLL
		push edx
		mov edx, lParam
		.IF (edx == hWinBar)
			.IF ebx == SB_ENDSCROLL
				INVOKE BarAdjust
				mov isDraging, 0
			.ELSE
				mov isDraging, 1
			.ENDIF
		.ELSEIF (edx == hVolumeBar)
;			.IF ebx == SB_ENDSCROLL
				INVOKE VolumeBarAdjust
;			.ENDIF
		.ENDIF
		pop edx
		jmp WinProcExit
	.ELSEIF eax == WM_LBUTTONDOWN		; mouse button?
	  jmp WinProcExit
	.ELSEIF eax == WM_KEYDOWN       ; keyboard button?
		jmp WinProcExit
	.ELSEIF eax == WM_CREATE		; create window?
		INVOKE CreateListWin, hWnd, hInstance					; Playlist
		INVOKE CreateTrackBar, hWnd, hInstance					; Time bar
		INVOKE CreateVolumeBar, hWnd, hInstance					; Volume bar
		INVOKE CreatePlayButton, hWnd, hInstance				; Play / pause button
		INVOKE CreatePlaybackButton, hWnd, hInstance, 1			; Next track
		INVOKE CreatePlaybackButton, hWnd, hInstance, 0			; Previous track
		INVOKE CreateStatic, hWnd, hInstance					; Static
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
	Invoke GetCurrentDirectory, 1000, ADDR workPath
	mov	hInstance,0
		invoke	InitCommonControls
		mov eax, eax
		invoke	GetModuleHandle,NULL
		mov	hInstance,eax
	
	invoke GetListName
	
	

; Load Bitmap
;		INVOKE LoadImage, hInstance, IDB_PAUSE, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
;		mov hPause, eax
		INVOKE LoadImages, hInstance

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
;		INVOKE CreateWindowEx, 0, ADDR className,
;		  ADDR WindowName,WS_VISIBLE+WS_DLGFRAME+WS_CAPTION+WS_BORDER+WS_SYSMENU+WS_MAXIMIZEBOX+WS_MINIMIZEBOX+WS_THICKFRAME,
;		  CW_USEDEFAULT,CW_USEDEFAULT,CW_USEDEFAULT,
;		  CW_USEDEFAULT,NULL,NULL,hInstance,NULL
		INVOKE GetSystemMetrics, SM_CXSCREEN
		mov ebx, 2
		xor edx, edx
		div ebx
		sub eax, windowWidth / 2
		mov xCtr, eax
		INVOKE GetSystemMetrics, SM_CYSCREEN
		mov ebx, 2
		xor edx, edx
		div ebx
		sub eax, windowHeight / 2
		mov yCtr, eax
		INVOKE CreateWindowEx, 0, ADDR className,
		  ADDR WindowName,WS_CAPTION+WS_SYSMENU+WS_MINIMIZEBOX+WS_THICKFRAME,
		  xCtr, yCtr, windowWidth, windowHeight, NULL, NULL ,hInstance, NULL
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