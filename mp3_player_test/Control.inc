CreatePlayButton		PROTO, hWnd: DWORD, hIns: DWORD
CreateTrackBar			PROTO, hWnd: DWORD, hIns: DWORD
CreateSoundBar			PROTO, hWnd: DWORD, hIns: DWORD
CreatePlaybackButton	PROTO, hWnd: DWORD, hIns: DWORD, mode: BYTE
SwitchTrackState		PROTO
BarAdjust				PROTO

playBtn_ID		EQU 400
nextBtn_ID		EQU	401
previousBtn_ID	EQU 402
Bar_ID			EQU 233

IDB_PLAY EQU 250
IDB_PAUSE EQU 251