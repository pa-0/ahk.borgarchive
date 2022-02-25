; Various Epic utility functions.

class EpicLib {
	; #PUBLIC#
	
	;---------
	; DESCRIPTION:    Run Hyperspace locally for the given version and environment.
	; PARAMETERS:
	;  version     (I,REQ) - Dotted Hyperspace version
	;  environment (I,OPT) - EpicComm ID for the environment to connect to.
	;---------
	runHyperspace(version, environment) {
		Run(Config.private["HYPERSPACE_BASE"].replaceTags({"VERSION":version, "VERSION_FLAT": version.remove(".") , "ENVIRONMENT":environment}))
	}
	
	;---------
	; DESCRIPTION:    Open a VDI matching the given ID.
	; PARAMETERS:
	;  vdiId (I,REQ) - The ID of the VDI to open.
	;---------
	runVDI(vdiId) {
		Run(Config.private["VDI_BASE"].replaceTag("VDI_ID", vdiId))
	}
	
	;---------
	; DESCRIPTION:    Split the given server location into tag and routine.
	; PARAMETERS:
	;  serverLocation (I,REQ) - The location in server code to split.
	;  routine        (O,OPT) - The routine
	;  tag            (O,OPT) - The tag. May include offset, see notes below.
	; NOTES:          Any offset from a tag will be included in the tag return value (i.e.
	;                 TAG+3^ROUTINE splits into routine=ROUTINE and tag=TAG+3).
	;---------
	splitServerLocation(serverLocation, ByRef routine := "", ByRef tag := "") {
		serverLocation := serverLocation.clean(["$", "(", ")"])
		locationAry := serverLocation.split("^")
		
		maxIndex := locationAry.MaxIndex()
		if(maxIndex > 1)
			tag := locationAry[1]
		routine := locationAry[maxIndex] ; Always the last piece (works whether there was a tag before it or not)
	}
	
