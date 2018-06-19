
setTrayIcon(iconPath) {
	if(!iconPath || !FileExist(iconPath))
		return ""
	
	originalIconPath := A_IconFile ; Back up the current icon before changing it.
	Menu, Tray, Icon, % iconPath
	
	return originalIconPath
}

applyTitleFormat() {
	Gui, Font, w600 underline ; Heavier weight (not quite bold), underline.
}
clearTitleFormat() {
	Gui, Font, norm
}

; Assumes that the formatting that would apply to the text in question is currently in effect.
getLabelWidthForText(text, uniqueId) {
	static ; Assumes-static mode - means that any variables that are used in here are assumed to be static
	Gui, Add, Text, vVar%uniqueId%, % text
	GuiControlGet, out, Pos, Var%uniqueId%
	GuiControl, Hide, Var%uniqueId% ; GuiControl, Delete not yet implemented, so just hide the temporary control.
	
	return outW
}

; These two basically let us hide the static/global requirement for variables used for GUI controls - 
; the given string is the variable name, but as long as it's only referenced via indirection, it won't 
; be treated as a local variable in other functions.
setDynamicGlobalVar(varName, value := "") {
	global
	%varName% := value
}
getDynamicGlobalVar(varName) {
	global
	local value := %varName%
	return value
}

fadeGuiIn(guiId, showProperties := "", maxOpacity := 255, numSteps := 10) {
	if(!guiId)
		return
	
	WinSet, Transparent, 0, % "ahk_id " guiId ; Start fully transparent
	Gui, % guiId ":Default"
	Gui, Show, % showProperties
	
	stepSize := maxOpacity / numSteps
	Loop, %numSteps% {
		WinSet, Transparent, % (A_Index * stepSize), % "ahk_id " guiId
		Sleep, 10 ; 10ms between steps - can vary fade speed with number of steps
	}
}
fadeGuiOut(guiId, numSteps := 10) {
	if(!guiId)
		return
	
	startOpacity := WinGet("Transparent", "ahk_id " guiId)
	stepSize := startOpacity / numSteps
	Loop, %numSteps% {
		WinSet, Transparent, % startOpacity - (A_Index * stepSize), % "ahk_id " guiId
		Sleep, 10 ; 10ms between steps - can vary fade speed with number of steps
	}
}
