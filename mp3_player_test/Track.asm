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
include		Image.inc
include		MusicList.inc

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
extern hPlayButton		: DWORD
extern hPlay			: DWORD
extern hPause			: DWORD
extern Pos				: DWORD
extern volume			: DWORD
extern totalTime		: DWORD
extern currentTime		: DWORD
extern htotalTime		: DWORD
extern hcurrentTime		: DWORD
extern volumePos		: DWORD
extern isDraging		: BYTE
extern workPath			: DWORD
extern mxcd				: MIXERCONTROLDETAILS
extern hMixer			: DWORD
extrn  ListName			: DWORD
extrn hMusicName		: DWORD
extrn hList				: DWORD
extrn currentMusicItem	: DWORD
extrn htotalTime		: DWORD
extrn hcurrentTime		: DWORD

szCaption	BYTE	"Error...",0
szError		BYTE	"Error to play MP3 file!",0
szPlay		BYTE	"&Play",0
szStop		BYTE	"&Stop",0
szDevice	BYTE	"MPEGVideo",0
szTitleSave	BYTE	"Open MP3 file...",0
szExt		BYTE	'*.mp3',0
szFilter	BYTE	'MP3 Files(*.mp3)',0,'*.mp3',0,'All Files(*.*)',0,'*.*',0,0
filterList	BYTE	'LIST Files(*.list)',0,'*.list',0,0
str_time    BYTE    256 dup(?)
ShowStr     BYTE    100 dup (?)
overFlag	BYTE    0
.code

;********************************************************************

GetListFileName proc

		mov	stOpenFileName.Flags,OFN_PATHMUSTEXIST or OFN_FILEMUSTEXIST
		mov	stOpenFileName.lStructSize,SIZEOF stOpenFileName
		mov	eax,hWinMain
		mov	stOpenFileName.hWndOwner,eax
		mov	stOpenFileName.lpstrFilter,offset filterList	;
		mov	stOpenFileName.lpstrFile,offset ListName	;
		mov	stOpenFileName.nMaxFile,255			;
		mov	stOpenFileName.lpstrInitialDir,0
		mov	stOpenFileName.lpstrTitle,offset szTitleSave
		;mov	stOpenFileName.lpstrDefExt,offset szExt
		invoke	GetOpenFileName,offset stOpenFileName
		invoke	SetCurrentDirectory, ADDR workPath
		.if	eax == FALSE
			ret
		.endif
		INVOKE SetImage, hPlayButton, hPlay
		INVOKE SendMessage, hWinBar, TBM_SETPOS, 1, 0
		INVOKE WriteListName
		call	_StopPlayMP3
		ret
GetListFileName ENDP


getTimeString PROC, time: DWORD
	local sec :WORD
	local min :WORD

	push eax
	push esi
	push ecx
	push edx

	lea esi, str_time
	mov edx, 0
	mov ecx, 1000
	div ecx
	mov edx, 0
	mov cx, 60
	div cx
	mov min, ax
	mov sec, dx

	mov ax, min
	mov cl, 10
	div cl
	add al, 48
	add ah, 48
	mov [esi], al
	mov [esi+1], ah

	mov al, ':'
	mov [esi+2], al

	mov ax, sec
	mov cl, 10
	div cl
	add al, 48
	add ah, 48
	mov [esi+3], al
	mov [esi+4], ah

	pop edx
	pop ecx
	pop edx
	pop eax
	ret
getTimeString ENDP

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
		invoke	SetCurrentDirectory, ADDR workPath
		.if	eax == FALSE
			ret
		.endif
		INVOKE SetImage, hPlayButton, hPlay
		INVOKE SendMessage, hWinBar, TBM_SETPOS, 1, 0

		;invoke	SetDlgItemText,hWinMain,ID_FILE,addr szBuffer
		call	_StopPlayMP3
		invoke InsertItem, addr szBuffer
		ret

_GetFileName	endp

;********************************************************************
_GetTotalTime	proc 
	local	@stMCIStatus:MCI_STATUS_PARMS
	mov eax, MCI_STATUS_LENGTH
	mov  @stMCIStatus.dwItem, eax
	mov	eax,hWinMain
	mov	@stMCIStatus.dwCallback,eax
	invoke	mciSendCommand,hDevice,MCI_STATUS,MCI_STATUS_ITEM,addr @stMCIStatus
	mov eax, @stMCIStatus.dwReturn
	mov totalTime, eax
	ret
_GetTotalTime	endp

;********************************************************************


;_PlayMP3	proc 
;		
;		local	@stMCIPlay:MCI_GENERIC_PARMS
;		local	@stMCIOpen:MCI_OPEN_PARMS
;		mov ebx, dwFlag
;		.if ebx == 0
;			mov	@stMCIOpen.lpstrDeviceType,offset szDevice
;			mov	@stMCIOpen.lpstrElementName,offset szBuffer
;			invoke	mciSendCommand,0,MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,addr @stMCIOpen
;			mov	eax,@stMCIOpen.wDeviceID
;			mov	hDevice,eax
;			mov	eax,hWinMain
;			mov	@stMCIPlay.dwCallback,eax
;			invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
;		.else
;
;			invoke	mciSendCommand,hDevice,MCI_RESUME,MCI_NOTIFY,addr @stMCIPlay
;		.endif
;			
;		.if	eax == 0
;			invoke	SetDlgItemText,hWinMain,IDOK,offset szStop
;			mov	dwFlag, 1
;		.else
;			invoke	MessageBox,hWinMain,addr szError,addr szCaption,MB_OK
;		.endif
;		ret
;      
;_PlayMP3	endp

