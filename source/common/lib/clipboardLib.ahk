; Clipboard-related helper functions.

class ClipboardLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Copy something to the clipboard using the given hotkey, waiting for it to
	;                 take and returning whether we actually got something.
	; PARAMETERS:
	;  hotkeyKeys (I,REQ) - The keys to send in order to copy something to the clipboard.
	; RETURNS:        true if we successfully copied something, false otherwise.
	;---------
	copyWithHotkey(hotkeyKeys) {
		if(hotkeyKeys = "")
			return
		
		Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
		Send, % hotkeyKeys
		ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
		
		return (ErrorLevel != 1)
	}
	;---------
	; DESCRIPTION:    Get some text by copying it to the clipboard using the given hotkey.
	; PARAMETERS:
	;  hotkeyKeys (I,REQ) - The keys to send in order to copy something to the clipboard.
	; RETURNS:        The copied text.
	;---------
	getWithHotkey(hotkeyKeys) {
		if(hotkeyKeys = "")
			return ""
		
		; PuTTY auto-copies the selection to the clipboard, and ^c causes an interrupt, so do nothing.
		if(Config.isWindowActive("Putty") && !WinActive("PuTTY Reconfiguration"))
			return Clipboard
		
		origClipboard := ClipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
		ClipboardLib.copyWithHotkey(hotkeyKeys)
		
		textFound := Clipboard
		ClipboardLib.set(origClipboard) ; Restore the original clipboard.
		
		return textFound
	}
	
	;---------
	; DESCRIPTION:    Copy something using the provided functor object, but make sure that we actually
	;                 get something on the clipboard.
	; PARAMETERS:
	;  boundFunc (I,REQ) - Functor object to run in order to copy something to the clipboard.
	;  timeout   (I,OPT) - Timeout for the max length of time we should wait for the clipboard to contain the result. Defaults
	;                      to 0.5 seconds.
	; RETURNS:        true if we successfully copied something, false otherwise.
	;---------
	copyWithFunction(boundFunc, timeout := "") {
		if(!boundFunc)
			return
		if(timeout = "")
			timeout := 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
		
		Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
		%boundFunc%()
		ClipWait, % timeout
		
		return (ErrorLevel != 1)
	}
	;---------
	; DESCRIPTION:    Get some content using a BoundFunc object which copies something to the clipboard.
	; PARAMETERS:
	;  boundFunc (I,REQ) - A BoundFunc object created with Func().Bind() or ObjBindMethod(), which will
	;                      copy the desired content to the clipboard.
	;  timeout   (I,OPT) - Timeout for the max length of time we should wait for the clipboard to contain the result. Defaults
	;                      to 0.5 seconds.
	; RETURNS:        The copied content.
	;---------
	getWithFunction(boundFunc, timeout := "") { ; boundFunc is a BoundFunc object created with Func.Bind() or ObjBindMethod().
		if(!boundFunc)
			return
		
		originalClipboard := ClipboardAll ; Back up the clipboard since we're going to use it to get the selected text.
		ClipboardLib.copyWithFunction(boundFunc, timeout)
		
		textFound := Clipboard
		Clipboard := originalClipboard    ; Restore the original clipboard. Note we're using Clipboard (not ClipboardAll).
		
		return textFound
	}
	
	;---------
	; DESCRIPTION:    Copy a file path with the provided hotkeys, making sure that:
	;                  * We wait long enough for the file to get onto the clipboard
	;                  * The path has been cleaned up and mapped
	; PARAMETERS:
	;  hotkeyKeys (I,REQ) - The keys to send in order to copy the file's path to the clipboard.
	;---------
	copyFilePathWithHotkey(hotkeyKeys) {
		path := ClipboardLib.getWithHotkey(hotkeyKeys)
		if(path)
			path := FileLib.cleanupPath(path)
		
		ClipboardLib.setAndToast(path, "file path")
	}
	
	;---------
	; DESCRIPTION:    Grabs the path for the current file, trims it down to the bit inside the DLG/App * folder, and puts
	;                 it on the clipboard.
	; PARAMETERS:
	;  hotkeyKeys (I,REQ) - The keys to send in order to copy the file's path to the clipboard.
	;---------
	copyPathRelativeToSource(hotkeyKeys) {
		path := ClipboardLib.getWithHotkey(hotkeyKeys)
		if(!path) {
			new ErrorToast("Could not copy source-relative path", "Failed to get file path").showMedium()
			return
		}
		
		path := EpicLib.convertToSourceRelativePath(path)
		
		ClipboardLib.setAndToast(path, "Source-relative path")
	}
	
	;---------
	; DESCRIPTION:    Set the clipboard to the given value, and wait to make sure it applies before returning.
	; PARAMETERS:
	;  value         (I,REQ) - Value to set.
	;  origClipboard (O,OPT) - The original value of ClipboardAll (which is binary and contains
	;                          everything, not just the text on the clipboard). This can be used to
	;                          restore the clipboard later if needed.
	;---------
	set(value, ByRef origClipboard := "") {
		; This must be a ByRef return parameter instead of returning directly, as it's a binary
		; variable, which can't be returned directly (see https://www.autohotkey.com/boards/viewtopic.php?t=62209 ).
		origClipboard := ClipboardAll ; Save off everything (images, formatting), not just the text (that's all that's in Clipboard)
		
		Clipboard := "" ; Clear the clipboard so we can wait for it to actually be set
		if(!DataLib.isNullOrEmpty(value)) { ; Must use isNullOrEmpty as value could be binary
			Clipboard := value
			ClipWait, 0.5 ; Wait for the minimum time (0.5 seconds) for the clipboard to contain the new info.
		}
	}
	
	;---------
	; DESCRIPTION:    Set the clipboard to the given value and show a toast about it which includes the value.
	; PARAMETERS:
	;  newValue  (I,REQ) - The value to put on the clipboard.
	;  clipLabel (I,REQ) - The label to show in the toast for the thing on the clipboard.
	;---------
	setAndToast(newValue, clipLabel) {
		ClipboardLib.set(newValue)
		ClipboardLib.toastNewValue(clipLabel)
	}
	
	;---------
	; DESCRIPTION:    Set the clipboard to the given value and show an error toast about it.
	; PARAMETERS:
	;  newValue       (I,REQ) - The value to put on the clipboard.
	;  clipLabel      (I,REQ) - The label to show in the toast for the thing on the clipboard.
	;  problemMessage (I,REQ) - The problem that occurred.
	;  errorMessage   (I,OPT) - What went wrong on a technical level.
	;---------
	setAndToastError(newValue, clipLabel, problemMessage, errorMessage := "") {
		ClipboardLib.set(newValue)
		new ErrorToast(problemMessage, errorMessage, "Clipboard set to " clipLabel ":`n" Clipboard).showMedium()
	}
	
	;---------
	; DESCRIPTION:    Show a toast about the clipboard's current state (basically whether it's set or not),
	;                 also including the actual value.
	; PARAMETERS:
	;  clipLabel (I,REQ) - The label to show in the toast for the thing on the clipboard.
	;---------
	toastNewValue(clipLabel) {
		if(Clipboard = "")
			new ErrorToast("Failed to get " clipLabel).showMedium()
		else
			new Toast("Clipboard set to " clipLabel ":`n" Clipboard).showMedium()
	}
	
	;---------
	; DESCRIPTION:    Send the provided text using the clipboard, restoring the clipboard afterwards.
	; PARAMETERS:
	;  value (I,REQ) - The text to send.
	;---------
	send(value) {
		ClipboardLib.set(value, origClipboard)
		Send, ^v   ; Paste the new value.
		Sleep, 100 ; Needed to make sure clipboard isn't overwritten before we paste it.
		ClipboardLib.set(origClipboard)
	}
	
	;---------
	; DESCRIPTION:    Add something to the clipboard history, restoring the original clipboard value.
	; PARAMETERS:
	;  textToSave (I,REQ) - Text to add to the clipboard history.
	;---------
	addToHistory(textToSave) {
		ClipboardLib.set(textToSave, origClipboard)
		ClipboardLib.saveToManager()
		
		ClipboardLib.set(origClipboard)
		ClipboardLib.saveToManager()
	}
	
	
	; #PRIVATE#
	
	;---------
	; DESCRIPTION:    Force the clipboard manager to store the current value, generally useful just
	;                 before you change the clipboard to something else.
	;---------
	saveToManager() {
		if(Ditto) ; If the Ditto class exists we can use it to save to the clipboard with Ditto with no wait time.
			Ditto.saveCurrentClipboard()
		else ; Otherwise, just wait a second for it to register normally.
			Sleep, 1000
	}
	; #END#
}
