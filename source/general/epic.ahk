; Work-specific hotkeys

#If Config.contextIsWork ; Any work machine --=
	^!+d:: Send, % selectTLGId().removeFromStart("P.").removeFromStart("Q.")
	^!#d:: selectTLGActionObject().openWeb()
	^!+#d::selectTLGActionObject().openEdit()
	selectTLGId() {
		s := new Selector("tlg.tls").setTitle("Select EMC2 Record ID").overrideFieldsOff()
		s.dataTableList.filterOutEmptyForColumn("RECORD")
		return s.selectGui("RECORD")
	}
	selectTLGActionObject() {
		recId := selectTLGId()
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
				EpicLib.runHyperspace(data["MAJOR"], data["MINOR"], data["COMM_ID"])
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
			record := new EpicRecord(SelectLib.getText())
			
			s := new Selector("epicEnvironments.tls").setTitle("Open Record(s) in Snapper in Environment")
			s.addOverrideFields(["INI", "ID"]).setDefaultOverrides({"INI":record.ini, "ID":record.id}) ; Add fields for INI/ID and default in any values that we figured out
			data := s.selectGui()
			if(!data)
				return
			
			if(data["COMM_ID"] = "LAUNCH") ; Special keyword - just launch Snapper, not any specific environment.
				Config.runProgram("Snapper")
			else
				Run(Snapper.buildURL(data["COMM_ID"], data["INI"], data["ID"])) ; data["ID"] can contain a list or range if that's what the user entered
		}

#If Config.machineIsWorkLaptop ; Main work laptop only (not other work machines) ===
	^!+t::
		selectOutlookTLG() {
			s := new Selector("tlg.tls").setTitle("Select EMC2 Record ID")
			s.dataTableList.filterByColumn("OLD", "") ; Filter out old records (have a value in the OLD column)
			data := s.selectGui()
			if(!data)
				return
			
			fullName := data["NAME_OUTPUT_PREFIX"] data["NAME"]
			combinedMessage := fullName.appendPiece(data["MESSAGE"], " - ")
			
			; Record field can contain DLG (no prefix), PRJ (P. prefix), or QAN (Q. prefix) IDs.
			recId := data["RECORD"]
			if(recId.startsWith("P."))
				prjId := recId.removeFromStart("P.")
			else if(recId.startsWith("Q."))
				qanId := recId.removeFromStart("Q.")
			else
				dlgId := recId
			
			textToSend := Config.private["OUTLOOK_TLG_BASE"]
			textToSend := textToSend.replaceTag("TLP",      data["TLP"])
			textToSend := textToSend.replaceTag("CUSTOMER", data["CUSTOMER"])
			textToSend := textToSend.replaceTag("DLG",      dlgId)
			textToSend := textToSend.replaceTag("PRJ",      prjId)
			textToSend := textToSend.replaceTag("QAN",      qanId)
			textToSend := textToSend.replaceTag("MESSAGE",  combinedMessage)
			
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
				
				monitorWorkArea := WindowLib.getMonitorWorkAreaForWindow(titleString)
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
#If ; =--
