GetMusicNameFromPath	PROTO, math: DWORD
InsertColumn			PROTO
ShowFileInfo			PROTO, row:DWORD, lpFind:DWORD
FillFileInfo			PROTO

WriteListFile			PROTO
GetList					PROTO
CreateListWin			PROTO, hWnd: DWORD, hInstance: DWORD

PATH_LEN		equ 256
NAME_LEN		equ 64
INFO_LEN		equ PATH_LEN+NAME_LEN+4
MAX_LIST_LEN	equ 100

musicInfo STRUCT
	path BYTE PATH_LEN dup(0)
	name BYTE NAME_LEN dup(0)
	time DWORD 0
musicInfo ENDS
RGB macro red,green,blue
        xor eax,eax
        mov ah,blue
        shl eax,8
        mov ah,green
        mov al,red
endm
IDM_LIST equ  LVS_LIST
;IDM_ICON equ LVS_ICON
;IDM_REPORT equ LVS_REPORT
;hMenu dd ?