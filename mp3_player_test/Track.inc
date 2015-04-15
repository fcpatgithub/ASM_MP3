_GetFileName	PROTO
;_PlayMP3		PROTO
PlayMP3			PROTO, musicPath: PTR BYTE
VolumeAdjust	PROTO, vPos: DWORD
_PausePlayMP3	PROTO
_StopPlayMP3	PROTO
_SeekMP3		PROTO
_AutochangePosition	PROTO
GetListFileName PROTO

ID_BROWSE		equ		1001
ID_FILE			equ		1002
ID_OPEN_LIST	equ		1004
ID_NEW_LIST		equ		1005
MCI_OVER		equ     1234