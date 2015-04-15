CreatePlayButton		PROTO, hWnd: DWORD, hIns: DWORD
CreateTrackBar			PROTO, hWnd: DWORD, hIns: DWORD
CreateVolumeBar			PROTO, hWnd: DWORD, hIns: DWORD
CreatePlaybackButton	PROTO, hWnd: DWORD, hIns: DWORD, mode: BYTE
CreateStatic			PROTO, hWnd: DWORD, hIns: DWORD
PlaybackButtonClicked	PROTO, mode: BYTE
SwitchTrackState		PROTO
BarAdjust				PROTO
VolumeBarAdjust			PROTO
CreateModeButton		PROTO,	hWnd: DWORD, hIns: DWORD

modeBtn_ID      EQU 403
playBtn_ID		EQU 400
nextBtn_ID		EQU	401
previousBtn_ID	EQU 402
Bar_ID			EQU 233
STATIC1_ID		EQU -1
STATIC2_ID		EQU -2
STATIC3_ID		EQU -3

windowWidth		EQU 360
windowHeight	EQU 450