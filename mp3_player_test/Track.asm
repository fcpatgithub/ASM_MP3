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
include		Track.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

.data
extern dwFlag			: DWORD
extern hDevice			: DWORD
extern szBuffer			: BYTE
extern stOpenFileName	: OPENFILENAME
extern hWinMain			: DWORD
extern hWinBar			: DWORD
extern Pos				: DWORD

szCaption	BYTE	"Error...",0
szError		BYTE	"Error to play MP3 file!",0
szPlay		BYTE	"&Play",0
szStop		BYTE	"&Stop",0
szDevice	BYTE	"MPEGVideo",0
szTitleSave	BYTE	"Open MP3 file...",0
szExt		BYTE	'*.mp3',0
szFilter	BYTE	'MP3 Files(*.mp3)',0,'*.mp3',0,'All Files(*.*)',0,'*.*',0,0

.code

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
		call	_StopPlayMP3

		ret

_GetFileName	endp
;********************************************************************
_PlayMP3	proc
		
		local	@stMCIPlay:MCI_GENERIC_PARMS
		local	@stMCIOpen:MCI_OPEN_PARMS
		mov ebx, dwFlag
		.if ebx == 0
			mov	@stMCIOpen.lpstrDeviceType,offset szDevice
			mov	@stMCIOpen.lpstrElementName,offset szBuffer
			invoke	mciSendCommand,0,MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,addr @stMCIOpen
			mov	eax,@stMCIOpen.wDeviceID
			mov	hDevice,eax
			mov	eax,hWinMain
			mov	@stMCIPlay.dwCallback,eax
			invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
		.else

			invoke	mciSendCommand,hDevice,MCI_RESUME,MCI_NOTIFY,addr @stMCIPlay
		.endif
			
		.if	eax == 0
			invoke	SetDlgItemText,hWinMain,IDOK,offset szStop
			mov	dwFlag, 1
		.else
			invoke	MessageBox,hWinMain,addr szError,addr szCaption,MB_OK
		.endif
		ret
        
_PlayMP3	endp
;********************************************************************
_PausePlayMP3	proc
		local	@stMCIStop:MCI_GENERIC_PARMS
		
		mov	eax,hWinMain
		mov	@stMCIStop.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_PAUSE,MCI_NOTIFY,addr @stMCIStop
		invoke	SetDlgItemText,hWinMain,IDOK,offset szPlay
		mov	dwFlag, 2
		ret

_PausePlayMP3	endp
;********************************************************************
_StopPlayMP3	proc
		local	@stMCIStop:MCI_GENERIC_PARMS
		
		mov	eax,hWinMain
		mov	@stMCIStop.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_STOP,MCI_NOTIFY,addr @stMCIStop
		invoke	mciSendCommand,hDevice,MCI_CLOSE,MCI_NOTIFY,addr @stMCIStop
		invoke	SetDlgItemText,hWinMain,IDOK,offset szPlay
		mov	dwFlag, 0
		ret

_StopPlayMP3	endp
;********************************************************************
_SeekMP3	proc
		local	@stMCIStatus:MCI_STATUS_PARMS
		local	@stMCISeek:MCI_SEEK_PARMS
		local	@stMCIPlay:MCI_GENERIC_PARMS
		mov ebx, dwFlag
		.if (ebx == 1)
			mov eax, MCI_STATUS_LENGTH
			mov  @stMCIStatus.dwItem, eax
			mov	eax,hWinMain
			mov	@stMCIStatus.dwCallback,eax
			invoke	mciSendCommand,hDevice,MCI_STATUS,MCI_STATUS_ITEM,addr @stMCIStatus
			push ecx
			mov eax, @stMCIStatus.dwReturn
			imul Pos
			mov ecx, 100
			div ecx
			pop ecx
			mov @stMCISeek.dwTo, eax
			mov	eax,hWinMain
			mov	@stMCISeek.dwCallback,eax
			invoke	mciSendCommand,hDevice,MCI_SEEK,MCI_TO+MCI_WAIT,addr @stMCISeek
			invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
		.endif
		ret
        
_SeekMP3	endp
;********************************************************************
_AutochangePosition		proc
	local	@stMCIStatus:MCI_STATUS_PARMS
	;.WHILE (1)
		;.while (dwFlag != 1 )
		;.endw
		
		.if (dwFlag == 1 )

		push eax
		push ecx
		push edx

		mov eax, MCI_STATUS_LENGTH
		mov  @stMCIStatus.dwItem, eax
		mov	eax,hWinMain
		mov	@stMCIStatus.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_STATUS,MCI_STATUS_ITEM,addr @stMCIStatus
		mov ecx, @stMCIStatus.dwReturn
		push ecx
		mov eax, MCI_STATUS_POSITION
		mov  @stMCIStatus.dwItem, eax
		mov	eax,hWinMain
		mov	@stMCIStatus.dwCallback,eax
		invoke	mciSendCommand,hDevice,MCI_STATUS,MCI_STATUS_ITEM,addr @stMCIStatus
		mov eax, @stMCIStatus.dwReturn
		pop ecx
		mov edx, 0
		imul eax, 100
		div ecx

		INVOKE SendMessage, hWinBar, TBM_SETPOS, 1, eax
		mov Pos, eax

		pop edx
		pop ecx
		pop eax

		.endif
	;.ENDW
	ret
_AutochangePosition			endp
;********************************************************************
END