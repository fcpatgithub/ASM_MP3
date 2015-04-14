
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
include		Track.inc

includelib	user32.lib
includelib	kernel32.lib
includelib	comctl32.lib
includelib	comdlg32.lib
includelib	winmm.lib

.data

public ListName

ListProP			dd 0
ListViewClassName	db "SysListView32",0
Heading1			db "Filename",0
Heading2			db "Size",0
;ListName			db "list.txt",0
ListName			db PATH_LEN dup (0)
Delete	            db "Delete",0


extrn hWinMain		: DWORD
extrn hList			: DWORD
extrn template		: WORD
extrn musicList		: musicInfo
extrn musicListLen	: DWORD
extern szBuffer		: BYTE
extern hWinBar		: DWORD
extrn currentMusicItem : DWORD
extrn config		: BYTE

.code

GetItemPath PROC uses eax ebx, Path:DWORD, ItemNum:DWORD
	mov eax, ItemNum
	.IF eax < 0 || eax >=musicListLen
		ret
	.ENDIF
	mov ebx, INFO_LEN
	mul ebx
	add eax, OFFSET musicList
	INVOKE szCopy, eax, Path
	ret
	
GetItemPath ENDP

NextMusic PROC uses eax ebx
	.IF musicListLen == 0
		ret
	.ENDIF
	inc currentMusicItem
	mov eax, currentMusicItem
	.IF eax == musicListLen
		mov currentMusicItem, 0 
	.ENDIF
	INVOKE GetItemPath, OFFSET szBuffer, currentMusicItem
	INVOKE _StopPlayMP3
	INVOKE PlayMP3, OFFSET szBuffer
	ret
NextMusic ENDP

PreviousMusic PROC uses eax ebx
	.IF musicListLen == 0
		ret
	.ENDIF
	mov eax, currentMusicItem
	.IF eax == 0
		mov eax, musicListLen  
	.ENDIF
	dec eax
	mov currentMusicItem,eax
	INVOKE GetItemPath, OFFSET szBuffer, currentMusicItem
	INVOKE _StopPlayMP3
	INVOKE PlayMP3, OFFSET szBuffer
	ret
PreviousMusic ENDP


WriteListFile proc uses esi ecx eax
	LOCAL fname :DWORD
	LOCAL hFile :DWORD

	mov		fname, OFFSET ListName
	.IF rv(exist, fname) != 0            
      test fdelete(fname), eax   
    .ENDIF
    mov		hFile, fcreate(fname)

	mov		esi, OFFSET musicList
	;add		esi, PATH_LEN
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
	
	;invoke WriteListFile
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
	mov lvi.state,0
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


_CreateMenu proc  
        LOCAL @hPopMenu1  
        LOCAL @hPopMenu2  
        invoke CreatePopupMenu  
        mov @hPopMenu1,eax  
        invoke CreatePopupMenu  
        mov @hPopMenu2,eax  
          
        invoke AppendMenu,@hPopMenu1,MF_STRING,1003, OFFSET Delete
          
        push @hPopMenu1  
        pop eax  
        ret  
    _CreateMenu endp  


WriteListName PROC uses esi eax ebx ecx
	LOCAL fname :DWORD
	LOCAL hFile :DWORD

	mov		fname, OFFSET config
	.IF rv(exist, fname) != 0            
      test fdelete(fname), eax   
    .ENDIF
    mov		hFile, fcreate(fname)

	mov		esi, OFFSET ListName
	;fprint	hFile,esi
	mov eax, fwrite(hFile,esi,len(esi))        ; write data to it

	fclose	hFile
	ret

WriteListName ENDP

GetListName PROC uses eax ebx
	LOCAL bufSize	: DWORD
	LOCAL bufAdd    : DWORD
	.IF rv(exist, ADDR config) != 0 
		invoke	read_disk_file, OFFSET config, ADDR bufAdd, ADDR bufSize 
	.ENDIF
	INVOKE szCopy, bufAdd, OFFSET ListName
	INVOKE WriteListName
	ret
GetListName ENDP




ListProc proc   hCtl	: DWORD,
                uMsg	: DWORD,
                wParam	: DWORD,
                lParam	: DWORD

    LOCAL IndexItem  :DWORD
    LOCAL Buffer[32] :BYTE
	LOCAL lvi:LV_ITEM

	LOCAL @stPos:POINT  
    LOCAL @hMenu  

    .IF uMsg == WM_LBUTTONDBLCLK
      jmp DoIt
	;.ELSEIF eax == WM_CREATE
	;	;Invoke SendMessage, nCtl, LVM_SETITEMSTATE,0, LVIS_SELECTED|LVIS_FOCUSED, LVIS_SELECTED|LVIS_FOCUSED
		
	;	jmp EndDo
    .ELSEIF uMsg == WM_CHAR
      .IF wParam == 13
        jmp DoIt
      .ENDIF
	.ELSEIF uMsg == WM_RBUTTONDOWN 
		 invoke _CreateMenu  
         mov @hMenu,eax  
         invoke GetCursorPos,addr @stPos  
         invoke TrackPopupMenu,@hMenu,TPM_LEFTALIGN,@stPos.x,@stPos.y,NULL,hList,NULL
	.ELSEIF uMsg == WM_COMMAND
      .IF wParam == 1003
		invoke SendMessage,hCtl,LVM_GETNEXTITEM,-1,LVNI_SELECTED
        mov IndexItem, eax
		invoke deleteItem, eax
        ;jmp DoIt
      .ENDIF
    .ENDIF
    jmp EndDo

 DoIt:
		
        invoke SendMessage,hCtl,LVM_GETNEXTITEM,-1,LVNI_SELECTED
		
        mov IndexItem, eax

	   szText CurSel1,"-"
