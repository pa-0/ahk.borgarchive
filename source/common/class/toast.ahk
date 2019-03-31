/* Class that shows something like a toast notification.
	
	Usage:
		Create Toast instance
		Show it (.showForSeconds or .show)
		If not showing on a timer, close it when finished (.close)
	
	Example:
		; Show a toast on a 5-second timer
		t := new Toast("5-second timer toast!")
		t.showForSeconds(5)
		; (OR)
		Toast.showMedium("5-second timer toast!")
		
		; Show a toast, then hide it after finishing a longer-running action
		t := new Toast("Running long action")
		t.showPersistent()
		... ; Long action happens
		t.setText("Next step")
		... ; Next step happens
		t.hide() ; Toast is hidden but still exists
		...
		t.showPersistent() ; Toast becomes visible again
		...
		t.close() ; Toast is destroyed
*/

class Toast {
	
	; ==============================
	; == Public (Static) ===========
	; ==============================
	
	static X_ALIGN_LEFT   := -1 ; Against left edge of screen
	static X_ALIGN_RIGHT  := -2 ; Against right edge of screen
	static X_ALIGN_CENTER := -3 ; Horizontally centered
	static Y_ALIGN_TOP    := -1 ; Against top edge of screen
	static Y_ALIGN_BOTTOM := -2 ; Against bottom edge of screen
	static Y_ALIGN_CENTER := -3 ; Vertically centered
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "short" toast (shown for 1 second) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showShort(toastText) {
		Toast.showForSeconds(toastText, 1, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "medium" toast (shown for 2 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showMedium(toastText) {
		Toast.showForSeconds(toastText, 2, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Wrapper for Toast.showForSeconds for a "long" toast (shown for 5 seconds) in
	;                 the bottom-right corner of the screen.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showLong(toastText) {
		Toast.showForSeconds(toastText, 5, Toast.X_ALIGN_RIGHT, Toast.Y_ALIGN_BOTTOM)
	}
	
	;---------
	; DESCRIPTION:    Static caller to show this toast for a certain number of seconds, then destroy it.
	; PARAMETERS:
	;  toastText  (I,REQ) - The text to show in the toast.
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x (I,OPT) - The x coordinate to show the toast at (or special value from Toast.X_ALIGN_*).
	;              Defaults to previous position (if set), then right edge of screen.
	;  y (I,OPT) - The y coordinate to show the toast at (or special value from Toast.Y_ALIGN_*).
	;              Defaults to previous position (if set), then bottom edge of screen.
	; SIDE EFFECTS:   The toast is destroyed when the time expires.
	;---------
	showForSeconds(toastText, numSeconds, x := -2, y := -2) { ; x := Toast.X_ALIGN_RIGHT, y := Toast.Y_ALIGN_BOTTOM
		idAry := this.buildGui()
		guiId        := idAry["GUI_ID"]
		labelVarName := idAry["LABEL_VAR_NAME"]
		
		this.setLabelText(toastText, labelVarName)
		this.showToast(x, y, guiId)
		
		closeFunc := ObjBindMethod(Toast, "closeToast", guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % closeFunc, % -numSeconds * 1000
	}
	
	
	; ==============================
	; == Public (Persistent) =======
	; ==============================
	
	;---------
	; DESCRIPTION:    Create a new Toast object.
	; PARAMETERS:
	;  toastText         (I,REQ) - The text to show in the toast.
	;  styleOverridesAry (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                              found in .getStyleAry().
	; RETURNS:        A new instance of this class.
	;---------
	__New(toastText := "", styleOverridesAry := "") {
		idAry := this.buildGui(styleOverridesAry)
		this.guiId        := idAry["GUI_ID"]
		this.labelVarName := idAry["LABEL_VAR_NAME"]
		
		if(toastText)
			this.setLabelText(toastText, this.labelVarName)
	}
	
	;---------
	; DESCRIPTION:    Show this toast indefinitely, until it is hidden or closed.
	; PARAMETERS:
	;  x (I,OPT) - The x coordinate to show the toast at (or special value from Toast.X_ALIGN_*).
	;              Defaults to previous position (if set), then right edge of screen.
	;  y (I,OPT) - The y coordinate to show the toast at (or special value from Toast.Y_ALIGN_*).
	;              Defaults to previous position (if set), then bottom edge of screen.
	;---------
	showPersistent(x := "", y := "") {
		Gui, % this.guiId ":Default"
		
		; Use optional x/y if given.
		if(x != "")
			this.x := x
		if(y != "")
			this.y := y
		
		; Default to bottom-right if nothing given and no previous position.
		if(this.x = "")
			this.x := Toast.X_ALIGN_RIGHT
		if(this.y = "")
			this.y := Toast.Y_ALIGN_BOTTOM
		
		this.showToast(this.x, this.y, this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Show this toast for a certain number of seconds, then hide it.
	; PARAMETERS:
	;  numSeconds (I,REQ) - The number of seconds to show the toast for.
	;  x          (I,OPT) - The x coordinate to show the toast at (or special value from Toast.X_ALIGN_*).
	;                       Defaults to previous position (if set), then right edge of screen.
	;  y          (I,OPT) - The y coordinate to show the toast at (or special value from Toast.Y_ALIGN_*).
	;                       Defaults to previous position (if set), then bottom edge of screen.
	;---------
	showPersistentForSeconds(numSeconds, x := "", y := "") {
		Gui, % this.guiId ":Default"
		
		this.showPersistent(x, y)
		
		hideFunc := ObjBindMethod(Toast, "hideToast", this.guiId) ; Create a BoundFunc object of the .closeToast function (with guiId passed to it) for when the timer finishes.
		SetTimer, % hideFunc, % -numSeconds * 1000
	}
	
	;---------
	; DESCRIPTION:    Change the text for the toast, without hiding it.
	; PARAMETERS:
	;  toastText (I,REQ) - The text to show in the toast.
	; NOTES:          Will try to maintain the same position, but toast size will expand to fit text.
	;---------
	setText(toastText) {
		Gui, % this.guiId ":Default"
		this.setLabelText(toastText, this.labelVarName)
		this.move(this.x, this.y)
	}
	
	;---------
	; DESCRIPTION:    Fade the toast out, but don't destroy it (use .close() instead if you're
	;                 finished with the toast).
	;---------
	hide() {
		Gui, % this.guiId ":Default"
		this.hideToast(this.guiId)
	}
	
	;---------
	; DESCRIPTION:    Hide and destroy the GUI for this toast.
	;---------
	close() {
		Gui, % this.guiId ":Default"
		this.closeToast(this.guiId)
	}
	
	
	; ==============================
	; == Private ===================
	; ==============================
	
	static widthLabelNum := 0
	
	stylesAry    := ""
	guiId        := ""
	labelVarName := ""
	x            := ""
	y            := ""
	
	
	;---------
	; DESCRIPTION:    Build the toast gui, applying various properties.
	; PARAMETERS:
	;  styleOverridesAry (I,OPT) - Any style overrides that you'd like to make. Defaults can be
	;                              found in .getStyleAry().
	; SIDE EFFECTS:   Saves off a reference to the gui's window handle.
	; RETURNS:        Array of ID information, format:
	;                 	idAry["GUI_ID"]         = Window handle/guiId
	;                 	     ["LABEL_VAR_NAME"] = Name of the global variable connected to the label
	;                 	                          containing the toast text.
	;---------
	buildGui(styleOverridesAry := "") {
		; Create Gui and save off window handle (which is also guiId)
		Gui, New, +HWNDguiId
		
		; Other gui options
		Gui, +AlwaysOnTop -Caption +LastFound +Toolwindow
		Gui, % "+E" WS_EX_CLICKTHROUGH
		
		; Set formatting options
		styleAry := Toast.getStyleAry(styleOverridesAry)
		Gui, Color, % styleAry["BACKGROUND_COLOR"]
		Gui, Font, % "c" styleAry["FONT_COLOR"] " s" styleAry["FONT_SIZE"], % styleAry["FONT_NAME"]
		Gui, Margin, % styleAry["MARGIN_X"], % styleAry["MARGIN_Y"]
		
		; Add label
		labelVarName := guiId "Text" ; Come up with a unique variable we can use to reference the label (to change its contents if needed).
		setDynamicGlobalVar(labelVarName) ; Since the variable must be global, declare it as such.
		Gui, Add, Text, % "v" labelVarName
		
		return {"GUI_ID":guiId, "LABEL_VAR_NAME":labelVarName}
	}
	
	;---------
	; DESCRIPTION:    Determine the styles to use for the toast gui, based on hard-coded defaults
	;                 and any given overrides.
	; PARAMETERS:
	;  styleOverridesAry (I,OPT) - Array of style overrides, see default styles below for supported
	;                              subscripts. Format:
	;                                styleOverridesAry(<property>) := <value>
	; RETURNS:        Combined array of styles to use for the toast gui.
	;---------
	getStyleAry(styleOverridesAry := "") {
		styleAry := []
		
		; Default styles
		styleAry["BACKGROUND_COLOR"] := "2A211C"
		styleAry["FONT_COLOR"]       := "BDAE9D"
		styleAry["FONT_SIZE"]        := 20
		styleAry["FONT_NAME"]        := "Consolas"
		styleAry["MARGIN_X"]         := 5
		styleAry["MARGIN_Y"]         := 0
		
		; Merge in any overrides
		styleAry := mergeArrays(styleAry, styleOverridesAry)
		
		return styleAry
	}
	
	;---------
	; DESCRIPTION:    Move the toast gui to the given coordinates and resize it to its contents.
	; PARAMETERS:
	;  x         (I,OPT) - The x coordinate to show the toast at (or special value from Toast.X_ALIGN_*).
	;  y         (I,OPT) - The y coordinate to show the toast at (or special value from Toast.Y_ALIGN_*).
	;---------
	move(x, y) {
		; If x/y not given, default them to right/bottom
		if(x = "")
			x := Toast.X_ALIGN_RIGHT
		if(y = "")
			y := Toast.Y_ALIGN_BOTTOM
		
		; Take special alignment values into account
		Gui, +LastFound ; Needed for WinGetPos
		WinGetPos, , , guiWidth, guiHeight
		boundsAry := getMonitorBounds()
		if(x = Toast.X_ALIGN_LEFT)
			x := boundsAry["LEFT"]
		if(y = Toast.Y_ALIGN_TOP)
			y := boundsAry["TOP"]
		
		if(x = Toast.X_ALIGN_RIGHT)
			x := boundsAry["LEFT"] + boundsAry["WIDTH"]  - guiWidth
		if(y = Toast.Y_ALIGN_BOTTOM)
			y := boundsAry["TOP"]  + boundsAry["HEIGHT"] - guiHeight
		
		if(x = Toast.X_ALIGN_CENTER)
			x := boundsAry["LEFT"] + (boundsAry["WIDTH"]  - guiWidth)  / 2
		if(y = Toast.Y_ALIGN_CENTER)
			y := boundsAry["TOP"]  + (boundsAry["HEIGHT"] - guiHeight) / 2
		
		Gui, Show, % "x" x " y" y " NoActivate"
	}
	
	;---------
	; DESCRIPTION:    Set the text of the toast label and resize it fit that text.
	; PARAMETERS:
	;  toastText    (I,REQ) - The text to show in the toast.
	;  labelVarName (I,REQ) - The name of the global variable connected to the toast label.
	;---------
	setLabelText(toastText, labelVarName) {
		; Figure out how wide the text control needs to be to fit its contents
		Toast.widthLabelNum++
		getLabelSizeForText(toastText, "WidthLabel" Toast.widthLabelNum, textWidth, textHeight)
		
		; Update the text and width
		GuiControl,     , % labelVarName, % toastText
		GuiControl, Move, % labelVarName, % "w" textWidth " h" textHeight
		
		; Resize to size of contents
		Gui, Show, AutoSize NoActivate Hide
	}
	
	;---------
	; DESCRIPTION:    Show (fade in) the toast.
	; PARAMETERS:
	;  x     (I,OPT) - The x coordinate to show the toast at (or special value from Toast.X_ALIGN_*).
	;  y     (I,OPT) - The y coordinate to show the toast at (or special value from Toast.Y_ALIGN_*).
	;  guiId (I,REQ) - Window handle for the toast gui.
	;---------
	showToast(x, y, guiId) {
		this.move(x, y) ; Don't show the gui until we transition it in below
		fadeGuiIn(guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade out the toast gui, but don't destroy it.
	; PARAMETERS:
	;  guiId (I,REQ) - Gui ID (window handle) of the toast gui.
	;---------
	hideToast(guiId) {
		fadeGuiOut(guiId)
	}
	
	;---------
	; DESCRIPTION:    Fade out and destroy the toast gui.
	; PARAMETERS:
	;  guiId (I,REQ) - Gui ID (window handle) of the toast gui.
	;---------
	closeToast(guiId) {
		this.hideToast(guiId)
      Gui, Destroy
	}
}