;********************************************************************
PlayMP3	proc musicPath : ptr BYTE
		LOCAL lvi:LV_ITEM
		local	@stMCIPlay:MCI_GENERIC_PARMS
		local	@stMCIOpen:MCI_OPEN_PARMS

		mov ebx, dwFlag
		.if ebx == 0
			mov	@stMCIOpen.lpstrDeviceType, offset szDevice
			mov eax, musicPath
			mov	@stMCIOpen.lpstrElementName, eax
			invoke	mciSendCommand,0,MCI_OPEN,MCI_OPEN_TYPE or MCI_OPEN_ELEMENT,addr @stMCIOpen
			mov	eax,@stMCIOpen.wDeviceID
			mov	hDevice,eax
			mov	eax,hWinMain
			mov	@stMCIPlay.dwCallback,eax

			invoke _GetTotalTime
			invoke getTimeString, totalTime
			invoke SetWindowText, htotalTime, ADDR str_time

			invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
		.else

			invoke	mciSendCommand,hDevice,MCI_RESUME,MCI_NOTIFY,addr @stMCIPlay
		.endif
			
		.if	eax == 0
			INVOKE SetImage, hPlayButton, hPause
			invoke	SetDlgItemText,hWinMain,IDOK,offset szStop
			INVOKE szCopy, musicPath  , OFFSET szBuffer
			invoke GetMusicNameFromPath, OFFSET szBuffer, OFFSET ShowStr
			invoke SetWindowText, hMusicName, ADDR ShowStr
			
			mov lvi.stateMask, LVIS_SELECTED+LVIS_FOCUSED
			mov lvi.state,  0
			Invoke SendMessage, hList, LVM_SETITEMSTATE,-1,ADDR lvi
			mov lvi.stateMask, LVIS_SELECTED+LVIS_FOCUSED
			mov lvi.state,  LVIS_SELECTED+LVIS_FOCUSED
			Invoke SendMessage, hList, LVM_SETITEMSTATE,currentMusicItem,ADDR lvi
			mov	dwFlag, 1
		.else
			invoke	MessageBox,hWinMain,addr szError,addr szCaption,MB_OK
			INVOKE GetLastError
		.endif
		ret
        
PlayMP3	endp
;********************************************************************
_PausePlayMP3	proc
		local	@stMCIStop:MCI_GENERIC_PARMS
		
		INVOKE SetImage, hPlayButton, hPlay
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

		szText EmptyStr," "
		invoke SetWindowText, htotalTime, ADDR EmptyStr
		invoke SetWindowText, hcurrentTime, ADDR EmptyStr
		ret

_StopPlayMP3	endp
;********************************************************************
_SeekMP3	proc
		local	@stMCIStatus:MCI_STATUS_PARMS
		local	@stMCISeek:MCI_SEEK_PARMS
		local	@stMCIPlay:MCI_GENERIC_PARMS
		mov ebx, dwFlag
		.if (ebx == 2)
			invoke	mciSendCommand,hDevice,MCI_RESUME,MCI_NOTIFY,addr @stMCIPlay
		.endif
		.if (ebx == 1 || ebx == 2)
			mov eax, MCI_STATUS_LENGTH
			mov  @stMCIStatus.dwItem, eax
			mov	eax,hWinMain
			mov	@stMCIStatus.dwCallback,eax
			invoke	mciSendCommand,hDevice,MCI_STATUS,MCI_STATUS_ITEM+MCI_NOTIFY,addr @stMCIStatus
			push ecx
			mov eax, @stMCIStatus.dwReturn
			imul Pos
			mov ecx, 100
			div ecx
			pop ecx
			mov @stMCISeek.dwTo, eax
			mov	eax,hWinMain
			mov	@stMCISeek.dwCallback,eax
			invoke	mciSendCommand,hDevice,MCI_SEEK,MCI_TO+MCI_WAIT+MCI_NOTIFY,addr @stMCISeek
			invoke	mciSendCommand,hDevice,MCI_PLAY,MCI_NOTIFY,addr @stMCIPlay
		.endif
			
		.if (ebx == 2)
			invoke	mciSendCommand,hDevice,MCI_PAUSE,MCI_NOTIFY,addr @stMCIPlay
		.endif
		ret
        
_SeekMP3	endp
;********************************************************************
_AutochangePosition		proc
	local	@stMCIStatus:MCI_STATUS_PARMS
	;.WHILE (1)
		;.while (dwFlag != 1 )
		;.endw
		
		.if (dwFlag == 1 && isDraging == 0)

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

		push eax
		mov currentTime, eax
		invoke getTimeString, currentTime
		invoke SetWindowText, hcurrentTime, ADDR str_time
		pop eax

		pop ecx

		.IF ecx == eax
			.IF overFlag == 0
				push ecx
				push eax
				INVOKE SendMessage, hWinMain, MCI_OVER , 1, eax
				inc overFlag
				pop eax
				pop ecx
			.ENDIF
		.ELSE
			mov overFlag, 0
		.ENDIF

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
VolumeAdjust PROC vPos: DWORD
	mov eax, vPos
	mov ecx, 65535
	mul ecx
	mov ecx, 100
	div ecx
	mov volume, eax
	INVOKE mixerSetControlDetails, hMixer, ADDR mxcd, \
			MIXER_OBJECTF_HMIXER or MIXER_SETCONTROLDETAILSF_VALUE
	ret
VolumeAdjust ENDP
;********************************************************************
END