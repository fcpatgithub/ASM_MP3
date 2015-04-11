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

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

.data
extern dwFlag			: DWORD
extern Pos				: DWORD
extern hPlayButton		: DWORD
extern hNextButton		: DWORD
extern hWinBar			: DWORD
extern hSoundBar		: DWORD
extern hRect			: DWORD
extern hPlay			: DWORD
extern hPause			: DWORD
extern hNext			: DWORD
extern hPrevious		: DWORD

ButtonClassName BYTE "button", 0
ButtonText BYTE " ", 0
barName  BYTE "msctls_trackbar32",0
barclassName   BYTE "msctls_trackbar32",0
.code

;********************************************************************
CreatePlayButton PROC,
	hWnd: DWORD, hIns: DWORD

	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		10, 10, 50, 50, hWnd, playBtn_ID, hIns, NULL
	mov hPlayButton, eax
	INVOKE LoadImage, hIns, IDB_PLAY, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
	mov hPlay, eax
	INVOKE SendMessage, hPlayButton, BM_SETIMAGE, IMAGE_BITMAP, eax	
	INVOKE CreateEllipticRgn, 0, 0, 50, 50							
	mov hRect, eax
	INVOKE SetWindowRgn, hPlayButton, hRect, TRUE
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
CreateSoundBar PROC,
	hWnd: DWORD, hIns: DWORD

	INVOKE CreateWindowEx, NULL, ADDR barclassName,
		ADDR barName,WS_CHILD+WS_VISIBLE,370,70,50,20, hWnd,Bar_ID,hIns,NULL
	mov hSoundBar, eax
	INVOKE SendMessage, hSoundBar, TBM_SETPAGESIZE, 0, 1
	
	ret

CreateSoundBar ENDP
;********************************************************************

SwitchTrackState PROC
	INVOKE SendMessage, hPlayButton, BM_GETIMAGE, IMAGE_BITMAP, NULL
	.IF dwFlag == 0 || dwFlag == 2
		INVOKE SendMessage, hPlayButton, BM_SETIMAGE, IMAGE_BITMAP, hPause
		call _PlayMP3
	.ELSE
		INVOKE SendMessage, hPlayButton, BM_SETIMAGE, IMAGE_BITMAP, hPlay
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
; not avaliable for now
; logical coordinate <--> screen coordinate?
CreatePlaybackButton PROC,
	hWnd: DWORD, hIns: DWORD, mode: BYTE
	; mode = 0 -> previous
	; mode = 1 -> next

	INVOKE CreateWindowEx, NULL, ADDR ButtonClassName,
		ADDR ButtonText, WS_CHILD or WS_VISIBLE or WS_CLIPCHILDREN or BS_BITMAP,
		400, 10, 50, 50, hWnd, nextBtn_ID, hIns, NULL
	mov hNextButton, eax
;	INVOKE LoadImage, hIns, IDB_PLAY, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
;	mov hPlay, eax
	INVOKE SendMessage, hNextButton, BM_SETIMAGE, IMAGE_BITMAP, hPause
	INVOKE CreateEllipticRgn, 350, 10, 400, 30
;	mov hRect, eax		
;	INVOKE SetWindowRgn, hNextButton, hRect, TRUE
	ret
CreatePlaybackButton ENDP
;********************************************************************
END