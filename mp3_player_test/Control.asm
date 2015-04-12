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
extern hVolumeBar		: DWORD
extern hRect			: DWORD
extern hPlay			: DWORD
extern hPause			: DWORD
extern hNext			: DWORD
extern hPrevious		: DWORD
extern szBuffer			: BYTE

ButtonClassName BYTE "button", 0
ButtonText		BYTE " ", 0
barName			BYTE "msctls_trackbar32",0
barclassName	BYTE "msctls_trackbar32",0

.code

;********************************************************************
CreatePlayButton PROC,
	hWnd: DWORD, hIns: DWORD

	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		10, 10, 50, 50, hWnd, playBtn_ID, hIns, NULL
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
		ADDR barName,WS_CHILD+WS_VISIBLE,70,70,200,20, hWnd,Bar_ID,hIns,NULL
	mov hWinBar, eax
	INVOKE SendMessage, hWinBar, TBM_SETPAGESIZE, 0, 1
	
	ret

CreateTrackBar ENDP
;********************************************************************
CreateVolumeBar PROC,
	hWnd: DWORD, hIns: DWORD

	INVOKE CreateWindowEx, NULL, ADDR barclassName,
		ADDR barName,WS_CHILD+WS_VISIBLE,370,70,50,20, hWnd,Bar_ID,hIns,NULL
	mov hVolumeBar, eax
	INVOKE SendMessage, hVolumeBar, TBM_SETPAGESIZE, 0, 2
	
	ret

CreateVolumeBar ENDP
;********************************************************************

SwitchTrackState PROC
	INVOKE SendMessage, hPlayButton, BM_GETIMAGE, IMAGE_BITMAP, NULL
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
<<<<<<< HEAD
=======
volumeBarAdjust PROC
	push eax
	INVOKE SendMessage, hVolumeBar, TBM_GETPOS, 0, 0
	.IF (volumePos != eax)
		mov volumePos, eax
		;call _SeekMP3
	.ENDIF
	pop eax
	ret
volumeBarAdjust ENDP
;********************************************************************
; not avaliable for now
; logical coordinate <--> screen coordinate?
>>>>>>> origin/dev
CreatePlaybackButton PROC,
	hWnd: DWORD, hIns: DWORD, mode: BYTE
	LOCAL btnX:				DWORD
	LOCAL btnID:			DWORD
	LOCAL btnHandle:		DWORD
	LOCAL imageHandle:		DWORD
	; mode = 0 -> previous
	; mode = 1 -> next

	.IF mode == 1
		mov btnX, 400
		mov btnID, nextBtn_ID
		push ebx
		mov ebx, hNext
		mov imageHandle, ebx
		pop ebx
	.ELSEIF mode == 0
		mov btnX, 300
		mov btnID, previousBtn_ID
		push ebx
		mov ebx, hPrevious
		mov imageHandle, ebx
		pop ebx
	.ENDIF
	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		btnX, 10, 50, 50, hWnd, btnID, hIns, NULL
	mov btnHandle, eax
	INVOKE SetImage, btnHandle, imageHandle
	INVOKE CreateEllipticRgn, 0, 0, 50, 50
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


END