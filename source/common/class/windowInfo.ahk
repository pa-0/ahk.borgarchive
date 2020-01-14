; Data class to hold identifying information about a specific window.

class WindowInfo {
	; #PUBLIC#
	
	; @GROUP@ Window edge types (see VisualWindow class for what this means/how it's used).
	static EdgeStyle_HasPadding := "HAS_PADDING" ; The window has the standard padding around the edges.
	static EdgeStyle_NoPadding  := "NO_PADDING"  ; The window has no padding around the edges.
	; @GROUP-END@
	
	; @GROUP@
	name     := ""                              ; Name of the window
	exe      := ""                              ; EXE for the corresonding program
	class    := ""                              ; AHK class of the window
	title    := ""                              ; Title of the window
	priority := ""                              ; Priority of this WindowInfo instance versus others. Can be used to break a tie if multiple instances match a given window.
	edgeType := WindowInfo.EdgeStyle_HasPadding ; Edge type of the window (from WindowInfo.EdgeStyle_* constants)
	titleStringMatchModeOverride := Config.TitleContains_Any ; If the window has a specific title match mode that needs to be used when locating it, this will return that override.
	; @GROUP-END@
	
	;---------
	; DESCRIPTION:    A string that can be used with WinActive() and the like to identify this
	;                 window.
	;---------
	titleString {
		get {
			return WindowLib.buildTitleString(this.exe, this.class, this.title)
		}
	}
	
	;---------
	; DESCRIPTION:    Creates a new instance of WindowInfo.
	; PARAMETERS:
	;  windowAry (I,REQ) - Array of identifying information about the window. Format:
	;                         windowAry["NAME"]  - The name of the window, for identification in code.
	;                                  ["EXE"]   - The exe for the window
	;                                  ["CLASS"] - The AHK class of the window
	;                                  ["TITLE"] - The title of the window
	;                      There are also a couple of special overrides available in the array:
	;                         windowAry["PRIORITY"]
	;                                      - If more than one WindowInfo instance matches a given
	;                                        window, this can be used to break the tie.
	;                                  ["EDGE_TYPE"]
	;                                      - The type of edges the window has (from
	;                                        WindowInfo.EdgeStyle_* constants), which determines
	;                                        whether the window is the size that it appears or if it
	;                                        has invisible padding around it that needs to be taken
	;                                        into account when resizing, etc.
	;                                  ["TITLE_STRING_MATCH_MODE_OVERRIDE"]
	;                                      - If the window has a specific title match mode that
	;                                        needs to be used when locating it, this will return
	;                                        that override.
	;---------
	__New(windowAry) {
		this.name  := windowAry["NAME"]
		this.exe   := windowAry["EXE"]
		this.class := windowAry["CLASS"]
		this.title := windowAry["TITLE"]
		
		; Replace any private tags lurking in these portions of info.
		this.name  := Config.replacePrivateTags(this.name)
		this.exe   := Config.replacePrivateTags(this.exe)
		this.class := Config.replacePrivateTags(this.class)
		this.title := Config.replacePrivateTags(this.title)
		
		this.priority := windowAry["PRIORITY"]
		if(windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"] != "")
			this.titleStringMatchModeOverride := windowAry["TITLE_STRING_MATCH_MODE_OVERRIDE"]
		if(windowAry["EDGE_TYPE"] != "")
			this.edgeType := windowAry["EDGE_TYPE"]
	}
	
	
	; #DEBUG#
	
	Debug_TypeName() {
		return "WindowInfo"
	}
	; #END#
}
