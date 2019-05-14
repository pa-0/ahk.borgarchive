; note to self: this must be in UTF-8 encoding.

#If !MainConfig.windowIsGame()
{ ; Emails.
	:X:emaila::Send,  % MainConfig.private["EMAIL"]
	:X:gemaila::Send, % MainConfig.private["EMAIL_2"]
	:X:eemaila::Send, % MainConfig.private["WORK_EMAIL"]
	:X:oemaila::Send, % MainConfig.private["OUTLOOK_EMAIL"]
}

{ ; Addresses.
	:X:waddr::SendRaw, % MainConfig.private["HOME_ADDRESS"]
	:X:eaddr::Send, % MainConfig.private["WORK_ADDRESS"]
	:*0X:ezip::Send, % MainConfig.private["WORK_ZIP_CODE"]
}

{ ; Logins.
	:X:uname::Send, % MainConfig.private["USERNAME"]
}

{ ; Phone numbers.
	:X:phoneno::Send, % MainConfig.private["PHONE_NUM"]
	:X:fphoneno::Send, % reformatPhone(MainConfig.private["PHONE_NUM"])
}

{ ; Typo correction.
	:*0:,3::<3
	::<#::<3
	::<43::<3
	:::0:::)
	::;)_::;)
	:::)_:::)
	:::)(:::)
	::*shurgs*::*shrugs*
	::mmgm::mmhm
	::fwere::fewer
	::aew::awe
	::teh::the
	::tteh::teh
	::nayone::anyone
	::idneed::indeed
	::seriuosly::seriously
	::.ocm::.com
	::heirarchy::hierarchy
	:*0:previou::previous
	::previosu::previous
	::dcb::dbc
	::h?::oh?
	:*0:ndeed::indeed
	::IT"S::IT'S ; "
	::THAT"S::THAT'S ; "
	::scheduleable::schedulable
	::performably::performable
	::isntead::instead
	::overrideable::overridable
	::Tapestery::Tapestry
	::InBasket::In Basket
}

{ ; Expansions.
	{ ; General
		::gov't::government
		::eq'm::equilibrium
		::f'n::function
		::tech'l::technological
		::eq'n::equation
		::pop'n::population
		::def'n::definition
		::int'l::international
		::int'e::internationalize
		::int'd::internationalized
		::int'n::internationalization
		::ppt'::powerpoint
		::conv'l::conventional
		::Au'::Australia
		::char'c::characteristic
		::intro'd::introduced
		::dev't::development
		::civ'd::civilized
		::ep'n::European
		::uni'::university
		::sol'n::solution
		::pos'n::position
		::pos'd::positioned
		::imp't::implement
		::imp'n::implementation
		::add'l::additional
		::org'n::organization
		::doc'n::documentation
		::hier'l::hierarchical
		::heir'l::hierarchical
		::qai::QA Instructions
		::acc'n::association
		::inf'n::information
		::info'n::information
		
		::.iai::...I'll allow it
		::iai::I'll allow it
		::asig::and so it goes, and so it goes, and you're the only one who knows...
	}

	{ ; Billing
		::col'n::collection
		::coll'n::collection
		::auth'n::authorization
	}
	
	{ ; Emoji
		::.shrug::{U+AF}\_({U+30C4})_/{U+AF} ; ¯\_(ツ)_/¯ - 0xAF=¯, 0x30C4=ツ
	}
}

{ ; Date and time.
	:X:idate::sendDateTime("M/d/yy")
	:X:itime::sendDateTime("h:mm tt")
	
	:X:dashidate::sendDateTime("M-d-yy")
	:X:didate::sendDateTime("dddd`, M/d")
	:X:iddate::sendDateTime("M/d`, dddd")
	
	::.tscell::
		sendDateTime("M/d/yy")
		Send, {Tab}
		sendDateTime("h:mm tt")
		Send, {Tab}
	return
	
	; Arbitrary dates/times, translates
	:X:aidate::queryDateAndSend()
	:X:aiddate::queryDateAndSend("M/d`, dddd")
	:X:adidate::queryDateAndSend("dddd`, M/d")
	queryDateAndSend(format = "M/d/yy") {
		date := queryDate(format)
		if(date)
			SendRaw, % date
	}
	
	::aitime::
		queryTimeAndSend() {
			time := queryTime()
			if(time)
				SendRaw, % time
		}
}

{ ; URLs.
	:X:lpv::Send, % "chrome-extension://hdokiejnpimakedhajhdlcegeplioahd/vault.html"
}

{ ; Folders and paths.
	{ ; General
		::pff::C:\Program Files\
		::xpff::C:\Program Files (x86)\
		
		:X:urf::sendFolderPath("USER_ROOT")
		:X:dsf::sendFolderPath("USER_ROOT", "Desktop")
		:X:desf::sendFolderPath("USER_ROOT", "Design")
		:X:dlf::sendFolderPath("DOWNLOADS")
		:X:devf::sendFolderPath("USER_DEV")
		
		:X:otmf::sendFolderPath("ONETASTIC_MACROS")
	}

	{ ; AHK
		:X:arf::sendFolderPath("AHK_ROOT")
		:X:aconf::sendFolderPath("AHK_CONFIG")
		:X:atf::sendFolderPath("AHK_ROOT", "test")
		:X:asf::sendFolderPath("AHK_SOURCE")
		:X:acf::sendFolderPath("AHK_SOURCE", "common")
		:X:accf::sendFolderPath("AHK_SOURCE", "common\class")
		:X:apf::sendFolderPath("AHK_SOURCE", "program")
		:X:agf::sendFolderPath("AHK_SOURCE", "general")
		:X:astf::sendFolderPath("AHK_SOURCE", "standalone")
	}

	{ ; Epic - General
		:X:epf::sendFolderPath("EPIC_PERSONAL")
		:X:ssf::sendFolderPath("USER_ROOT", "Screenshots")
		:X:enfsf::sendFolderPath("EPIC_NFS_3DAY")
		:X:eunfsf::sendUnixFolderPath("EPIC_NFS_3DAY_UNIX")
		
		:X:ecompf::sendFolderPath("VB6_COMPILE")
	}
	
	{ ; Epic - Source
		:X:esf::sendFolderPath("EPIC_SOURCE_S1")
		:X:fesf::sendFilePath("EPIC_SOURCE_S1", MainConfig.private["EPICDESKTOP_PROJECT"])
	}
}
#If

; Edits this file.
^!h::
	editScript(A_LineFile)
return
