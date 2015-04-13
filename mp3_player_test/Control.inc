CreatePlayButton		PROTO, hWnd: DWORD, hIns: DWORD
CreateTrackBar			PROTO, hWnd: DWORD, hIns: DWORD
CreateVolumeBar			PROTO, hWnd: DWORD, hIns: DWORD
CreatePlaybackButton	PROTO, hWnd: DWORD, hIns: DWORD, mode: BYTE
PlaybackButtonClicked	PROTO, mode: BYTE
SwitchTrackState		PROTO
BarAdjust				PROTO
VolumeBarAdjust			PROTO

playBtn_ID		EQU 400
nextBtn_ID		EQU	401
previousBtn_ID	EQU 402
Bar_ID			EQU 233

windowWidth		EQU 360
windowHeight	EQU 650