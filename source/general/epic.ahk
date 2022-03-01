; Work-specific hotkeys

; Universal open of EMC2 objects from title.
; Note that some programs override this if they have special ways of providing the record string or INI/ID/title.
$!e::getEMC2ObjectFromCurrentTitle().openEdit()
$!w::getEMC2ObjectFromCurrentTitle().openWeb()
	getEMC2ObjectFromCurrentTitle() {
		; We have to check this directly instead of putting it under an #If directive, so that the various program-specific #If directives win.
		if(!Config.contextIsWork) {
			HotkeyLib.waitForRelease()
			Send, % A_ThisHotkey.removeFromStart("$")
			return ""
		}
		
		record := EpicLib.selectEMC2RecordFromText(WinGetTitle("A"))
		if(!record)
			return ""
		
		return new ActionObjectEMC2(record.id, record.ini)
	}

#If Config.contextIsWork ; Any work machine =--
	^!+d:: Send, % selectTLGId("Select EMC2 Record to Send").removeFromStart("P.").removeFromStart("Q.")
	^!#d:: selectTLGActionObject("Select EMC2 Record to View").openWeb()
	^!+#d::selectTLGActionObject("Select EMC2 Record to Edit").openEdit()
	selectTLGId(title) {
		s := new Selector("tlg.tls").setTitle(title).overrideFieldsOff()
		s.dataTableList.filterOutEmptyForColumn("RECORD")
		return s.selectGui("RECORD")
	}
	selectTLGActionObject(title) {
		recId := selectTLGId(title)
		if(!recId)
			return ""
		
		if(recId.startsWith("P.")) {
			recId := recId.removeFromStart("P.")
			recINI := "PRJ"
		} else if(recId.startsWith("Q.")) {
			recId := recId.removeFromStart("Q.")
			recINI := "QAN"
		} else {
			recINI := "DLG"
		}
		
		return new ActionObjectEMC2(recId, recINI)
	}
	
	^!+h::
		selectHyperspace() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch Hyperspace in Environment").selectGui()
			if(data)
				EpicLib.runHyperspace(data["VERSION"], data["COMM_ID"])
		}
	
	^!+i::
		selectEnvironmentId() {
			envId := new Selector("epicEnvironments.tls").selectGui("ENV_ID")
			if(envId) {
				Send, % envId
				Send, {Enter} ; Submit it too.
			}
		}
	
	^!#s::
		selectSnapper() {
			selectedText := SelectLib.getText()
			record := new EpicRecord().initFromRecordString(selectedText)
			
			; Don't include invalid INIs (anything that's not 3 characters)
			if(record.ini && record.ini.length() != 3)
				record := ""
			
			s := new Selector("epicEnvironments.tls").setTitle("Open Record(s) in Snapper in Environment")
			s.addOverrideFields(["INI", "ID"]).setDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in any values that we figured out
			data := s.selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				Config.runProgram("Snapper")
			else
				Snapper.addRecords(data["COMM_ID"], data["INI"], data["ID"]) ; data["ID"] can contain a list or range if that's what the user entered
		}
	
	; Turn clipboard into standard EMC2 string and send it.
	!+n::
		sendStandardEMC2ObjectString() {
			HotkeyLib.waitForRelease()
			
			record := EpicLib.selectEMC2RecordFromText(clipboard)
			if(!record)
				return
			ini   := record.ini
			id    := record.id
			title := record.title
			
			ClipboardLib.send(ini " " id " - " title) ; Can contain hotkey chars
			
			; Special case for OneNote: link the INI/ID as well.
			if(Config.isWindowActive("OneNote"))
				OneNote.linkEMC2ObjectInLine(ini, id)
		}
	
	; Pull EMC2 record IDs from currently open window titles and prompt the user to send one.
	^!i::
		sendEMC2RecordID() {
			record := EpicLib.selectEMC2RecordFromUsefulTitles()
			if(record)
				SendRaw, % record.id
		}

