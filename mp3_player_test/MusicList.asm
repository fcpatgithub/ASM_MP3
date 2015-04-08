
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
include		MusicList.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib


.data

ListViewClassName	db "SysListView32",0
Heading1			db "Filename",0
Heading2			db "Size",0
ListName			db "list.txt",0
ListName2			db "list2.txt",0

extrn hList			: DWORD
extrn template		: WORD
extrn musicList		: musicInfo
extrn musicListLen	: DWORD

.code

WriteListFile proc
	LOCAL fname :DWORD
	LOCAL hFile :DWORD

	mov		fname, OFFSET ListName2
	.IF rv(exist, fname) != 0            
      test fdelete(fname), eax   
    .ENDIF
    mov		hFile, fcreate(fname)

	mov		esi, OFFSET musicList
	add		esi, PATH_LEN
	mov		ecx, musicListLen
	.IF		ecx == 0 
	  jmp	E
	.ENDIF
L1:
	push	ecx
	fprint	hFile,esi
	add		esi, INFO_LEN
	pop		ecx
	Loop	L1
	
E:
	fclose	hFile
	ret

WriteListFile endp



GetList PROC
	LOCAL bufAddr :DWORD
	LOCAL bufSize :DWORD
	mov	musicListLen, 0
	.IF rv(exist, ADDR ListName) == 0
		ret
	.ENDIF
	
	invoke	read_disk_file, OFFSET ListName, ADDR bufAddr, ADDR bufSize
	mov esi, OFFSET musicList
	mov eax, 0
L1:
	invoke	readline, bufAddr, esi, eax 
	.IF ecx >0
		inc	musicListLen
		invoke	GetMusicNameFromPath, esi 
	.ENDIF
	.IF eax > 0  
		add	esi, INFO_LEN
		jmp L1
	.ENDIF
	
	invoke WriteListFile
	ret
GetList ENDP

GetMusicNameFromPath PROC uses eax esi edi ebx, Mpath:DWORD
	LOCAL Mname:DWORD
	mov eax, Mpath
	add eax, PATH_LEN
	mov Mname, eax
	mov esi, Mpath
	mov bl, BYTE ptr[esi]
	.IF bl == 0
		ret
	.ENDIF
L1:
	.IF bl == '\'
		mov edi, esi
	.ENDIF
	inc esi
	mov bl, BYTE ptr [esi]
	.IF bl > 0
		jmp L1
	.ENDIF

	inc edi
	mov esi, Mname
L2:
	mov bl, BYTE ptr [edi]
	.IF bl != '.'
		mov al, BYTE ptr [edi]
		mov [esi], al
		inc edi
		inc esi
		jmp L2
	.ENDIF
	mov al, 0
	mov [esi], al
	ret
GetMusicNameFromPath ENDP






InsertColumn proc
	LOCAL lvc:LV_COLUMN
	mov lvc.imask,LVCF_TEXT+LVCF_WIDTH
	mov lvc.pszText,offset Heading1
	mov lvc.lx,150
	invoke SendMessage,hList, LVM_INSERTCOLUMN,0,addr lvc
	or lvc.imask,LVCF_FMT
	mov lvc.fmt,LVCFMT_RIGHT
	mov lvc.pszText,offset Heading2
	mov lvc.lx,100
	invoke SendMessage,hList, LVM_INSERTCOLUMN, 1 ,addr lvc	
	ret		
InsertColumn endp



ShowFileInfo proc uses edi row:DWORD, lpFind:DWORD
	LOCAL lvi:LV_ITEM
	LOCAL buffer[100]:BYTE
	
	mov edi,lpFind
	assume edi:ptr WIN32_FIND_DATA
	mov lvi.imask,LVIF_TEXT+LVIF_PARAM
	push row
	pop lvi.iItem	
	mov lvi.iSubItem,0
	lea eax,[edi].cFileName
	mov lvi.pszText,eax
	push row
	pop lvi.lParam
	invoke SendMessage,hList, LVM_INSERTITEM,0, addr lvi
	mov lvi.imask,LVIF_TEXT
	inc lvi.iSubItem
	invoke wsprintf,addr buffer, addr template,[edi].nFileSizeLow
	lea eax,buffer
	mov lvi.pszText,eax
	invoke SendMessage,hList,LVM_SETITEM, 0,addr lvi
	assume edi:nothing
	ret
ShowFileInfo endp

ShowMusicItem proc uses edx eax ebx, row:DWORD
	LOCAL lvi:LV_ITEM
	

	mov lvi.imask,LVIF_TEXT+LVIF_PARAM
	push row
	pop lvi.iItem	
	mov lvi.iSubItem,0

	mov eax, row
	mov ebx, INFO_LEN
	mul ebx
	add eax, OFFSET musicList
	add eax, PATH_LEN
	mov lvi.pszText,eax

	push row
	pop lvi.lParam
	invoke SendMessage,hList, LVM_INSERTITEM,0, addr lvi

	ret
ShowMusicItem endp



FillFileInfo proc uses edi
	LOCAL finddata:WIN32_FIND_DATA
	LOCAL FHandle:DWORD
	LOCAL lina:DWORD
	
	invoke GetList
	xor edi, edi
L1:
	.IF edi < musicListLen
		invoke ShowMusicItem, edi
		inc edi
		jmp L1
	.ENDIF


COMMENT *
	invoke FindFirstFile,addr ListName,addr finddata
	.if eax!=INVALID_HANDLE_VALUE
		mov FHandle,eax
		xor ebx,ebx
		.while eax!=0
			test finddata.dwFileAttributes,FILE_ATTRIBUTE_DIRECTORY
			.if ZERO?
				;invoke ShowFileInfo,edi, addr finddata
L1:
				.IF ebx < musicListLen
				invoke ShowMusicItem, ebx
				inc ebx
				jmp L1
				.ENDIF
			.endif
			invoke FindNextFile,FHandle,addr finddata
		.endw
		invoke FindClose,FHandle
	.endif
*
	ret
FillFileInfo endp



CreateListWin PROC, hWnd: DWORD, hInstance: DWORD
	invoke CreateWindowEx, NULL, addr ListViewClassName, NULL, LVS_LIST+WS_CHILD+WS_VISIBLE, 100,100,500,500,hWnd, NULL, hInstance, NULL
	mov hList, eax
	invoke InsertColumn
	invoke FillFileInfo
	RGB 255,255,255
	invoke SendMessage,hList,LVM_SETTEXTCOLOR,0,eax
	RGB 0,0,0
	invoke SendMessage,hList,LVM_SETBKCOLOR,0,eax
	RGB 0,0,0
	invoke SendMessage,hList,LVM_SETTEXTBKCOLOR,0,eax
	ret
CreateListWin ENDP
END