#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, %A_ScriptDir% ; Ensures a consistent starting directory.

#Include <includeCommon>

/* .bits file format:
		One line per regex bit
			Each should be valid by itself
			Each should be surrounded by parentheses
			They may be indented as desired, if and only if they are under a header AND they have following explanation lines
		Optional headers should be left-justified (no indentation) and start with a single quote (')
			They may also end with a single quote for syntax highlighting purposes, but this isn't required
			If regex bit lines are under a header they may be indented (as desired)
		Optional explanation lines can come after each regex bit line
			They must be indented at least once
*/

; Start in the relevant folder.
SetWorkingDir, % Config.path["EPICSTUDIO_GLOBAL_HIGHLIGHTS"]

; Loop over all .bits files and compile them into .regex files.
Loop, Files, % "*.bits"
{
	fileString := FileRead(A_LoopFileName)
	
	; Compile the bits into one pipe-delimited regex string (and filter out header/explanation strings)
	fileString    := fileString "`r`n"                               ; Add a newline to the end so our pattern (which ends with and replaces the newline at the end of non-regex lines) can catch the last line
	regexLines    := fileString.removeRegEx("m)^('|\t).+(\r\n)+\t*") ; Replace everything that starts with a single quote (header lines) or with a double tab (explanation lines) + the newline after it + any tabs
	combinedRegex := regexLines.replaceRegEx("m)\r\n\(", "|(")       ; Replace remaining newlines (the one between regex lines) with pipes
	finalString   := combinedRegex.removeRegEx("m)(\r\n)*")          ; Remove any extra newlines (the one added when we read in the file and anything else)
	
	; Generate the name of the compiled regex file from the base name of the original
	SplitPath(A_LoopFileName, "", "", "", baseName)
	
	; Overwrite the file if it exists
	replaceFileWithString(baseName ".regex", finalString)
}

Toast.showMedium("Compiled all .bits files into .regex files")
Sleep, 2500 ; Wait for the toast to finish and fade out before exiting

ExitApp