comment*
         .if eax ==-1
          mov Buffer, '-'
		  .elseif eax ==0
		  mov Buffer, '0'
		  .elseif eax ==1 
		  mov Buffer, '1'
		  .elseif eax ==2 
		  mov Buffer, '2'
		  .elseif eax ==3 
		  mov Buffer, '3'
		  .elseif eax ==4 
		  mov Buffer, '4'
		  .else
		  mov Buffer, '6'
		  .endif
*
	.IF eax != -1 
		mov currentMusicItem, eax
		mov ebx, INFO_LEN
		mul ebx
		add eax, OFFSET musicList
		INVOKE szCopy, eax, OFFSET szBuffer
		INVOKE _StopPlayMP3
		INVOKE PlayMP3, OFFSET szBuffer
		
	.ENDIF
		
		

          ;invoke MessageBox,hWinMain,eax,ADDR CurSel1,MB_OK
        

EndDo:
    invoke CallWindowProc,ListProP,hCtl,uMsg,wParam,lParam

    ret

ListProc endp


CreateListWin PROC, hWnd: DWORD, hInstance: DWORD
	LOCAL lvi:LV_ITEM

	invoke CreateWindowEx, NULL, addr ListViewClassName, NULL, \
			LVS_LIST+WS_CHILD+WS_VISIBLE+LVS_SHOWSELALWAYS, 0, 170, 500, 430, hWnd, NULL, hInstance, NULL


	mov hList, eax
	invoke SetWindowLong,hList,GWL_WNDPROC,ListProc
	mov ListProP, eax
	invoke InsertColumn
	invoke FillFileInfo
	RGB 255,255,255
	invoke SendMessage,hList,LVM_SETTEXTCOLOR,0,eax
	RGB 200,200,200
	invoke SendMessage,hList,LVM_SETBKCOLOR,0,eax
	RGB 0,0,0
	invoke SendMessage,hList,LVM_SETTEXTBKCOLOR,0,eax

	.IF musicListLen >0		
		mov lvi.stateMask, LVIS_SELECTED+LVIS_FOCUSED
		mov lvi.state,  LVIS_SELECTED+LVIS_FOCUSED
		Invoke SendMessage, hList, LVM_SETITEMSTATE,0,ADDR lvi

		INVOKE szCopy, offset musicList, OFFSET szBuffer
		mov currentMusicItem,0
	.ENDIF




comment*

	invoke SendMessage,hList, LVM_GETITEMPOSITION, 0, ADDR p
	mov eax, p.y
	mov ebx, 65536
	mul ebx
	add ebx, p.x
	invoke SendMessage,hList, WM_LBUTTONDBLCLK, MK_LBUTTON, ebx
*

	ret
CreateListWin ENDP



deleteItem PROC uses eax ebx esi edx, ItemNum : DWORD
	szText Cannot_Delete_Mes,"The music is playing!"
	szText Cannot_Delete, "Delete Unsuccessfully"
	mov eax, ItemNum
	.IF eax < 0 || eax >=musicListLen
		ret
	.ENDIF
	.IF eax == currentMusicItem
		INVOKE MessageBox, hWinMain, ADDR Cannot_Delete, ADDR Cannot_Delete_Mes, MB_OK
		ret
	.ELSEIF eax<currentMusicItem
		dec currentMusicItem
	.ENDIF

	mov ebx, INFO_LEN
	mul ebx
	add eax, OFFSET musicList
	
	mov esi, ItemNum
	inc esi
L1:
	.IF esi >= musicListLen
		jmp END_DO
	.ENDIF
	mov ebx, eax
	add ebx, INFO_LEN
	push ebx
	push eax
	INVOKE szCopy, ebx, eax
	pop eax
	pop ebx
	add eax, PATH_LEN
	add ebx, PATH_LEN
	push ebx
	push eax
	INVOKE szCopy, ebx, eax
	pop eax
	pop ebx
	add eax, NAME_LEN
	add ebx, NAME_LEN
	mov edx, [ebx]
	mov [eax], edx
	add eax, 4
	add ebx, 4
	inc esi
	jmp L1

END_DO:
	dec musicListLen
	invoke SendMessage, hList, LVM_DELETEITEM, ItemNum, 0
	invoke WriteListFile
	ret
deleteItem ENDP

InsertItem PROC uses eax esi ebx, musicPath : ptr BYTE
	LOCAL lvi:LV_ITEM
	;insert the list
	mov eax, musicListLen
	mov ebx, INFO_LEN
	mul ebx
	add eax, OFFSET musicList
	mov esi,eax
	INVOKE szCopy, musicPath, eax 
	inc	musicListLen
	invoke	GetMusicNameFromPath, esi
	INVOKE szCopy, musicPath, OFFSET szBuffer

	

	mov eax, musicListLen
	dec eax
	invoke	ShowMusicItem, eax

	mov lvi.stateMask, LVIS_SELECTED+LVIS_FOCUSED
	mov lvi.state,  0
	Invoke SendMessage, hList, LVM_SETITEMSTATE,-1,ADDR lvi

	mov lvi.stateMask, LVIS_SELECTED+LVIS_FOCUSED
	mov lvi.state,  LVIS_SELECTED+LVIS_FOCUSED
	mov ebx, musicListLen
	dec ebx
	mov currentMusicItem, ebx
	Invoke SendMessage, hList, LVM_SETITEMSTATE,ebx,ADDR lvi
	mov ebx,eax


	;renew list file
	invoke WriteListFile	

	ret
InsertItem ENDP
END