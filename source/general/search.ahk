; Search hotkeys and tools.

; Generic search for selected text.
!+f::
	selectSearch() {
		text := getFirstLineOfSelectedText().clean()
		
		s := new Selector("search.tls", MainConfig.contextSelectorFilter)
		data := s.selectGui("", "", {"SEARCH_TERM":text})
		if(!data)
			return
		
		searchTerm := data["SEARCH_TERM"]
		if(searchTerm = "")
			return
		
		subTypesAry := forceArray(data["SUBTYPE"]) ; Force it to be an array - sometimes it is, sometimes it isn't.
		For _,subType in subTypesAry { ; For searching multiple at once.
			url := ""
			
			if(data["SEARCH_TYPE"] = "WEB")
				url := StrReplace(subType, "%s", escapeForRunURL(searchTerm))
			else if(data["SEARCH_TYPE"] = "CODESEARCH")
				url := buildCodeSearchURL(searchTerm, subType, data["APP_KEY"])
			else if(data["SEARCH_TYPE"] = "GURU")
				url := buildGuruSearchURL(searchTerm)
			else if(data["SEARCH_TYPE"] = "WIKI") ; Epic wiki search.
				url := buildEpicWikiSearchURL(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "GREPWIN")
				searchWithGrepWin(searchTerm, subType)
			else if(data["SEARCH_TYPE"] = "EVERYTHING")
				searchWithEverything(searchTerm)
			
			if(url)
				Run(url)
		}
	}


;---------
; DESCRIPTION:    Build a CodeSearch URL for the given search term, type, and app.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;  searchType (I,REQ) - Type of search, from: Server, Client, Records, ProgPoint
;  appKey     (I,OPT) - App key (goes on the end of CS_APP_ID_ for a private value) to search only
;                       within that app's code. Defaults to all apps (no filter).
; RETURNS:        CodeSearch URL for the given parameters.
;---------
buildCodeSearchURL(searchTerm, searchType, appKey := "") {
	if(!searchType) ; Gotta know w here to search.
		return ""
	
	searchTerm := escapeForRunURL(searchTerm)
	
	url := MainConfig.private["CS_BASE"]
	url := replaceTag(url, "SEARCH_TYPE", searchType)
	url := replaceTag(url, "APP_ID",      getEpicAppIdFromKey(appKey))
	url := replaceTag(url, "CRITERIA",    "a=" searchTerm)
	
	return url
}

;---------
; DESCRIPTION:    Turn the given app key into its numeric ID for CodeSearch.
; PARAMETERS:
;  appKey (I,REQ) - App key (goes on the end of CS_APP_ID_ for a private value).
; RETURNS:        The numeric ID for the given app, 0 if no match (including blank appKey).
;---------
getEpicAppIdFromKey(appKey) {
	if(appKey = "")
		return 0
	return MainConfig.private["CS_APP_ID_" appKey]
}

;---------
; DESCRIPTION:    Build a Guru search URL for the given text.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
; RETURNS:        Guru URL to search for the given text.
;---------
buildGuruSearchURL(searchTerm) {
	searchTerm := escapeForRunURL(searchTerm)
	return MainConfig.private["GURU_SEARCH_BASE"] searchTerm
}

;---------
; DESCRIPTION:    Build an Epic wiki search URL.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;  category   (I,OPT) - Category to restrict search results to within the wiki.
; RETURNS:        Wiki search URL for the given text, filtered by category if given.
;---------
buildEpicWikiSearchURL(searchTerm, category := "") {
	searchTerm := escapeForRunURL(searchTerm)
	
	url := MainConfig.private["WIKI_SEARCH_BASE"]
	url := replaceTag(url, "QUERY", searchTerm)
	
	if(category) {
		filters := MainConfig.private["WIKI_SEARCH_FILTERS"]
		filters := replaceTag(filters, "CATEGORIES", "'" category "'")
		url .= filters
	}
	
	return url
}

;---------
; DESCRIPTION:    Run a search with grepWin in the given path.
; PARAMETERS:
;  searchTerm   (I,REQ) - Text to search for.
;  pathToSearch (I,REQ) - Where to search files for the given term.
;---------
searchWithGrepWin(searchTerm, pathToSearch) {
	args := "/regex:no"
	args .= " /searchpath:" DOUBLE_QUOTE MainConfig.replacePathTags(pathToSearch) " "    DOUBLE_QUOTE ; Extra space after path, otherwise trailing backslash escapes ending double quote
	args .= " /searchfor:"  DOUBLE_QUOTE escapeCharUsingChar(searchTerm, DOUBLE_QUOTE) DOUBLE_QUOTE ; Escape any quotes in the search string
	args .= " /execute" ; Run it immediately if we got what to search for
	
	; DEBUG.popup("Path to search",pathToSearch, "To search",searchTerm, "Args",args)
	MainConfig.runProgram("GrepWin", args)
}

;---------
; DESCRIPTION:    Run a search with Everything.
; PARAMETERS:
;  searchTerm (I,REQ) - Text to search for.
;---------
searchWithEverything(searchTerm) {
	MainConfig.runProgram("Everything", "-search " searchTerm)
}
