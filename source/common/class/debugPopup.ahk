/* GDB TODO --=
	
	Example Usage
;		GDB TODO
	
	GDB TODO
		Update auto-complete and syntax highlighting notepad++ definitions
	
*/ ; =--

; Edit width = 9*numChars + 13

class DebugPopup {
	; #PUBLIC#
	
	;  - Constants
	static Prefix_GuiSpecialLabels := "DebugPopupGui_" ; Used to have the gui call DebugPopupGui_* functions instead of just Gui* ones
	static EditField_VarName := "DebugEdit"
	;  - staticMembers
	
	;  - nonStaticMembers
	guiId       := ""
	
	
	mouseIsOverEditField() {
		MouseGetPos("", "", windowUnderMouse, varNameUnderMouse)
		GuiControlGet, mouseName, % this.guiId ":Name", % varNameUnderMouse
		
		return (windowUnderMouse = this.guiId && mouseName = this.EditField_VarName)
	}
	
	
	
	;  - properties
	;  - __New()/Init()
	__New(params*) {
		
		
		global DebugEdit := 5 ; GDB TODO do this nicer, probably with a unique, incrementing value like SelectorGui does
		
		; GDB TODO move all of these to constants
		fontSize := 12 ; 12pt
		fontName := "Consolas"
		editLineHeight := 19 ; For size 12 Consolas
		charWidth := 9
		
		editTotalMarginWidth := 8 ; How much extra space the edit control needs to cut off at character edges
		
		backgroundColor := "444444"
		fontColor := "00FF00"
		
		
		
		
		table := new DebugTable("Debug Info").thickBorderOn()
		table.addPairs(params*)
		
		message   := table.getText()
		lineWidth := table.getWidth()
		numLines  := table.getHeight()
		
		
		
		
		
		needVScroll := false
		needHScroll := false
		
		; 90% of available height/width so we're not right up against the edges
		workArea := WindowLib.getMonitorWorkArea()
		availableHeight := workArea["HEIGHT"] * 0.9
		availableWidth  := workArea["WIDTH"]  * 0.9
		
		possibleHeight := (editLineHeight * numLines)
		if(possibleHeight > availableHeight) {
			numLinesToShow := availableHeight // editLineHeight
			needVScroll := true
		} else {
			numLinesToShow := numLines
		}
		editHeight := (editLineHeight * numLinesToShow)
		
		; GDB TODO this whole block seems like a good function - "find max possible size based on max + margin + increments)
		possibleWidth := (lineWidth * charWidth) + editTotalMarginWidth
		if(possibleWidth > availableWidth) {
			numCharsToShow := (availableWidth - editTotalMarginWidth) // charWidth
			needHScroll := true
		} else {
			numCharsToShow := lineWidth
		}
		editWidth := (numCharsToShow * charWidth) + editTotalMarginWidth
		
		; Debug.popup("numCharsToShow",numCharsToShow, "numCharsToShow*charWidth",numCharsToShow*charWidth, "editLeftPaddingBuiltIn",editLeftPaddingBuiltIn, "needHScroll",needHScroll, "editWidth",editWidth, "fullWidth",fullWidth)
		
		
		
		Gui, New, % "+HWNDguiId +Label" this.Prefix_GuiSpecialLabels ; guiId := gui's window handle, DebugPopupGui_* functions instead of Gui*
		this.guiId := guiId
		
		Gui, Margin, 0, 0
		Gui, Color, % backgroundColor
		Gui, Font, % "c" fontColor " s" fontSize, % fontName
		
		editProperties := "ReadOnly -WantReturn -E0x200 -VScroll -Wrap v" this.EditField_VarName " h" editHeight " w" editWidth
		Gui, Add, Edit, % editProperties, % message
		
		
		Gui, Font ; Restore font to default
		
		
		Gui, Add, Button, Hidden Default gDebugPopupGui_Close x0 y0 ; DebugPopupGui_Close call on click/activate
		
		Gui, -MinimizeBox -MaximizeBox -0x400000 ; 0x400000=WS_DLGFRAME +ToolWindow ;+0x800000 ; 0x800000=WS_BORDER ;
		GuiControl, Focus, % this.EditField_VarName
		
		; guiWidth := editWidth + 10
		; Gui, Show, % "w" guiWidth, Debug Info
		Gui, Show, , Debug Info
		
		Gui, +LastFound ; GDB TODO do we still need this?
		
		; WinGetPos, , , winWidth, winHeight
		; Debug.popup("numLines",numLines, "winWidth",winWidth, "winHeight",winHeight, "workArea",workArea)
		
		
		mouseIsOverEditField := ObjBindMethod(this, "mouseIsOverEditField")
		Hotkey, If, % mouseIsOverEditField
		if(needVScroll) {
			scrollUp   := ObjBindMethod(this, "scrollUp",   3)
			scrollDown := ObjBindMethod(this, "scrollDown", 3)
			Hotkey, ~WheelUp,    % scrollUp
			Hotkey, ~WheelDown,  % scrollDown
			
			scrollUpPrecise   := ObjBindMethod(this, "scrollUp",   1)
			scrollDownPrecise := ObjBindMethod(this, "scrollDown", 1)
			Hotkey, ~^WheelUp,   % scrollUpPrecise
			Hotkey, ~^WheelDown, % scrollDownPrecise
		}
		if(needHScroll) {
			scrollLeft  := ObjBindMethod(this, "scrollLeft",  10)
			scrollRight := ObjBindMethod(this, "scrollRight", 10)
			Hotkey, ~+WheelUp,    % scrollLeft
			Hotkey, ~+WheelDown,  % scrollRight
			
			scrollLeftPrecise  := ObjBindMethod(this, "scrollLeft",  1)
			scrollRightPrecise := ObjBindMethod(this, "scrollRight", 1)
			Hotkey, ~+^WheelUp,   % scrollLeftPrecise
			Hotkey, ~+^WheelDown, % scrollRightPrecise
		}
		Hotkey, If
		
		; WinWaitClose
		
		; GDB TODO do we need to disable the hotkeys when we close? (only if they exist, though - either check if the hotkeys exist, or just use needVScroll/needHScroll)
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
		
	}
	;  - otherFunctions
	scrollUp(numLines := 1) { ; GDB TODO should these specific send-message commands just live in MicrosoftLib?
		Loop, % numLines
			SendMessage, 0x115, 0, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEUP
	}
	scrollDown(numLines := 1) { ; GDB TODO can we use something more specific than Edit1?
		Loop, % numLines
			SendMessage, 0x115, 1, , Edit1, % "ahk_id " this.guiId ; WM_VSCROLL, SB_LINEDOWN
	}
	scrollLeft(numLines := 1) {
		Loop, % numLines
			SendMessage, 0x114, 0, , Edit1, % "ahk_id " this.guiId ; WM_HSCROLL, SB_LINELEFT
	}
	scrollRight(numLines := 1) {
		Loop, % numLines
			SendMessage, 0x114, 1, , Edit1, % "ahk_id " this.guiId ; WM_HSCROLL, SB_LINERIGHT
	}
	
	
	; #INTERNAL#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	
	
