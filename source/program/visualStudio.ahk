; Visual Studio hotkeys.
#If Config.isWindowActive("Visual Studio")
	; Copy current file/folder paths to clipboard
	!c::  ClipboardLib.copyFilePathWithHotkey(          VisualStudio.Hotkey_CopyCurrentFile) ; Current file
	^!#c::ClipboardLib.copyCodeLocationRelativeToSource(VisualStudio.Hotkey_CopyCurrentFile) ; Current file, but drop the usual EpicSource stuff up through the DLG folder and add the selected text as a function.
	^!f:: ClipboardLib.openActiveFileParentFolder(      VisualStudio.Hotkey_CopyCurrentFile)
	
	; Subword navigation, because I can't use the windows key in hotkeys otherwise
	^#Left::  Send, ^!{Numpad1} ; Previous subword
	^#Right:: Send, ^!{Numpad2} ; Next subword
	^#+Left:: Send, ^!{Numpad3} ; Extend selection previous
	^#+Right::Send, ^!{Numpad4} ; Extend selection next
	
	:X:dbpop::VisualStudio.sendDebugCodeStringTS(clipboard) ; Debug popup
#If
