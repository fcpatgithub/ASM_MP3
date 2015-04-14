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
include		masm32rt.inc
include		Control.inc
include		Track.inc
include		Image.inc
include		MusicList.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

.data
extern dwFlag			: DWORD
extern Pos				: DWORD
extern volumePos		: DWORD
extern hPlayButton		: DWORD
extern hNextButton		: DWORD
extern hPreviousButton  : DWORD
extern hWinBar			: DWORD
extern hWinMain			: DWORD
extern htotalTime		: DWORD
extern hMusicName		: DWORD
extern hcurrentTime		: DWORD
extern hVolumeBar		: DWORD
extern hRect			: DWORD
extern hPlay			: DWORD
extern hPause			: DWORD
extern hNext			: DWORD
extern hPrevious		: DWORD
extern hMixer			: DWORD
extern szBuffer			: BYTE
extern volume			: MIXERCONTROLDETAILS_SIGNED
extern mxcd				: MIXERCONTROLDETAILS
extern mixer_id			: DWORD

ButtonClassName BYTE "button", 0
ButtonText		BYTE " ", 0
barName			BYTE "msctls_trackbar32",0
barclassName	BYTE "msctls_trackbar32",0
EditClass	BYTE "Static", 0
EmptyStr	BYTE " ", 0
ShowStr			BYTE 100 dup (?)


.code

;********************************************************************
CreatePlayButton PROC,
	hWnd: DWORD, hIns: DWORD

;	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
;		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
;		10, 10, 50, 50, hWnd, playBtn_ID, hIns, NULL
	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		windowWidth / 2 - 25, 50, 50, 50, hWnd, playBtn_ID, hIns, NULL
	mov hPlayButton, eax
	INVOKE SetImage, hPlayButton, hPlay	
	INVOKE CreateEllipticRgn, 0, 0, 50, 50
	INVOKE SetWindowRgn, hPlayButton, eax, TRUE
	ret

CreatePlayButton ENDP
;********************************************************************
CreateTrackBar PROC,
	hWnd: DWORD, hIns: DWORD

	INVOKE CreateWindowEx, NULL, ADDR barclassName,
		ADDR barName,WS_CHILD+WS_VISIBLE, windowWidth / 2 - 100, 20, 200, 20, hWnd,Bar_ID,hIns,NULL
	mov hWinBar, eax
	INVOKE SendMessage, hWinBar, TBM_SETPAGESIZE, 0, 1
	
	ret

CreateTrackBar ENDP
;********************************************************************
CreateVolumeBar PROC,
	hWnd: DWORD, hIns: DWORD
	LOCAL mxl:			MIXERLINE
	LOCAL mxc:			MIXERCONTROL
	LOCAL mxlc:			MIXERLINECONTROLS

	INVOKE CreateWindowEx, NULL, ADDR barclassName,
		ADDR barName,WS_CHILD+WS_VISIBLE, windowWidth / 2 - 50, 120, 100, 20, hWnd, Bar_ID, hIns, NULL
	mov hVolumeBar, eax
	INVOKE SendMessage, hVolumeBar, TBM_SETPAGESIZE, 0, 1
	
	INVOKE mixerOpen, ADDR hMixer, 0, hWinMain, NULL, MIXER_OBJECTF_MIXER or CALLBACK_WINDOW
	mov mxl.cbStruct, SIZEOF MIXERLINE
	mov mxl.dwComponentType, MIXERLINE_COMPONENTTYPE_DST_SPEAKERS
	INVOKE mixerGetLineInfo, hMixer, ADDR mxl, \
			MIXER_OBJECTF_HMIXER or MIXER_GETLINEINFOF_COMPONENTTYPE
	mov mxlc.cbStruct, SIZEOF MIXERLINECONTROLS
	mov eax, mxl.dwLineID
	mov mxlc.dwLineID, eax
	mov mxlc.dwControlType, MIXERCONTROL_CONTROLTYPE_VOLUME
	mov mxlc.cControls, 1
	mov mxlc.cbmxctrl, SIZEOF MIXERCONTROL
	lea eax, mxc
	mov mxlc.pamxctrl, eax
	INVOKE mixerGetLineControls, hMixer, ADDR mxlc, \
			MIXER_OBJECTF_HMIXER or MIXER_GETLINECONTROLSF_ONEBYTYPE
	mov eax, mxc.dwControlID
	mov mixer_id, eax
	mov mxcd.cbStruct, SIZEOF MIXERCONTROLDETAILS
	mov eax, mxc.dwControlID
	mov mxcd.dwControlID, eax
	mov mxcd.cChannels, 1
	mov mxcd.cMultipleItems, 0
	mov mxcd.cbDetails, SIZEOF MIXERCONTROLDETAILS_SIGNED
	lea eax, volume
	mov mxcd.paDetails, eax
	INVOKE mixerGetControlDetails, hMixer, ADDR mxcd, \
			MIXER_OBJECTF_HMIXER or MIXER_GETCONTROLDETAILSF_VALUE

	INVOKE SendMessage, hVolumeBar, TBM_SETPOS, 1, 100
	INVOKE VolumeAdjust, 100

	ret