	; #PRIVATE#
	
	;  - Constants
	;  - staticMembers
	;  - nonStaticMembers
	;  - functions
	; #END#
}

DebugPopupGui_Close() {
	Gui, Destroy
}

class DebugTable {
	title := ""
	table := new TextTable().setBorderType(TextTable.BorderType_Line)
	
	__New(title) {
		this.title := title
		this.table.setTopTitle(title)
	}
	
	thickBorderOn() {
		this.table.setBorderType(TextTable.BorderType_BoldLine)
		return this
	}
	
	addPairs(params*) {
		Loop, % params.MaxIndex() // 2 {
			label := params[A_Index * 2 - 1]
			value := params[A_Index * 2]
			this.addLine(label, value)
		}
	}
	
	addLine(label, value) {
		this.table.addRow(label ":", this.buildValueDebugString(value))
	}
	
	getText() {
		; Also add the title to the bottom if the table ends up tall enough.
		if(this.table.getHeight() > 50)
			this.table.setBottomTitle(this.title)
		
		return this.table.getText()
	}
	
	getWidth() {
		return this.table.getWidth()
	}
	
	getHeight() {
		return this.table.getHeight()
	}
	
	
	
	buildValueDebugString(value) {
		; Base case - not a complex object, just return the value to show.
		if(!isObject(value))
			return value
		
		; Just display the name if it's an empty object (like an empty array)
		objName := this.getObjectName(value)
		if(value.count() = 0)
			return objName
		
		; Compile child values
		childTable := new DebugTable(objName)
		if(isFunc(value.Debug_ToString)) { ; If an object has its own debug logic, use that rather than looping.
			value.Debug_ToString(childTable)
		} else {
			For subLabel,subVal in value
				childTable.addLine(subLabel, subVal)
		}
		
		return childTable.getText()
	}

	getObjectName(value) {
		; If an object has its own name specified, use it.
		if(isFunc(value.Debug_TypeName))
			return value.Debug_TypeName()
			
		; For other objects, just use a generic "Array"/"Object" label and add the number of elements.
		if(value.isArray)
			return "Array (" value.count() ")"
		return "Object (" value.count() ")"
	}
}