	;---------
	; DESCRIPTION:    Drop the offset ("+4" in "tag+4^routine", can also be negative) from the
	;                 given server (so we'd return "tag^routine").
	; PARAMETERS:
	;  serverLocation (I,REQ) - The server location to drop the offset from.
	; RETURNS:        The updated server code location.
	;---------
	dropOffsetFromServerLocation(serverLocation) {
		this.splitServerLocation(serverLocation, routine, tag)
		tag := tag.beforeString("+").beforeString("-")
		return tag "^" routine
	}
	
	;---------
	; DESCRIPTION:    Given a file path, convert it to a "source-relative" path - that is, the relative path between the
	;                 source root folder (DLG-* or App *) and the given location.
	; PARAMETERS:
	;  path (I,REQ) - The path to convert.
	; RETURNS:        Relative path with leading backslash.
	;---------
	convertToSourceRelativePath(path) {
		path := FileLib.cleanupPath(path)
		
		sourceRoot := Config.path["EPIC_SOURCE_CURRENT"] "\"
		if(!path.startsWith(sourceRoot)) {
			ClipboardLib.setAndToastError(path, "path", "Could not copy source-relative path", "Path is not in source root")
			return ""
		}
		path := path.removeFromStart(sourceRoot)
		
		; Strip off one more parent - it's either one of the main folders (App *) or a DLG folder (DLG-*)
		path := "\" path.afterString("\") ; Keep the leading backslash
		
		return path
	}
	
	;---------
	; DESCRIPTION:    Find the source folder of the current version, by looking for the biggest version number we have a
	;                 folder for.
	; RETURNS:        Full path to the current version's source folder (no trailing backslash).
	;---------
	findCurrentVersionSourceFolder() {
		latestVersion := 0.0
		latestPath := ""
		
		Loop, Files, C:\EpicSource\*, D
		{
			; Only consider #[#].# folders
			if(!A_LoopFileName.matchesRegEx("\d{1,2}\.\d"))
				Continue
			
			if(A_LoopFileName > latestVersion) {
				latestVersion := A_LoopFileName
				latestPath := A_LoopFileLongPath
			}
		}
		
		return latestPath
	}
	
	;---------
	; DESCRIPTION:    Finds the current path to the latest installed version of EMC2.
	; RETURNS:        Full filepath (including the EpicD*.exe) for the latest installed version of EMC2.
	;---------
	findCurrentEMC2Path() {
		latestVersion := 0.0
		latestEMC2Folder := ""
		
		Loop, Files, C:\Program Files (x86)\Epic\v*.*, D
		{
			; Only consider versions where there's an EMC2 directory
			if(!FileLib.folderExists(A_LoopFileLongPath "\EMC2"))
				Continue
			
			version := A_LoopFileName.removeFromStart("v")
			if(version > latestVersion) {
				latestVersion := version
				latestEMC2Folder := A_LoopFileLongPath "\EMC2"
			}
		}
			
		return latestEMC2Folder "\Shared Files\EpicD" latestVersion.remove(".") ".exe"
	}
	
	;---------
	; DESCRIPTION:    Check whether the given string COULD be an EMC2 record ID - these are numeric except for SUs and TDE
	;                 logs, which start with I and T respectively.
	; PARAMETERS:
	;  id (I,REQ) - Possible ID to evaluate.
	; RETURNS:        true if possibly an ID, false otherwise.
	;---------
	couldBeEMC2ID(id) {
		; For SU DLG IDs, trim off leading letter so we recognize them as a numeric ID.
		if(id.startsWithAnyOf(["I", "T"], letter))
			id := id.removeFromStart(letter)
		
		return id.isNum()
	}
	
	
	couldBeEMC2Record(ByRef ini, id) { ; Checks whether this is PLAUSIBLY an EMC2 INI/ID, based on INI and ID format - no guarantee that it exists. Also converts INI to "proper" one.
		; Need both INI and ID.
		if(ini = "" || id = "")
			return false
		
		; ID format check
		if(!this.couldBeEMC2ID(id))
			return false
		
		; INI check
		tempINI := this.convertToUsefulEMC2INI(ini)
		if(tempINI = "")
			return false
		
		ini := tempINI ; Return "proper" INI
		return true
	}
	
	;---------
	; DESCRIPTION:    Convert the given "INI" into the useful version of itself.
	; PARAMETERS:
	;  ini (I,REQ) - The ini to convert, can be any of:
	;                 - Normal INI (DLG, zdq)
	;                 - Special INI that we want a different version of (ZQN => QAN)
	;                 - Word that describes an INI (Design, log, development log)
	; RETURNS:        The useful form of the INI, or "" if we couldn't match the input to one.
	;---------
	convertToUsefulEMC2INI(ini) {
		; Don't allow numeric "INIs" - they're just picking choices from the Selector, not converting a valid value.
		if(ini.isNum())
			return ""
		
		s := this.getEMC2TypeSelector()
		return s.selectChoice(ini, "SUBTYPE") ; Silent selection - no popup.
	}
	
	
	getBestEMC2RecordFromTitle(title) {
		this.extractEMC2RecordsFromTitle(title, exacts, possibles)
		
		; Return the first exact match, then the first possible match.
		return DataLib.coalesce(exacts[1], possibles[1])
	}
	
	
	selectEMC2RecordFromTitle(title) {
		if(!this.extractEMC2RecordsFromTitle(title, exacts, possibles)) {
			; No matches at all
			Toast.ShowError("No potential EMC2 record IDs found in window title: " title)
			return ""
		}
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(exacts.length() = 1)
			return exacts[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(exacts, possibles)
		if(!data) ; User didn't pick an option
			return ""
		
		ini := this.convertToUsefulEMC2INI(data["INI"]) ; GDB TODO probably move this and the conversion to EpicRecord into selectFromEMC2RecordMatches()
		return new EpicRecord(ini, data["ID"], data["TITLE"])
	}
	
	
	selectEMC2RecordFromUsefulTitles() {
		titles := this.getUsefulEMC2RecordWindows()
		; Debug.popup("titles",titles)
		
		allExacts    := []
		allPossibles := []
		For windowName,title in titles {
			if(this.extractEMC2RecordsFromTitle(title, exacts, possibles, windowName)) {
				allExacts.appendArray(exacts)
				allPossibles.appendArray(possibles)
			}
		}
		Debug.popup("allExacts",allExacts, "allPossibles",allPossibles)
		
		; No exacts or possibles
		if(allExacts.length() + allPossibles.length() = 0) {
			Toast.ShowError("No potential EMC2 record IDs found.")
			return ""
		}
		
		; Only 1 exact match, just return it directly (ignoring any possibles).
		if(allExacts.length() = 1)
			return allExacts[1]
		
		; Prompt the user (even if there's just 1 possible, this gives them the opportunity to enter the INI)
		data := this.selectFromEMC2RecordMatches(allExacts, allPossibles)
		if(!data) ; User didn't pick an option
			return ""
		
		ini := this.convertToUsefulEMC2INI(data["INI"])
		return new EpicRecord(ini, data["ID"], data["TITLE"])
	}
	
	
	; #PRIVATE#
	
	emc2TypeSelector := "" ; Selector instance (performance cache)
	
	;---------
	; DESCRIPTION:    Get a Selector instance you can use to map various INI-like strings to actual EMC2 INIs.
	; RETURNS:        Selector instance
	;---------
	getEMC2TypeSelector() {
		if(this.emc2TypeSelector)
			return this.emc2TypeSelector
		
		; Use ActionObject's TLS (filtered to EMC2-type types) for mapping INIs
		s := new Selector("actionObject.tls")
		s.dataTableList.filterByColumn("TYPE", ActionObject.Type_EMC2)
		
		this.emc2TypeSelector := s ; Cache for future use
		
		return s
	}
	
	
	getUsefulEMC2RecordWindows() {
		titles := {} ; {windowName: title}
		
		; Normal titles
		For _,windowName in ["EMC2", "EpicStudio", "Visual Studio", "Explorer"]
			titles[windowName] := Config.windowInfo[windowName].getCurrTitle()
		
		; Special "titles" extracted from inside the window(s)
		For i,title in Outlook.getAllMessageTitles() ; Outlook message titles
			titles["Outlook " i] := title ; GDB TODO store the windowName at the title level somehow so titles doesn't have to be associative and we don't need this counter.
		titles["VB6"] := "DLG " VB6.getDLGIdFromProject() ; VB6 (sidebar title from project group)
		
		return titles
	}
	
	
	extractEMC2RecordsFromTitle(title, ByRef exacts := "", ByRef possibles := "", windowName := "") {
		exacts    := []
		possibles := []
		
		; Make sure the title is in a decent state to be parsed.
		title := title.clean()
		
		; First, give EpicRecord's parsing logic a shot - since most titles are close to this format, it gives us the best chance at a nicer title.
		record := new EpicRecord().initFromRecordString(title)
		if(this.couldBeEMC2Record(record.ini, record.id)) {
			record.label := windowName
			exacts.push(record)
		}
		
		; Split up the title and look for potential IDs.
		delims := [" ", ",", "-", "(", ")", "[", "]", "/", "\", ":", ".", "#"]
		titleBits := title.split(delims, " ").removeEmpties()
		For i,id in titleBits {
			; Extract other potential info
			ini := titleBits[i - 1] ; INI is assumed to be the piece just before the ID.
			; Title is the whole string, sans INI & ID (for a hopefully nicer title).
			iniAndID := ini title.firstBetweenStrings(ini, id) id
			recordTitle := title.remove(iniAndID).clean(delims)
			
			; Match: Valid INI + ID.
			if(this.couldBeEMC2Record(ini, id)) {
				exacts.push(new EpicRecord(ini, id, recordTitle, windowName))
				Continue
			}
			
			; Possible: ID has potential, but no valid INI.
			if(this.couldBeEMC2ID(id))
				possibles.push(new EpicRecord("", id, recordTitle, windowName))
		}
		
		; origExacts := exacts.clone() ; GDB TODO remove
		; origPossibles := possibles.clone()
		
		; GDB TODO consider handling these two with a Functor object approach - a DataLib function for removing duplicates, and a reference to a function that returns whether/which element to remove.
		; Remove duplicate entries.
		For i,exact1 in exacts.clone() {
			For j,exact2 in exacts.clone() {
				; Same element.
				if(i = j)
					Continue
				
				if(exact1.id = exact2.id) {
					; If the titles (or title lengths) match too, just drop the later one.
					if(exact1.title = exact2.title || exact1.title.length() = exact2.title.length())
						exacts.delete(max(i, j))
					
					; Otherwise, keep the one with the shorter (and presumably nicer) title.
					else if(exact1.title.length() > exact2.title.length())
						exacts.delete(j)
					else
						exacts.delete(i)
				}
			}
		}
		; Filter out possibles for IDs we already have in exacts.
		For _,exact in exacts.clone() {
			For j,possible in possibles.clone() {
				if(exact.id = possible.id)
					possibles.delete(j)
			}
		}
		; Debug.popup("titleBits",titleBits, "origExacts",origExacts, "origPossibles",origPossibles, "exacts",exacts, "possibles",possibles)
		
		; Debug.popup("titleBits",titleBits, "exacts",exacts, "possibles",possibles)
		return (exacts.length() + possibles.length()) > 0
	}
	
	;---------
	; DESCRIPTION:    Build a Selector and ask the user to pick from the matches we found.
	; PARAMETERS:
	;  exacts   (I,REQ) - Associative array of confirmed EpicRecord objects, from getMatchesFromTitles.
	;  possibles (I,REQ) - Associative array of potential EpicRecord objects, from getMatchesFromTitles.
	; RETURNS:        Data array from Selector.selectGui().
	;---------
	selectFromEMC2RecordMatches(exacts, possibles) {
		s := new Selector().setTitle("Select EMC2 Object to use:").addOverrideFields({1:"INI"})
		
		abbrevNums := {} ; {letter: lastUsedNumber}
		s.addSectionHeader("Full matches")
		For _,record in exacts
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbrevNums))
		
		s.addSectionHeader("Potential IDs")
		For _,record in possibles
			s.addChoice(this.buildChoiceFromEMC2Record(record, abbrevNums))
		
		return s.selectGui()
	}
	
	;---------
	; DESCRIPTION:    Turn the provided EpicRecord object into a SelectorChoice to show to the user.
	; PARAMETERS:
	;  record      (I,REQ) - EpicRecord object to use.
	;  abbrevNums (IO,REQ) - Associative array of abbreviation letters to counts, used to generate unique abbreviations. {letter: lastUsedNumber}
	; RETURNS:        SelectorChoice instance describing the provided record.
	;---------
	buildChoiceFromEMC2Record(record, ByRef abbrevNums) {
		ini        := record.ini
		id         := record.id
		title      := record.title
		windowName := record.label
		
		name := ""
		if(windowName)
			name .= windowName " - "
		if(ini)
			name .= ini " "
		name .= id
		if(title)
			name .= " - " title
		
		; Abbreviation is INI first letter + a counter.
		if(ini = "")
			abbrevLetter := "u" ; Unknown INI
		else
			abbrevLetter := StringLower(ini.charAt(1))
		abbrevNum := DataLib.forceNumber(abbrevNums[abbrevLetter]) + 1
		abbrevNums[abbrevLetter] := abbrevNum
		abbrev := abbrevLetter abbrevNum
		
		return new SelectorChoice({NAME:name, ABBREV:abbrev, INI:ini, ID:id, TITLE:title})
	}
	; #END#
}