CreateVolumeBar ENDP
;********************************************************************
SwitchTrackState PROC

	.IF dwFlag == 0 || dwFlag == 2
		INVOKE PlayMP3, OFFSET szBuffer
	.ELSE
		call _PausePlayMP3
	.ENDIF
	ret
SwitchTrackState ENDP
;********************************************************************
BarAdjust PROC
	push eax
	INVOKE SendMessage, hWinBar, TBM_GETPOS, 0, 0
	.IF (Pos != eax)
		mov Pos, eax
		call _SeekMP3
	.ENDIF
	pop eax
	ret
BarAdjust ENDP
;********************************************************************
VolumeBarAdjust PROC

	INVOKE SendMessage, hVolumeBar, TBM_GETPOS, 0, 0
	mov	volumePos, eax
	INVOKE VolumeAdjust, volumePos
	ret
VolumeBarAdjust ENDP
;********************************************************************
CreatePlaybackButton PROC,
	hWnd: DWORD, hIns: DWORD, mode: BYTE
	LOCAL btnX:				DWORD
	LOCAL btnID:			DWORD
	LOCAL btnHandle:		DWORD
	LOCAL imageHandle:		DWORD
	; mode = 0 -> previous
	; mode = 1 -> next

	.IF mode == 1
;		mov btnX, 400
		mov btnX, windowWidth / 2 + 50
		mov btnID, nextBtn_ID
		push ebx
		mov ebx, hNext
		mov imageHandle, ebx
		pop ebx
	.ELSEIF mode == 0
;		mov btnX, 300
		mov btnX, windowWidth / 2 - 85
		mov btnID, previousBtn_ID
		push ebx
		mov ebx, hPrevious
		mov imageHandle, ebx
		pop ebx
	.ENDIF
	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		btnX, 60, 30, 30, hWnd, btnID, hIns, NULL
	mov btnHandle, eax
	INVOKE SetImage, btnHandle, imageHandle
	INVOKE CreateEllipticRgn, 0, 0, 30, 30
	INVOKE SetWindowRgn, btnHandle, eax, TRUE
	.IF mode == 1
		push ebx
		mov ebx, btnHandle
		mov hNextButton, ebx
		pop ebx
	.ELSEIF mode == 0
		push ebx
		mov ebx, btnHandle
		mov hPreviousButton, ebx
		pop ebx
	.ENDIF
	ret
CreatePlaybackButton ENDP
;********************************************************************
PlaybackButtonClicked PROC,
	mode: BYTE
	; mode = 0 -> previous track
	; mode = 1 -> next track
	

	ret
PlaybackButtonClicked ENDP
;********************************************************************
CreateStatic PROC,
	hWnd: DWORD, hIns: DWORD

	invoke CreateWindowEx,NULL,ADDR EditClass,ADDR EditClass,
                   WS_VISIBLE or WS_CHILD,20,20,50,20,hWnd,STATIC1_ID,
                   hIns,NULL
	mov hcurrentTime, eax
	invoke SetWindowText, hcurrentTime, ADDR EmptyStr

	invoke CreateWindowEx,NULL,ADDR EditClass,ADDR EditClass,
                   WS_VISIBLE or WS_CHILD,290,20,50,20,hWnd,STATIC2_ID,
                   hIns,NULL
	mov htotalTime, eax
	invoke SetWindowText, htotalTime, ADDR EmptyStr

	invoke CreateWindowEx,NULL,ADDR EditClass,ADDR EditClass,
                   WS_VISIBLE or WS_CHILD or SS_CENTER,0,0,windowWidth,20,hWnd,STATIC3_ID,
                   hIns,NULL

	mov hMusicName, eax
	invoke SetWindowText, hMusicName, ADDR EmptyStr
	

	ret
CreateStatic ENDP

END