#If Config.machineIsWorkLaptop ; Main work laptop only (not other work machines) ---
	^!+t::
		selectOutlookTLG() {
			s := new Selector("tlg.tls").setTitle("Select EMC2 Record ID")
			s.dataTableList.filterByColumn("OLD", "") ; Filter out old records (have a value in the OLD column)
			data := s.selectGui()
			if(!data)
				return
			
			; We can do an additional Selector popup to grab ID (and potentially title) from various window titles.
			recId := data["RECORD"]
			if(recId = "GET") {
				record := EpicLib.selectEMC2RecordFromUsefulTitles()
				if(!record)
					return
				recId := record.id
				if(["PRJ", "QAN", "SLG"].contains(record.ini))
					recId := record.ini.charAt(1) "." recId ; Add on the INI prefix so the ID goes in the right position.
				
				if(record.title)
					data["NAME"] := record.title
			}
			
			; Message is a combination of a prefix, the name displayed in the Selector, and the user's entered message.
			fullName := data["NAME_OUTPUT_PREFIX"] data["NAME"]
			combinedMessage := fullName.appendPiece(data["MESSAGE"], " - ")
			
			; Record field can contain DLG (no prefix), PRJ (P.), QAN (Q.), or SLG (S.) IDs.
			if(recId.startsWith("P."))
				prjId := recId.removeFromStart("P.")
			else if(recId.startsWith("Q."))
				qanId := recId.removeFromStart("Q.")
			else if(recId.startsWith("S."))
				slgId := recId.removeFromStart("S.")
			else
				dlgId := recId
			
			textToSend := Config.private["OUTLOOK_TLG_BASE"]
			textToSend := textToSend.replaceTag("MESSAGE",  combinedMessage) ; Replace the message first in case it contains any of the following tags
			textToSend := textToSend.replaceTag("TLP",      data["TLP"])
			textToSend := textToSend.replaceTag("CUSTOMER", data["CUSTOMER"])
			textToSend := textToSend.replaceTag("SLG",      slgId)
			textToSend := textToSend.replaceTag("DLG",      dlgId)
			textToSend := textToSend.replaceTag("PRJ",      prjId)
			textToSend := textToSend.replaceTag("QAN",      qanId)
			
			if(Outlook.isTLGCalendarActive()) {
				SendRaw, % textToSend
				Send, {Enter}
			} else {
				ClipboardLib.setAndToastError(textToSend, "event string", "Outlook TLG calendar not focused.")
			}
		}
	
	^!+r::
		selectThunder() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch Thunder Environment").selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just show Thunder itself, don't launch an environment.
				Config.activateProgram("Thunder")
			else
				Config.runProgram("Thunder", data["THUNDER_ID"])
		}
	
	!+v::
		selectVDI() {
			data := new Selector("epicEnvironments.tls").setTitle("Launch VDI for Environment").selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") { ; Special keyword - just show VMWare itself, don't launch a specific VDI.
				Config.runProgram("VMware Horizon Client")
			} else {
				EpicLib.runVDI(data["VDI_ID"])
				
				; Also fake-maximize the window once it shows up.
				WinWaitActive, ahk_exe vmware-view.exe, , 10, VMware Horizon Client ; Ignore the loading-type popup that happens initially with excluded title.
				if(ErrorLevel) ; Set if we timed out or if somethign else went wrong.
					return
				
				monitorWorkArea := MonitorLib.getWorkAreaForWindow(titleString)
				new VisualWindow("A").resizeMove(VisualWindow.Width_Full, VisualWindow.Height_Full, VisualWindow.X_Centered, VisualWindow.Y_Centered)
			}
		}
	
	#p::
		selectPhone() {
			selectedText := SelectLib.getCleanFirstLine()
			
			if(PhoneLib.isValidNumber(selectedText)) {
				PhoneLib.call(selectedText)
			} else {
				data := new Selector("phone.tls").selectGui()
				if(data)
					PhoneLib.call(data["NUMBER"], data["NAME"])
			}
		}
#If ; --=
