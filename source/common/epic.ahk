; Epic-specific functions.

{ ; Epic Object-related things.
	
	getRelatedQANsAry() {
		if(!WinActive("DLG  ahk_class ThunderRT6MDIForm ahk_exe EpicD84.exe"))
			return ""
		if(!isWindowInState("active"," - EMC2","",2))
			return ""
		
		; Assuming you're in the first row of the table already.
		
		outAry := []
		Loop {
			Send, {End}
			Send, {Left}
			Send, {Ctrl Down}{Shift Down}
			Send, {Left}
			Send, {Ctrl Up}
			Send, {Right}
			Send, {Shift Up}
			
			qan := getSelectedText()
			if(!qan)
				break
			
			Send, {Tab}
			version := getSelectedText()
			
			; Avoid duplicate entries (for multiple versions
			if(qan != oldQAN)
				outAry.push(qan)
			
			; Loop quit condition - same QAN again (table ends on last filled row), also same version
			if( (qan = oldQAN) && (version = oldVersion) )
				break
			oldQAN     := qan
			oldVersion := version
			
			Send, +{Tab}
			Send, {Down}
		}
		
		return outAry
	}

	buildQANURLsAry(relatedQANsAry) {
		if(!relatedQANsAry)
			return ""
		
		urlsAry := []
		For i,qan in relatedQANsAry {
			link := ActionObject.do(qan, TYPE_EMC2, ACTION_Link, "QAN", SUBACTION_Web)
			if(link)
				urlsAry.push(link)
		}
		
		return urlsAry
	}
}

{ ; Phone-related functions.
	; Dials a given number using the Cisco WebDialer API.
	callNumber(formattedNum, name := "") {
		; Get the raw number (with leading digits as needed) to plug into the URL.
		rawNum := parsePhone(formattedNum)
		if(!rawNum) {
			MsgBox, % "Invalid phone number."
			return
		}
		
		; Confirm the user wants to call.
		if(!userWantsToCall(formattedNum, rawNum, name))
			return
		
		; Build the URL.
		url := getDialerURL(rawNum)
		if(!url)
			return
		
		; Dial with a web request.
		HTTPRequest(url, In := "", Out := "")
		; DEBUG.popup("callNumber","Finish", "Input",formattedNum, "Raw number",rawNum, "Name",name, "URL",url)
	}
	
	userWantsToCall(formattedNum, rawNum, name := "") {
		if(!formattedNum || !rawNum)
			return false
		
		if(formattedNum = "HANGUP") {
			title          := "Hang up?"
			messageText    := "Hanging up current call. `n`nContinue?"
		} else {
			title          := "Dial number?"
			messageText    := "Calling: `n`n"
			if(name)
				messageText .= name "`n"
			messageText    .= formattedNum "`n"
			messageText    .= "[" rawNum "] `n`n"
			messageText    .= "Continue?"
		}
		
		MsgBox, % MSGBOX_BUTTONS_YES_NO, % title, % messageText
		IfMsgBox Yes
			return true
		return false
	}
	
	; Generates a Cisco WebDialer URL to call a number.
	getDialerURL(rawNum) {
		if(!rawNum)
			return ""
		
		if(rawNum = "HANGUP")
			command := "HangUpCall?"
		else
			command := "CallNumber?extension=" rawNum
		
		return replaceTag(MainConfig.getPrivate("CISCO_PHONE_BASE"), "COMMAND", command)
	}
}

; Launches a routine in EpicStudio (and focuses a specific tag if given).
openEpicStudioRoutine(routine, tag := "") {
	if(!routine)
		return
	
	; Open routine in EpicStudio, wait until it's open
	Run(MainConfig.getProgram("EpicStudio", "PATH") " " routine "|93") ; ROUTINE|ENVIRONMENT_ID
	exeName := MainConfig.getProgram("EpicStudio", "EXE")
	WinWaitActive, %routine% ahk_exe %exeName%
	
	; Focus correct tag if given.
	if(tag) {
		Send, ^+o
		WinWaitActive, Go To
		SendRaw, %tag%
		Send, {Enter}
	}
}

; Split "INI ID" string into INI and ID (assume it's just the ID if no space included)
splitRecordString(recordString, ByRef ini := "", ByRef id := "") {
	recordString := cleanupText(recordString)
	recordPartsAry := StrSplit(recordString, " ")
	
	maxIndex := recordPartsAry.MaxIndex()
	if(maxIndex > 1)
		ini := recordPartsAry[1]
	id := recordPartsAry[maxIndex] ; Always the last piece (works whether there was an INI before it or not)
}

; Split serverLocation into routine and tag (assume it's just the routine if no ^ included)
splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
	serverLocation := cleanupText(serverLocation, ["$", "(", ")"])
	locationAry := StrSplit(serverLocation, "^")
	
	maxIndex := locationAry.MaxIndex()
	if(maxIndex > 1)
		tag := locationAry[1]
	routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
}

openEpicStudioDLG(dlgNum) {
	activateProgram("EpicStudio")
	exeName := MainConfig.getProgram("EpicStudio", "EXE")
	WinWaitActive, ahk_exe %exeName%
	
	Send, ^!e
	WinWaitActive, Open DLG
	
	Send, ^a
	Send, {Delete} ; Make sure the DLG that defaults in it cleared before we add our own.
	Send, % dlgNum
	Send, {Enter 2}
}

getEpicAppIdFromKey(appKey) {
	if(!appKey)
		return 0
	return MainConfig.getPrivate("CS_APP_ID_" appKey)
}

buildEMC2Link(ini, id, subAction := "WEB") { ; subAction = SUBACTION_Web
	global SUBACTION_Edit, SUBACTION_View, SUBACTION_Web
	if(!ini || !id)
		return ""
	
	; View basically goes one way or the other depending on INI:
	;  * If it can be viewed in EMC2, use EDIT with a special view-only parameter.
	;  * Otherwise, create a web link instead.
	if(subAction = SUBACTION_View) {
		if(canViewINIInEMC2(ini)) {
			subAction   := SUBACTION_Edit
			paramString := "&runparams=1"
		} else {
			subAction   := SUBACTION_Web
		}
	}
	
	; Pick one of the types of links - edit in EMC2, web summary or Sherlock.
	if(subAction = SUBACTION_Edit) {
		link := MainConfig.getPrivate("EMC2_LINK_BASE")
	} else if(subAction = SUBACTION_Web) {
		if(isSherlockINI(ini))
			link := MainConfig.getPrivate("SHERLOCK_BASE")
		else
			link := MainConfig.getPrivate("EMC2_LINK_WEB_BASE")
	}
	
	link .= paramString
	link := replaceTags(link, {"INI":ini, "ID":id})
	
	return link
}
canViewINIInEMC2(ini) {
	if(!ini)
		return false
	
	if(ini = "DLG")
		return true
	if( (ini = "QAN") || (ini = "ZQN") )
		return true
	if(ini = "XDS")
		return true
	
	return false
}
isSherlockINI(ini) {
	if(!ini)
		return false
	
	if(ini = "SLG")
		return true
	
	return false
}

buildHyperspaceRunString(versionMajor, versionMinor, environment) {
	runString := MainConfig.getPrivate("HYPERSPACE_BASE")
	
	; Handling for 2010 special path.
	if(versionMajor = 7 && versionMinor = 8)
		runString := replaceTag(runString, "EPICNAME", "EpicSys")
	else
		runString := replaceTag(runString, "EPICNAME", "Epic")
	
	; Versioning and environment.
	runString := replaceTags(runString, {"MAJOR":versionMajor, "MINOR":versionMinor, "ENVIRONMENT":environment})
	
	; DEBUG.popup("Start string", tempRun, "Finished string", runString, "Major", versionMajor, "Minor", versionMinor, "Environment", environment)
	return runString
}

buildCodeSearchURL(searchType, searchTerm, appKey := "") {
	appId := getEpicAppIdFromKey(appKey)
	; DEBUG.popup("buildCodeSearchURL", "Start", "Search type", searchType, "Search term", searchTerm, "App key", appKey, "App ID", appId)
	
	; Gotta have something to search for (and a type) to run a search.
	if(!searchTerm || !searchType)
		return ""
	
	criteriaString := "a=" searchTerm
	return replaceTags(MainConfig.getPrivate("CS_BASE"), {"SEARCH_TYPE":searchType, "APP_ID":appId, "CRITERIA":criteriaString})
}

buildGuruURL(searchTerm) {
	return MainConfig.getPrivate("GURU_SEARCH_BASE") searchTerm
}

buildEpicWikiSearchURL(category, searchTerm) {
	outURL := MainConfig.getPrivate("WIKI_SEARCH_BASE")
	outURL := replaceTag(outURL, "QUERY", searchTerm)
	
	if(category) {
		category := "'" category "'"
		outURL .= MainConfig.getPrivate("WIKI_SEARCH_FILTERS")
		outURL := replaceTag(outURL, "CATEGORIES", category)
	}
	
	return outURL
}

; ini/id defaults are "X" as a dummy - URL will still connect to desired environment (and show an error popup).
buildSnapperURL(environment := "", ini := "", idList := "") { ; idList is a comma-separated list of IDs
	if(!environment)
		environment := getCurrentSnapperEnvironment() ; Try to default from what Snapper has open right now if no environment given.
	if(!environment)
		return ""
	
	if(!ini && !id) { ; These aren't be parameter defaults in case of blank parameters (not simply not passed at all)
		ini    := "X"
		idList := "X"
	}
	
	if(stringContains(idList, ","))
		idAry := StrSplit(idList, ",")
	else
		idAry := [idList]
	
	outURL := MainConfig.getPrivate("SNAPPER_URL_BASE")
	For i,id in idAry {
		; DEBUG.popup("Index", i, "ID", id)
		if(!id)
			Continue
		
		outURL .= ini "." id "." environment "/"
	}
	
	return outURL
}

buildVDIRunString(vdiId) {
	return replaceTag(MainConfig.getPrivate("VDI_BASE"), "VDI_ID", vdiId)
}

buildServerCodeLink(serverLocation) {
	splitServerLocation(serverLocation, routine, tag)
	
	url := MainConfig.getPrivate("CS_SERVER_CODE_BASE")
	url := replaceTag(url, "ROUTINE", routine)
	url := replaceTag(url, "TAG", tag)
	
	; DEBUG.popup("epic","buildServerCodeLink", "Server location",serverLocation, "Tag",tag, "Routine",routine, "URL",url)
	return url
}

buildHelpdeskLink(hdrId) {
	return replaceTag(MainConfig.getPrivate("HELPDESK_BASE"), "ID", hdrId)
}

getCurrentSnapperEnvironment() {
	snapperTitleString := "Snapper ahk_exe Snapper.exe"
	if(!WinExist(snapperTitleString))
		return ""
	
	environmentText := ControlGetText("ThunderRT6ComboBox2", snapperTitleString)
	commId := getStringBetweenStr(environmentText, "[", "]")
	
	return commId
}

; line - title of EMC2 email, or title from top of web view.
extractEMC2ObjectInfo(line) {
	infoAry := extractEMC2ObjectInfoRaw(line)
	return processEMC2ObjectInfo(infoAry)
}
extractEMC2ObjectInfoRaw(line) {
	line := cleanupText(line, ["["]) ; Remove any odd leading/trailing characters (and also remove open brackets)
	
	; INI is first characters up to the first delimiter
	if(isAlpha(subStr(line, 1, 1))) { ; Make sure we're starting with an INI (instead of an ID) by checking whether the first character is a letter (not a number).
		delimPos := stringMatchesAnyOf(line, [" ", "#"])
		ini  := subStr(line, 1, delimPos - 1)
		line := subStr(line, delimPos + 1) ; +1 to drop delimiter too
	}
	
	; ID is remaining up to the next delimiter
	delimPos := stringMatchesAnyOf(line, [":", "-", "]"])
	id := subStr(line, 1, delimPos - 1)
	line := subStr(line, delimPos + 1) ; +1 to drop delimiter too
	
	; Title is everything left
	title := line
	
	return {"INI":ini, "ID":id, "TITLE":title}
}
processEMC2ObjectInfo(infoAry) {
	ini   := infoAry["INI"]
	id    := infoAry["ID"]
	title := infoAry["TITLE"]
	
	; INI
	s := new Selector("actionObject.tl")
	if(ini) ; Turn any not-really-ini strings (like "Design") into actual INI
		ini := s.selectChoice(ini, "SUBTYPE")
	else    ; If no INI found at all, ask the user for it
		ini := s.selectGui("SUBTYPE", "", "", true)
	if(!ini)
		return ""
	
	; ID
	id := cleanupText(id)
	
	; Title
	stringsToRemove := ["-", "/", "\", ":", "(Developer has reset your status)", "(Stage 1 QAer is Waiting for Changes)", "(Stage 2 QAer is Waiting for Changes)"] ; Odd characters and non-useful strings that should come off
	title := cleanupText(title, stringsToRemove)
	title := removeStringFromStart(title, "DBC") ; Drop from start - most of my DLGs are DBC, no reason to include that.
	title := cleanupText(title, stringsToRemove) ; Remove anything that might have been after the "DBC"
	if(ini = "SLG") {
		; "--Assigned to: USER" might be on the end for SLGs - trim it off.
		title := getStringBeforeStr(title, "--Assigned To:")
	}
	
	return {"INI":ini, "ID":id, "TITLE":title}
}

; Returns standard string for OneNote use.
buildStandardEMC2ObjectString(ini, id, title) {
	return ini " " id " - " title
}

; Turn descriptors that aren't real INIs (like "Design") into the corresponding INI.
getTrueINI(iniString) {
	if(!iniString)
		return ""
	
	s := new Selector("actionObject.tl")
	return s.selectChoice(iniString, "SUBTYPE")
}


getEMC2Info(ByRef ini := "", ByRef id := "", titleString := "A") {
	title := WinGetTitle(titleString)
	title := removeStringFromEnd(title, " - EMC2")
	
	; If no info available, finish here.
	if((title = "") or (title = "EMC2"))
		return
	
	; Split the input.
	splitRecordString(title, ini, id)
	; DEBUG.popup("getEMC2Info","Finish", "INI",ini, "ID",id)
}
