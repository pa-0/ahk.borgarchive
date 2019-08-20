; Grabs the command line arguments (which live in %1%, %2%, etc) passed to the script, and puts them in a numeric array.
getScriptArgs(placeholderChar := "") {
	local paramsAry = [] ; This is the array that will hold the arguments at the end, which we'll return. Everything else (namely %1%, %2%, etc) are global.
	
	Loop, %0% { ; For each command line arg. %0% is the count of them.
		if(%A_Index% = placeholderChar) ; If a placeholder character is given, filter out values that match it (that index won't even be set).
			Continue
		paramsAry[A_Index] := %A_Index% ; %1% is the value of the first command line arg, etc.
	}
	
	return paramsAry
}

; Opens the given script in Notepad++.
editScript(script) {
	MainConfig.runProgram("Notepad++", script)
}

; Runs something and returns the result from standard out.
runReturn(command) {
	fullCommand := comspec . " /c """ . command . """"
	shell := comobjcreate("wscript.shell")
	exec := (shell.exec(fullCommand))
	stdout := exec.stdout.readall()
	return stdout
}

; Runs a command with cmd.exe.
runCommand(commandToRun := "", workingDirectory := "", stayOpen := false) {
	; Allow either an array or just a string.
	cmdString := ""
	if(commandToRun.MaxIndex()) {
		For _,command in commandToRun
			cmdString := cmdString.appendPiece(command, " ")
	} else {
		cmdString := commandToRun
	}
	
	; Set /C or /K (command and close, or command and stay up) based on input.
	if(!cmdString || stayOpen)
		runString := MainConfig.path["CMD"] " /K " cmdString
	else
		runString := MainConfig.path["CMD"] " /C " cmdString
	
	; DEBUG.popup("Command string", cmdString, "Run string", runString)
	Run(runString, workingDirectory)
}

; Run as a non-elevated user (since main script typically needs to run as admin).
runAsUser(path, args := "") {
	if(!FileExist(path)) {
		Toast.showError("Could not run path", "Does not exist: " path)
		return
	}
	
	ShellRun(path, args)
}

/*
	ShellRun by Lexikos
		requires: AutoHotkey_L
		license: http://creativecommons.org/publicdomain/zero/1.0/

	Credit for explaining this method goes to BrandonLive:
	http://brandonlive.com/2008/04/27/getting-the-shell-to-run-an-application-for-you-part-2-how/

	Shell.ShellExecute(File [, Arguments, Directory, Operation, Show])
	http://msdn.microsoft.com/en-us/library/windows/desktop/gg537745

	Function found here:
	https://autohotkey.com/board/topic/108434-run-ahk-as-admin-or-not-dilemma/#entry648428

	Parameters
		1 application to launch
		2 command line parameters
		3 working directory for the new process
		4 "Verb" (For example, pass "RunAs" to run as administrator)
		5 Suggestion to the application about how to show its window - see the msdn link for possible values
*/
ShellRun(prms*) {
	shellWindows := ComObjCreate("{9BA05972-F6A8-11CF-A442-00A0C90A8F39}")
	
	desktop := shellWindows.Item(ComObj(19, 8)) ; VT_UI4, SCW_DESKTOP
	
	; Retrieve top-level browser object.
	SID_STopLevelBrowser := "{4C96BE40-915C-11CF-99D3-00AA004AE837}"
	IID_IShellBrowser    := "{000214E2-0000-0000-C000-000000000046}"
	
	if(ptlb := ComObjQuery(desktop, SID_STopLevelBrowser, IID_IShellBrowser)) {
		; IShellBrowser.QueryActiveShellView -> IShellView
		if(DllCall(NumGet(NumGet(ptlb + 0) + 15 * A_PtrSize), "ptr", ptlb, "ptr*", psv := 0) = 0) {
			; Define IID_IDispatch.
			VarSetCapacity(IID_IDispatch, 16)
			NumPut(0x46000000000000C0, NumPut(0x20400, IID_IDispatch, "int64"), "int64")
			
			; IShellView.GetItemObject -> IDispatch (object which implements IShellFolderViewDual)
			DllCall(NumGet(NumGet(psv + 0) + 15 * A_PtrSize), "ptr", psv, "uint", 0, "ptr", &IID_IDispatch, "ptr*", pdisp := 0)
			
			; Get Shell object.
			shell := ComObj(9, pdisp, 1).Application
			
			; IShellDispatch2.ShellExecute
			shell.ShellExecute(prms*)
			
			ObjRelease(psv)
		}
		ObjRelease(ptlb)
	}
}
