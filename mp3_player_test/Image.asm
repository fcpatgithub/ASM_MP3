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
include		Image.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

.data
extern hPlay		: DWORD
extern hPause		: DWORD
extern hNext		: DWORD
extern hPrevious		: DWORD

.code

;********************************************************************
LoadImages PROC,
	hIns: DWORD

	INVOKE LoadImage, hIns, IDB_PLAY, IMAGE_BITMAP, 45, 45, LR_DEFAULTCOLOR
	mov hPlay, eax
	INVOKE LoadImage, hIns, IDB_PAUSE, IMAGE_BITMAP, 45, 45, LR_DEFAULTCOLOR
	mov hPause, eax
	INVOKE LoadImage, hIns, IDB_NEXT, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
	mov hNext, eax
	INVOKE LoadImage, hIns, IDB_PREVIOUS, IMAGE_BITMAP, 50, 50, LR_DEFAULTCOLOR
	mov hPrevious, eax
	ret
LoadImages ENDP
;********************************************************************
SetImage PROC,
	hButton: DWORD, hImage: DWORD

	INVOKE SendMessage, hButton, BM_SETIMAGE, IMAGE_BITMAP, hImage
	ret
SetImage ENDP
;********************************************************************

END