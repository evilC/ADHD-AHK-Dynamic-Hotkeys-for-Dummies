; 3rd party functions
; Tooltip function from http://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry598735
Class ADHDLib
	; ADHDLib - Autohotkey Dynamic Hotkeys for Dummies
{
	; ToDo:
	; BUGS:

	; Before next release:

	; Features:

	; Long-term:
	; Perform checking on hotkey_list to ensure sane values (No dupes, labels do not already exist etc)
	; Replace label names in ini with actual label names instead of 1, 2, 3 ?
	
	; Constructor - init default values
	__New(){
		this.core_version := "2.3.0"

		this.instantiated := 1
		this.hotkey_list := []
		this.author_macro_name := "An ADHD Macro"					; Change this to your macro name
		this.author_version := 1.0									; The version number of your script
		this.author_name := "Unknown"							; Your Name
		this.author_link := ""
		
		this.default_app := ""
		this.gui_w := 450
		this.gui_h := 200
		
		this.ini_version := 1
		this.write_version := 1				; set to 0 to stop writing of version to INI file on exit
		
		; Hooks
		this.events := {}
		;this.events.profile_load := ""
		this.events.option_changed := ""
		this.events.tab_changed := ""
		this.events.on_exit := ""
		this.events.program_mode_on := ""
		this.events.program_mode_off := ""
		this.events.disable_timers := ""
		this.events.app_active := ""		; When the "Limited" app comes into focus
		this.events.app_inactive := ""		; When the "Limited" app goes out of focus
		
		this.limit_app_w := -1				; Used for resolution change detection
		this.limit_app_h := -1
		this.limit_app_last_w := -1
		this.limit_app_last_h := -1
		this.tab_list := Array("Main")
		
		this.x64_warning := 1
		this.noaction_warning := 1
		; strip extension from end of script name for basis of INI name
		;this.ini_name := this.build_ini_name()
		this.build_ini_name()
		
		this.functionality_enabled := 1

		; Build list of "End Keys" for Input command
		this.EXTRA_KEY_LIST := "{Escape}"	; DO NOT REMOVE! - Used to quit binding
		; Standard non-printables
		this.EXTRA_KEY_LIST .= "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}"
		this.EXTRA_KEY_LIST .= "{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BackSpace}{Pause}"
		; Numpad - Numlock ON
		this.EXTRA_KEY_LIST .= "{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}{NumpadDot}{NumpadMult}{NumpadAdd}{NumpadSub}"
		; Numpad - Numlock OFF
		this.EXTRA_KEY_LIST .= "{NumpadIns}{NumpadEnd}{NumpadDown}{NumpadPgDn}{NumpadLeft}{NumpadClear}{NumpadRight}{NumpadHome}{NumpadUp}{NumpadPgUp}{NumpadDel}"
		; Numpad - Common
		this.EXTRA_KEY_LIST .= "{NumpadMult}{NumpadAdd}{NumpadSub}{NumpadDiv}{NumpadEnter}"
		; Stuff we may or may not want to trap
		;EXTRA_KEY_LIST .= "{Numlock}"
		this.EXTRA_KEY_LIST .= "{Capslock}"
		;EXTRA_KEY_LIST .= "{PrintScreen}"
		; Browser keys
		this.EXTRA_KEY_LIST .= "{Browser_Back}{Browser_Forward}{Browser_Refresh}{Browser_Stop}{Browser_Search}{Browser_Favorites}{Browser_Home}"
		; Media keys
		this.EXTRA_KEY_LIST .= "{Volume_Mute}{Volume_Down}{Volume_Up}{Media_Next}{Media_Prev}{Media_Stop}{Media_Play_Pause}"
		; App Keys
		this.EXTRA_KEY_LIST .= "{Launch_Mail}{Launch_Media}{Launch_App1}{Launch_App2}"

	}

	; EXPOSED METHODS
	
	; Load settings etc
	init(){
		; Perform some sanity checks
		
		; Check if compiled and x64
		if (A_IsCompiled){
			if (A_Ptrsize == 8 && this.x64_warning){
				Msgbox, You have compiled this script under 64-bit AutoHotkey.`n`nAs a result, it will not work for people on 32-bit windows.`n`nDo one of the following:`n`nReinstall Autohotkey and choose a 32-bit option.`n`nCreate an x64 exe without this warning by calling config_ignore_x64_warning()
				ExitApp
			}
		}

		; Check the user instantiated the class
		if (this.instantiated != 1){
			msgbox You must use an instance of this class, not the class itself.`nPut something like ADHD := New ADHDLib at the start of your script
			ExitApp
		}
		
		; Check the user defined a hotkey
		if (this.hotkey_list.MaxIndex() < 1){
			if (this.noaction_warning){
				msgbox, No Actions defined, Exiting...
				ExitApp
			}
		}

		; Check that labels specified as targets for hotkeys actually exist
		Loop, % this.hotkey_list.MaxIndex()
		{
			If (IsLabel(this.hotkey_list[A_Index,"subroutine"]) == false){
				msgbox, % "The label`n`n" this.hotkey_list[A_Index,"subroutine"] ":`n`n does not appear in the script.`nExiting..."
				ExitApp
			}

		}
		this.debug_ready := 0
		
		; Indicates that we are starting up - ignore errant events, always log until we have loaded settings etc use this value
		this.starting_up := 1

		this.debug("Starting up...")
		this.app_act_curr := -1						; Whether the current app is the "Limit To" app or not. Start on -1 so we can init first state of app active or inactive

		; Start ADHD init vars and settings

		; Variables to be stored in the INI file - will be populated by code later
		; [Variable Name, Control Type, Default Value]
		; eg ["MyControl","Edit","None"]
		this.ini_vars := []
		; Holds a REFERENCE copy of the hotkeys so authors can access the info (eg to quickly send a keyup after the trigger key is pressed)
		this.hotkey_mappings := {}

		#InstallKeybdHook
		#InstallMouseHook
		#MaxHotKeysPerInterval, 200

		#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
		SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

		; Make sure closing the GUI using X exits the script
		OnExit, GuiClose

		; List of mouse buttons
		this.mouse_buttons := "LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight"

		ini := this.ini_name
		IniRead, x, %ini%, Settings, adhd_gui_x, unset
		IniRead, y, %ini%, Settings, adhd_gui_y, unset
		this.first_run := 0
		if (x == "unset"){
			msgbox, Welcome to this ADHD based macro.`n`nThis window is appearing because no settings file was detected, one will now be created in the same folder as the script`nIf you wish to have an icon on your desktop, it is recommended you place this file somewhere other than your desktop and create a shortcut, to avoid clutter or accidental deletion.`n`nIf you need further help, look in the About tab for links to Author(s) sites.`nYou may find help there, you may also find a Donate button...
			x := 0	; initialize
			this.first_run := 1
		}
		if (y == "unset"){
			y := 0
			this.first_run := 1
		}

		if (x == ""){
			x := 0	; in case of crash empty values can get written
		}
		if (y == ""){
			y := 0
		}
		this.gui_x := x
		this.gui_y := y
		
		; Get list of profiles
		IniRead, pl, %ini%, Settings, adhd_profile_list, %A_Space%
		this.profile_list := pl
		; Get current profile
		IniRead, cp, %ini%, Settings, adhd_current_profile, Default
		this.current_profile := cp

		; Get version of INI file
		IniRead, iv, %ini%, Settings, adhd_ini_version, 1
		this.loaded_ini_version := iv

	}
	
	; Creates the ADHD gui
	create_gui(){
		; IMPORTANT !!
		; Declare global for gui creation routine.
		; Limitation of AHK - no dynamic creation of vars, and guicontrols need a global or static var
		; Also, gui commands do not accept objects
		; So declare temp vars as local in here
		global
		; Set up the GUI ====================================================
		local w := this.gui_w
		local h := this.gui_h - 30
		
		local tabs := ""
		Loop, % this.tab_list.MaxIndex()
		{
			tabs := tabs this.tab_list[A_Index] "|"
		}
		Gui, Add, Tab2, x0 w%w% h%h% vadhd_current_tab gadhd_tab_changed, %tabs%Bindings|Profiles|About

		local tabtop := 40
		local current_row := tabtop + 20
		
		local nexttab := this.tab_list.MaxIndex() + 1
		Gui, Tab, %nexttab%
		; BINDINGS TAB
		Gui, Add, Text, x5 y40 W100 Center, Action
		;Gui, Add, Text, xp+100 W70 Center, Keyboard
		;Gui, Add, Text, xp+90 W70 Center, Mouse
		;Gui, Add, Text, xp+82 W30 Center, Ctrl
		;Gui, Add, Text, xp+30 W30 Center, Shift
		;Gui, Add, Text, xp+30 W30 Center, Alt

		; Add hotkeys
		local mb := this.mouse_buttons
		
		; Add functionality toggle as last item in list
		this.config_hotkey_add({uiname: "Functionality Toggle", subroutine: "adhd_functionality_toggle"})

		Gui, Add, Text, x410 y30 w30 center, Wild`nMode

		Loop % this.hotkey_list.MaxIndex() {
			local name := this.hotkey_list[A_Index,"uiname"]
			Gui, Add, Text,x5 W100 y%current_row%, %name%
			Gui, Add, Edit, Disabled vadhd_hk_hotkey_%A_Index% w260 x105 yp-3,
			;Gui, Add, Edit, Disabled vadhd_hk_hotkey_display_%A_Index% w160 x105 yp-3, None
			;Gui, Add, Edit, Disabled vadhd_hk_hotkey_%A_Index% w95 xp+165 yp,
			Gui, Add, Button, gadhd_set_binding vadhd_hk_bind_%A_Index% yp-1 xp+270, Bind
			;Gui, Add, Button, gadhd_set_binding vadhd_hk_bind_%A_Index% yp-1 xp+105, Bind
			Gui, Add, Checkbox, vadhd_hk_wild_%A_Index% gadhd_option_changed xp+45 yp+5 w25 center
			/*
			local name := this.hotkey_list[A_Index,"uiname"]
			Gui, Add, Text,x5 W100 y%current_row%, %name%
			Gui, Add, Hotkey, yp-5 xp+100 W70 vadhd_hk_k_%A_Index% gadhd_key_changed
			Gui, Add, DropDownList, yp xp+80 W90 vadhd_hk_m_%A_Index% gadhd_mouse_changed, None||%mb%
			Gui, Add, CheckBox, xp+100 yp+5 W25 vadhd_hk_c_%A_Index% gadhd_option_changed
			Gui, Add, CheckBox, xp+30 yp W25 vadhd_hk_s_%A_Index% gadhd_option_changed
			Gui, Add, CheckBox, xp+30 yp W25 vadhd_hk_a_%A_Index% gadhd_option_changed
			*/
			current_row := current_row + 30
		}
		
		; Limit application toggle
		Gui, Add, CheckBox, x5 yp+25 W160 vadhd_limit_application_on gadhd_option_changed, Limit to Application: ahk_class

		; Limit application Text box
		Gui, Add, Edit, xp+170 yp+2 W120 vadhd_limit_application gadhd_option_changed,

		; Launch window spy
		Gui, Add, Button, xp+125 yp-1 W15 gadhd_show_window_spy, ?
		adhd_limit_application_TT := "Enter a value here to make hotkeys only trigger when a specific application is open.`nUse the window spy (? Button to the right) to find the ahk_class of your application.`nCaSe SenSitIve !!!"

		; Program mode toggle
		Gui, Add, Checkbox, x5 yp+30 vadhd_program_mode gadhd_program_mode_changed, Program Mode
		adhd_program_mode_TT := "Turns on program mode and lets you program keys. Turn off again to enable hotkeys"

		local nexttab := this.tab_list.MaxIndex() + 2
		Gui, Tab, %nexttab%
		; PROFILES TAB
		current_row := tabtop + 20
		Gui, Add, Text,x5 W40 y%current_row%,Profile
		local pl := this.profile_list
		local cp := this.current_profile
		Gui, Add, DropDownList, xp+35 yp-5 W300 vadhd_current_profile gadhd_profile_changed, Default||%pl%
		Gui, Add, Button, x40 yp+25 gadhd_add_profile, Add
		Gui, Add, Button, xp+35 yp gadhd_delete_profile, Delete
		Gui, Add, Button, xp+47 yp gadhd_duplicate_profile, Copy
		Gui, Add, Button, xp+40 yp gadhd_rename_profile, Rename
		GuiControl,ChooseString, adhd_current_profile, %cp%

		local nexttab := this.tab_list.MaxIndex() + 3
		Gui, Tab, %nexttab%
		; ABOUT TAB
		current_row := tabtop + 5
		Gui, Add, Link,x5 y%current_row%, This macro was created using AHK Dynamic Hotkeys for Dummies (ADHD)
		Gui, Add, Link,x5 yp+25,By Clive "evilC" Galway <a href="http://evilc.com/proj/adhd">HomePage</a>    <a href="https://github.com/evilC/ADHD-AHK-Dynamic-Hotkeys-for-Dummies">GitHub Page</a>
		local aname := this.author_name
		local mname := this.author_macro_name
		Gui, Add, Link,x5 yp+35, This macro ("%mname%") was created by %aname%
		local link := this.author_link
		Gui, Add, Link,x5 yp+25, %link%

		Gui, Tab

		; Add a Status Bar for at-a-glance current profile readout and update status
		local ypos := this.gui_h - 17
		local tmp := this.gui_w - 200
		Gui, Add, Text, x5 y%ypos%,Current Profile:
		Gui, Add, Text, x80 y%ypos% w%tmp% vCurrentProfile,

		local tmp := this.gui_w - 120
		Gui, Add, Text, x%tmp% y%ypos%, Updates:
		;local tmp := this.gui_w - 200
		Gui, Add, Text, xp+50 y%ypos% w60 vUpdateStatus
		;Gui, Add, Button, xp+48 yp-6 w20 gadhd_update_status_info, ?
		Gui, Add, Button, xp+48 yp-6 w20 vUpdateStatusInfo, ?
		UpdateStatusInfo_TT := ""

		; Build version info
		local bad := 0
		
		; Check versions:
		local tt := "Versions found on the internet:`n`nADHD library:`n"

		; ADHD version
		ver := this.get_ver("http://evilc.com/files/ahk/adhd/adhd.au.txt")
		if (ver){
			cv := this.pad_version(this.core_version)
			rv := this.pad_version(ver)
			diffc := this.semver_compare(cv,rv)

			tt .= this.version_tooltip_create(diffc,rv,cv)
		} else {
			tt .= "Unknown"
			bad++
		}
		tt .= "`n`n" this.author_macro_name ":`n"

		; Author Script version
		ver := this.get_ver(this.author_url_prefix)
		if (ver){
			av := this.pad_version(this.author_version)
			rv := this.pad_version(ver)
			diffa := this.semver_compare(av,rv)

			tt .= this.version_tooltip_create(diffa,rv,av)
		} else {
			tt .= "Unknown"
			bad++
		}

		; Show status
		if (bad){
			GuiControl,+Cblack,UpdateStatus
			GuiControl,,UpdateStatus, Unknown
		} else if (diffc > 0 || diffa > 0){
			GuiControl,+Cblue,UpdateStatus
			GuiControl,,UpdateStatus, Newer
		} else if (diffc < 0 || diffa < 0){
			GuiControl,+Cred,UpdateStatus
			GuiControl,,UpdateStatus, Available
		} else {
			GuiControl,+Cgreen,UpdateStatus
			GuiControl,,UpdateStatus, Latest
		}

		; Apply tooltip
		UpdateStatusInfo_TT := tt

		; Add Debug window controls
		Gui, Tab
		local tmp
		tmp := w - 90
		Gui, Add, CheckBox, x%tmp% y10 vadhd_debug_window gadhd_debug_window_change, Show Window
			
		tmp := w - 180
		Gui, Add, CheckBox, x%tmp% y10 vadhd_debug_mode gadhd_debug_change, Debug Mode

		; Fire GuiSubmit while starting_up is on to set all the variables
		Gui, Submit, NoHide

		; Create the debug GUI, but do not show yet
		tmp := w - 30
		Gui, 2:Add,Edit,w%tmp% h350 vadhd_log_contents hwndadhd_log ReadOnly,
		Gui, 2:Add, Button, gadhd_clear_log, clear
	}

	
	; Adds a GUI item and registers it for storage in the INI file
	; type(edit etc), name(variable name), options(eg xp+50), param3(eg dropdown list, label), default(used for ini file)
	gui_add(ctype, cname, copts, cparam3, cdef){
		; Note this function assumes global so it can create gui items
		Global
		Gui, Add, %ctype%, %copts% v%cname% gadhd_option_changed, %cparam3%
		this.ini_vars.Insert([cname,ctype,cdef])
	}

	build_ini_name(){
		tmp := A_Scriptname
		Stringsplit, tmp, tmp,.
		ini_name := ""
		last := ""
		Loop, % tmp0
		{
			if (last != ""){
				if (ini_name != ""){
					ini_name := ini_name "."
				}
				ini_name := ini_name last
			}
			last := tmp%A_Index%
		}
		this.ini_name := ini_name ".ini"
		return
	}

	finish_startup(){
		global	; Remove! phase out mass use of globals
		
		; Show the GUI =====================================
		local ver := this.core_version
		local aver := this.author_version
		local name := this.author_macro_name
		local x := this.gui_x
		local y := this.gui_y
		local w := this.gui_w
		local h := this.gui_h
		Gui, Show, x%x% y%y% w%w% h%h%, %name% v%aver% (ADHD v%ver%)

		this.debug_ready := 1

		; Set up the links on the footer of the main page
		h := this.get_gui_h() - 40
		name := this.get_macro_name()
		alink := this.author_help
		Gui, Add, Link, x5 y%h%, <a href="http://evilc.com/proj/adhd">ADHD Instructions</a>    %name% %alink%


		;Hook for Tooltips
		;OnMessage(0x200, "this.mouse_move")
		OnMessage(0x200, "adhd_mouse_move")


		; Finish setup =====================================
		this.profile_changed()
		this.debug_window_change()

		this.debug("Finished startup")

		; Finished startup, allow change of controls to fire events
		this.starting_up := 0

	}

	config_ini_version(ver){
		this.ini_version := ver
	}
	
	config_ignore_x64_warning(){
		this.x64_warning := 0
	}
	
	config_ignore_noaction_warning(){
		this.noaction_warning := 0
	}
	
	; Setup stuff
	config_hotkey_add(data){
		this.hotkey_list.Insert(data)
	}
	
	;ADHD.config_event("option_changed", "option_changed_hook")
	config_event(name, hook){
		this.events[name] := hook
	}
	
	config_size(w,h){
		this.gui_w := w
		this.gui_h := h
	}
	
	config_default_app(app){
		this.default_app := app
	}
	
	config_get_default_app_on(){
		global adhd_limit_application_on
		;Gets the state of the Limit App checkbox
		return adhd_limit_application_on
	}
	
	config_updates(url){
		this.author_url_prefix := url
	}
	
	; Configure the About tab
	config_about(data){
		this.author_macro_name := data.name					; Change this to your macro name
		this.author_version := data.version									; The version number of your script
		this.author_name := data.author							; Your Name
		this.author_link := data.link
		if (data.help == "" || data.help == null){
			this.author_help := this.author_link
		} else {
			this.author_help := data.help
		}
	}
	
	; Attempts to read a version from a text file at a specified URL
	get_ver(url){
		if (url == ""){
			return 0
		}
		
		pwhr := ComObjCreate("WinHttp.WinHttpRequest.5.1")
		pwhr.Open("GET",url) 
		pwhr.Send()
		ret := pwhr.ResponseText
		
		; Cater for 404s etc
		if (InStr(ret, "<html>")){
			return 0
		}		
		
		out := {}
		
		Loop, Parse, ret, `n`r, %A_Space%%A_Tab%
		{
			c := SubStr(A_LoopField, 1, 1)
			if (c="[")
				;key := SubStr(A_LoopField, 2, -1)
				continue
			else if (c=";")
				continue
			else {
				p := InStr(A_LoopField, "=")
				if p {
					k := SubStr(A_LoopField, 1, p-1)
					out[%k%] := SubStr(A_LoopField, p+1)
				}
			}
		}
		if (out[version] == ""){
			return 0
		}
		return out[version]
	}
	
	; Fires an event.
	; Basically executes a string as a function
	; Checks string is not empty first
	fire_event(event){
		if (event && event != ""){
			%event%()
		}
	}
	
	; Unused, just here to keep a record of the OnMessage technique
	gui_move( lParam, wParam, msg )
	{
		ToolTip, % "msg: " . msg . " | lParam: " . lParam . " | wParam: " . wParam
	}
	
	set_profile_statusbar(){
		cp := this.current_profile
		GuiControl,,CurrentProfile,%cp%
	}

	hotkey_index_to_name(idx){
		return this.hotkey_list[idx,"subroutine"]
	}

	; aka load profile
	profile_changed(){
		global adhd_debug_mode

		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_debug_window
		
		; Remove old bindings before changing profile
		;this.disable_hotkeys(1)
		this.disable_hotkeys(0)
		
		GuiControlGet,cp,,adhd_current_profile
		this.current_profile := cp
		;msgbox % this.current_profile
		this.debug("profile_changed - " this.current_profile)
		Gui, Submit, NoHide

		this.update_ini("adhd_current_profile", "Settings", this.current_profile,"")
		
		;SB_SetText("Current profile: " this.current_profile,2) 
		this.set_profile_statusbar() 
		
		this.hotkey_mappings := {}
		
		; Load hotkey bindings
		Loop, % this.hotkey_list.MaxIndex()
		{
			name := this.hotkey_index_to_name(A_Index)

			this.hotkey_mappings[this.hotkey_index_to_name(A_Index)] := {}
			this.hotkey_mappings[this.hotkey_index_to_name(A_Index)]["index"] := A_Index

			tmp := this.read_ini("adhd_hk_hotkey_" A_Index,this.current_profile,A_Space)
			this.hotkey_mappings[name].modified := tmp
			tmp := this.BuildHotkeyName(this.hotkey_mappings[name].modified, this.hotkey_mappings[name].type)
			GuiControl,, adhd_hk_hotkey_%A_Index%, %tmp%

			tmp := this.read_ini("adhd_hk_wild_" A_Index,this.current_profile,0)
			this.hotkey_mappings[name].wild := tmp
			GuiControl,, adhd_hk_wild_%A_Index%, %tmp%

			tmp := this.read_ini("adhd_hk_type_" A_Index,this.current_profile,0)
			this.hotkey_mappings[name].type := tmp

		}
		
		; limit application name
		this.remove_glabel("adhd_limit_application")
		if (this.default_app == "" || this.default_app == null){
			this.default_app := A_Space
		}
		tmp := this.read_ini("adhd_limit_app",this.current_profile,this.default_app)
		GuiControl,, adhd_limit_application, %tmp%
		this.add_glabel("adhd_limit_application")
		
		; limit application status
		tmp := this.read_ini("adhd_limit_app_on",this.current_profile,0)
		GuiControl,, adhd_limit_application_on, %tmp%
		
		; Get author vars from ini
		Loop, % this.ini_vars.MaxIndex()
		{
			def := this.ini_vars[A_Index,3]
			if (def == ""){
				def := A_Space
			}
			key := this.ini_vars[A_Index,1]
			sm := this.control_name_to_set_method(this.ini_vars[A_Index,2])
			
			this.remove_glabel(key)
			tmp := this.read_ini(key,this.current_profile,def)
			GuiControl,%sm%, %key%, %tmp%
			this.add_glabel(key)
		}

		; Debug settings
		adhd_debug_mode := this.read_ini("adhd_debug_mode","Settings",0)
		GuiControl,, adhd_debug_mode, %adhd_debug_mode%
		
		adhd_debug_window := this.read_ini("adhd_debug_window","Settings",0)
		GuiControl,, adhd_debug_window, %adhd_debug_window%

		;this.program_mode_changed()
		this.enable_hotkeys()
		
		; Fire the Author hook
		this.fire_event(this.events.option_changed)

		return
	}

	; Removes ~ * etc prefixes (But NOT modifiers!) from a hotkey object for comparison
	strip_prefix(hk){
		Loop {
			chr := substr(hk,1,1)
			if (chr == "~" || chr == "*" || chr == "$"){
				hk := substr(hk,2)
			} else {
				break
			}
		}
		return hk
	}

	; Removes ^ ! + # modifiers from a hotkey object for comparison
	strip_modifiers(hk){
		hk := this.strip_prefix(hk)

		Loop {
			chr := substr(hk,1,1)
			if (chr == "^" || chr == "!" || chr == "+" || chr == "#"){
				hk := substr(hk,2)
			} else {
				break
			}
		}
		return hk
	}

	; aka save profile
	option_changed(){
		global adhd_debug_mode

		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_debug_window
		
		; Disable existing hotkeys
		this.disable_hotkeys(0)

		if (this.starting_up != 1){
			;this.debug("option_changed - control: " A_guicontrol)
			
			Gui, Submit, NoHide

			; Hotkey bindings
			Loop % this.hotkey_list.MaxIndex(){
				name := this.hotkey_index_to_name(A_Index)

				this.update_ini("adhd_hk_hotkey_" A_Index, this.current_profile, this.hotkey_mappings[name].modified, "")
				tmp := this.BuildHotkeyName(this.hotkey_mappings[name].modified, this.hotkey_mappings[name].type)
				GuiControl,, adhd_hk_hotkey_%A_Index%, %tmp%

				this.update_ini("adhd_hk_type_" A_Index, this.current_profile, this.hotkey_mappings[name].type,0)

				this.hotkey_mappings[name].wild := adhd_hk_wild_%A_Index%
				this.update_ini("adhd_hk_wild_" A_Index, this.current_profile, this.hotkey_mappings[name].wild, 0)
			}
			
			this.update_ini("adhd_profile_list", "Settings", this.profile_list,"")
			
			; Limit app
			if (this.default_app == "" || this.default_app == null){
				this.default_app := A_Space
			}
			this.update_ini("adhd_limit_app", this.current_profile, adhd_limit_application, this.default_app)
			;SB_SetText("Current profile: " this.current_profile, 2)
			this.set_profile_statusbar()
			
			; Limit app toggle
			this.update_ini("adhd_limit_app_on", this.current_profile, adhd_limit_application_on, 0)
			
			; Add author vars to ini
			Loop, % this.ini_vars.MaxIndex()
			{
				tmp := this.ini_vars[A_Index,1]
				this.update_ini(tmp, this.current_profile, %tmp%, this.ini_vars[A_Index,3])
			}

			; Re-enable the hotkeys			
			this.enable_hotkeys()

			; Fire the Author hook
			this.fire_event(this.events.option_changed)
			
			; Debug settings
			this.update_ini("adhd_debug_mode", "settings", adhd_debug_mode, 0)
			this.update_ini("adhd_debug_window", "settings", adhd_debug_window, 0)
			
		} else {
			this.debug("ignoring option_changed - " A_Guicontrol)
		}
		return
	}

	; Detects key combinations
	set_binding(ctrlnum){
		global BindMode

		; init vars
		this.HKControlType := 0
		this.HKModifierState := {ctrl: 0, alt: 0, shift: 0, win: 0}

		; Disable existing hotkeys
		this.disable_hotkeys(0)

		; Enable Joystick detection hotkeys
		;JoystickDetection(1)

		; Start Bind Mode - this starts detection for mouse buttons and modifier keys
		BindMode := 1

		; Show the prompt
		prompt := "Please press the desired key combination.`n`n"
		prompt .= "Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n"
		prompt .= "Joystick buttons are also supported, but currently not with modifiers.`n"
		prompt .= "`nHit Escape to cancel."
		prompt .= "`nHold Escape to clear a binding."
		Gui, 3:Add, text, center, %prompt%
		Gui, 3:-Border +AlwaysOnTop
		Gui, 3:Show

		outhk := ""

		EXTRA_KEY_LIST := this.EXTRA_KEY_LIST
		Input, detectedkey, L1 M, %EXTRA_KEY_LIST%

		if (substr(ErrorLevel,1,7) == "EndKey:"){
			; A "Special" (Non-printable) key was pressed
			tmp := substr(ErrorLevel,8)
			detectedkey := tmp
			if (tmp == "Escape"){
				; Detection ended by Escape
				if (this.HKControlType > 0){
					; The Escape key was sent because a special button was used
					detectedkey := this.HKSecondaryInput
				} else {
					detectedkey := ""
					; Start listening to key up event for Escape, to see if it was held
					this.HKLastHotkey := ctrlnum
					hotkey, Escape up, ADHD_EscapeReleased, ON
					SetTimer, ADHD_DeleteHotkey, 1000
				}
			}
		}

		; Stop listening to mouse, keyboard etc
		BindMode := 0
		;JoystickDetection(0)

		; Hide prompt
		Gui, 3:Submit

		;msgbox % detectedkey "`n" this.HKModifierState.ctrl

		; Process results

		modct := this.CurrentModifierCount()

		if (detectedkey && modct && this.HKControlType == 3){
			msgbox ,,Error, Modifiers (Ctrl, Alt, Shift, Win) are currently not supported with Joystick buttons.
			detectedkey := ""
		}

		if (detectedkey){
			; Update the hotkey object
			;outhk := this.BuildHotkeyString(detectedkey,this.HKControlType)
			;tmp := {hk: outhk, type: this.HKControlType, status: 0}

			;msgbox % outhk

			clash := 0
			/*
			Loop % HotkeyList.MaxIndex(){
				if (A_Index == ctrlnum){
					continue
				}
				if (StripPrefix(HotkeyList[A_Index].hk) == StripPrefix(tmp.hk)){
					clash := 1
				}
			}
			if (clash){
				msgbox You cannot bind the same hotkey to two different actions. Aborting...
			} else {
				HotkeyList[ctrlnum] := tmp
			}
			*/
			this.hotkey_mappings[this.hotkey_index_to_name(ctrlnum)].modified := this.BuildHotkeyString(detectedkey,this.HKControlType)
			this.hotkey_mappings[this.hotkey_index_to_name(ctrlnum)].type := this.HKControlType
			;GuiControl,, adhd_hk_hotkey_%ctrlnum%, %outhk%
			; Rebuild rest of hotkey object, save settings etc
			this.option_changed()
			;OptionChanged()
			; Write settings to INI file
			;SaveSettings()

			; Update the GUI control
			;UpdateHotkeyControls()

			; Enable the hotkeys
			;EnableHotkeys()

		} else {
			; Escape was pressed - resotre original hotkey, if any
			;EnableHotkeys()
		}
		return

	}

	; Builds a Human-Readable form of a Hotkey string (eg "^C" -> "CTRL + C")
	BuildHotkeyName(hk,ctrltype){
		outstr := ""
		modctr := 0
		stringupper, hk, hk

		Loop % strlen(hk) {
			chr := substr(hk,1,1)
			mod := 0

			if (chr == "^"){
				; Ctrl
				mod := "CTRL"
				modctr++
			} else if (chr == "!"){
				; Alt
				mod := "ALT"
				modctr++
			} else if (chr == "+"){
				; Shift
				mod := "SHIFT"
				modctr++
			} else if (chr == "#"){
				; Win
				mod := "WIN"
				modctr++
			} else {
				break
			}
			if (mod){
				if (modctr > 1){
					outstr .= " + "
				}
				outstr .= mod
				; shift character out
				hk := substr(hk,2)
			}
		}
		if (modctr){
			outstr .= " + "
		}

		if (ctrltype == 1){
			; Solitary Modifiers
			pfx := substr(hk,1,1)
			if (pfx == "L"){
				outstr .= "LEFT "
			} else {
				outstr .= "RIGHT "
			}
			outstr .= substr(hk,2)
		} else if (ctrltype == 2){
			; Mouse Buttons
			if (hk == "LBUTTON") {
				outstr .= "LEFT MOUSE"
			} else if (hk == "RBUTTON") {
				outstr .= "RIGHT MOUSE"
			} else if (hk == "MBUTTON") {
				outstr .= "MIDDLE MOUSE"
			} else if (hk == "XBUTTON1") {
				outstr .= "MOUSE THUMB 1"
			} else if (hk == "XBUTTON2") {
				outstr .= "MOUSE THUMB 2"
			} else if (hk == "WHEELUP") {
				outstr .= "MOUSE WHEEL U"
			} else if (hk == "WHEELDOWN") {
				outstr .= "MOUSE WHEEL D"
			} else if (hk == "WHEELLEFT") {
				outstr .= "MOUSE WHEEL L"
			} else if (hk == "WHEELRIGHT") {
				outstr .= "MOUSE WHEEL R"
			}
		} else if (ctrltype == 3){
			; Joystick Buttons
			pos := instr(hk,"JOY")
			id := substr(hk,1,pos-1)
			button := substr(hk,5)
			outstr .= "JOYSTICK " id " BTN " button
		} else {
			; Keyboard Keys
			tmp := instr(hk,"NUMPAD")
			if (tmp){
				outstr .= "NUMPAD " substr(hk,7)
			} else {
				; Replace underscores with spaces (In case of key name like MEDIA_PLAY_PAUSE)
				StringReplace, hk, hk, _ , %A_SPACE%, All
				outstr .= hk
			}
		}
		return outstr
	}

	; Builds an AHK String (eg "^c" for CTRL + C) from the last detected hotkey
	BuildHotkeyString(str, type := 0){

		outhk := ""
		modct := this.CurrentModifierCount()

		if (type == 1){
			; Solitary modifier key used (eg Left / Right Alt)
			outhk := str
		} else {
			if (modct){
				; Modifiers used in combination with something else - List modifiers in a specific order
				modifiers := ["CTRL","ALT","SHIFT","WIN"]

				Loop, 4 {
					key := modifiers[A_Index]
					value := this.HKModifierState[modifiers[A_Index]]
					if (value){
						if (key == "CTRL"){
							outhk .= "^"
						} else if (key == "ALT"){
							outhk .= "!"
						} else if (key == "SHIFT"){
							outhk .= "+"
						} else if (key == "WIN"){
							outhk .= "#"
						}
					}
				}
			}
			; Modifiers etc processed, complete the string
			outhk .= str
		}

		return outhk
	}

	; Sets the state of the HKModifierState object to reflect the state of the modifier keys
	SetModifier(hk,state){
		if (hk == "lctrl" || hk == "rctrl"){
			this.HKModifierState.ctrl := state
		} else if (hk == "lalt" || hk == "ralt"){
			this.HKModifierState.alt := state
		} else if (hk == "lshift" || hk == "rshift"){
			this.HKModifierState.shift := state
		} else if (hk == "lwin" || hk == "rwin"){
			this.HKModifierState.win := state
		}
		return
	}

	; Counts how many modifier keys are currently held
	CurrentModifierCount(){
		return this.HKModifierState.ctrl + this.HKModifierState.alt + this.HKModifierState.shift  + this.HKModifierState.win
	}


	; Add and remove glabel is useful because:
	; When you use GuiControl to set the contents of an edit...
	; .. it's glabel is fired.
	; So remove glabel, set editbox value, re-add glabel to solve
	add_glabel(ctrl){
		GuiControl, +gadhd_option_changed, %ctrl%
	}

	remove_glabel(ctrl){
		GuiControl, -g, %ctrl%
	}

	get_macro_name(){
		return this.author_macro_name
	}
	
	get_gui_h(){
		return this.gui_h
	}
	
	get_gui_w(){
		return this.gui_w
	}
	
	; Profile management - functions to manage preserving user settings
	add_profile(name){
		global adhd_current_profile
		
		Loop, {
			if (name == ""){
				InputBox, name, Profile Name, Please enter a profile name
				if (ErrorLevel){
					return
				}
			}
			if (this.profile_unique(name)){
				break
			} else {
				msgbox Duplicate names are not allowed, please re-enter name.
				name := ""
			}
		}
		if (this.profile_list == ""){
			this.profile_list := name
		} else {
			this.profile_list := this.profile_list "|" name
		}
		pl := this.profile_list
		Sort, pl, D|
		this.profile_list := pl
		
		GuiControl,, adhd_current_profile, |Default||%pl%
		GuiControl,ChooseString, adhd_current_profile, %name%
		adhd_current_profile := name
		this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")
		; Call profile load on a nonexistant profile to force settings to defaults and reset UI
		this.profile_changed()
		; No need to save - profile is default options

		return name
	}

	; Deletes a profile
	delete_profile(name, gotoprofile = "Default"){
		Global adhd_current_profile
		
		if (name != "Default"){
			pl := this.profile_list
			StringSplit, tmp, pl, |
			out := ""
			Loop, %tmp0%{
				if (tmp%a_index% != name){
					if (out != ""){
						out := out "|"
					}
					out := out tmp%a_index%
				}
			}
			pl := out
			this.profile_list := pl
			
			ini := this.ini_name
			IniDelete, %ini%, %name%
			this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")		
			
			; Set new contents of list
			GuiControl,, adhd_current_profile, |Default|%pl%
			
			; Select the desired new current profile
			GuiControl, ChooseString, adhd_current_profile, %gotoprofile%
			
			; Trigger save
			Gui, Submit, NoHide
			
			this.profile_changed()
		}
		return
	}

	; Copies a profile
	duplicate_profile(name){
		global adhd_current_profile
		
		Loop, {
			; Blank name specified - prompt for name
			if (name == ""){
				InputBox, name, Profile Name, Please enter a profile name,,,,,,,,%adhd_current_profile%
				if (ErrorLevel){
					return
				}
			}
			if (this.profile_unique(name)){
				break
			} else {
				msgbox Duplicate names are not allowed, please re-enter name.
				name := ""
			}
		}
		; Create the new item in the profile list
		if (this.profile_list == ""){
			this.profile_list := name
		} else {
			this.profile_list := this.profile_list "|" name
		}
		pl := this.profile_list
		Sort, pl, D|
		this.profile_list := pl
		
		this.current_profile := name
		adhd_current_profile := name
		; Push the new list to the profile select box
		GuiControl,, adhd_current_profile, |Default||%pl%
		; Set the new profile to the currently selected item
		GuiControl,ChooseString, adhd_current_profile, %name%
		; Update the profile list in the INI
		this.update_ini("adhd_profile_list", "Settings", this.profile_list, "")
		
		; Firing option_changed saves the current state to the new profile name in the INI
		this.debug("duplicate_profile calling option_changed")
		this.option_changed()
		
		; Fire profile changed to update current profile in ini
		this.profile_changed()

		return name
	}

	; Renames a profile
	rename_profile(){
		old_prof := this.current_profile
		if (this.current_profile != "Default"){
			Loop {
				InputBox, new_prof, Profile Name, Please enter a new name,,,,,,,,%old_prof%
				if (ErrorLevel){
					return
				}
				if (this.current_profile == name){
					msgbox Please enter a different name.
					return
				}
				if (this.profile_unique(name)){
					break
				} else {
					msgbox Duplicate names are not allowed, please re-enter name.
				}
			}
			if (this.duplicate_profile(new_prof) != ""){
				this.delete_profile(old_prof,new_prof)
			}
		}
		return
	}

	; Checks if a profile name is unique
	profile_unique(name){
		tmp := this.profile_list
		Loop, parse, tmp, |
		{
			if (A_LoopField == name){
				return 0
			}
		}
		return 1
	}

	; End profile management

	; For some games, they will not let you autofire if the triggering key is still held down...
	; even if the triggering key is not the key sent and does nothing in the game!
	; Often a workaround is to send a keyup of the triggering key
	; Calling send_keyup_on_press() in an action will cause this to happen
	send_keyup_on_press(sub,mod){
		; hotkey_mappings contains a handy lookup to hotkey mappings !
		; contains "modified" and "unmodified" keys
		; Note, it is REFERENCE ONLY. Changing it has no effect.
		tmp := this.hotkey_mappings[sub][mod] " up"
		Send {%tmp%}

	}

	tab_changed(){
		global adhd_program_mode
		
		; If in program mode on tab change, disable program mode
		if (adhd_program_mode == 1){
			GuiControl,,adhd_program_mode,0
			this.program_mode_changed()
		}
		Gui, Submit, NoHide
		this.fire_event(this.events.tab_changed)
		return
	}

	/*
	get_program_mode(){
		global adhd_program_mode
		
		return adhd_program_mode
	}
	*/
	
	; Converts a Control name (eg DropDownList) into the parameter passed to GuiControl to set that value (eg ChooseString)
	control_name_to_set_method(name){
		if (name == "DropDownList"){
			return "ChooseString"
		} else {
			return ""
		}
	}

	; INI manipulation
	
	; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
	update_ini(key, section, value, default){
		tmp := this.ini_name
		if (value != default){
			; Only write the value if it differs from what is already written
			if (this.read_ini(key,section,-1) != value){
				IniWrite,  %value%, %tmp%, %section%, %key%
			}
		} else {
			; Only delete the value if there is already a value to delete
			if (this.read_ini(key,section,-1) != -1){
				IniDelete, %tmp%, %section%, %key%
			}
		}
	}

	read_ini(key,section,default){
		ini := this.ini_name
		IniRead, out, %ini%, %section%, %key%, %default%
		return out
	}

	; Called on app exit
	exit_app(){	
		Gui, +Hwndgui_id
		WinGetPos, gui_x, gui_y,,, ahk_id %gui_id%
		ini := this.ini_name
		if (this.read_ini("adhd_gui_x","Settings", -1) != gui_x && gui_x >= 0){
			IniWrite, %gui_x%, %ini%, Settings, adhd_gui_x
		}
		if (this.read_ini("gui_y","Settings", -1) != gui_y && gui_x >= 0){
			IniWrite, %gui_y%, %ini%, Settings, adhd_gui_y
		}

		if (this.write_version){
			tmp := this.ini_version
			IniWrite, %tmp%, %ini%, Settings, adhd_ini_version
		}
		
		this.fire_event(this.events.on_exit)
		ExitApp
		return
	}

	show_window_spy(){
		SplitPath, A_AhkPath,,tmp
		tmp := tmp "\AU3_Spy.exe"
		IfExist, %tmp%
			Run, %tmp%
	}

	; Debug functions
	debug_window_change(){
		global adhd_debug_window
		
		gui, submit, nohide
		if (adhd_debug_window == 1){
			Gui, +Hwndgui_id
			WinGetPos, x, y,,, ahk_id %gui_id%
			y := y - 440
			w := this.gui_w
			Gui, 2:Show, x%x% y%y% w%w% h400, ADHD Debug Window
		} else {
			gui, 2:hide
		}
		; On startup do not call option_changed, we are just setting the window open or closed
		if (!this.starting_up){
			this.option_changed()
		}
		return
	}

	debug_change(){
		gui, 2:submit, nohide
		this.option_changed()
		return
	}

	debug(msg){
		global adhd_log_contents
		global adhd_debug_mode
		global adhd_log

		; If in debug mode, or starting up...
		if (adhd_debug_mode || this.starting_up){
			;adhd_log_contents := adhd_log_contents "* " msg "`n"
			adhd_log_contents := "* " msg "`n " adhd_log_contents
			if (this.debug_ready){
				guicontrol,2:,adhd_log_contents, % adhd_log_contents
				; Send CTRL-END to log control to make it scroll down.
				;controlsend,,^{End},ahk_id %adhd_log%
				gui, 2:submit, nohide
			}
		}
	}
	
	clear_log(){
		global adhd_log_contents
		adhd_log_contents := ""
		GuiControl,,adhd_log_contents,%adhd_log_contents%
	}

	; Program mode stuff
	program_mode_changed(){
		global adhd_limit_application
		global adhd_limit_application_on
		global adhd_program_mode
		
		this.debug("program_mode_changed")
		Gui, Submit, NoHide
		
		if (adhd_program_mode == 1){
			this.debug("Entering Program Mode")
			; Enable controls, stop hotkeys, kill timers
			this.disable_hotkeys(0)
			this.disable_heartbeat()
			GuiControl, enable, adhd_limit_application
			GuiControl, enable, adhd_limit_application_on
			this.fire_event(this.events.program_mode_on)
		} else {
			; Disable controls, start hotkeys, start heartbeat timer
			this.debug("Exiting Program Mode")
			this.enable_hotkeys()
			this.enable_heartbeat()
			GuiControl, disable, adhd_limit_application
			GuiControl, disable, adhd_limit_application_on
			this.fire_event(this.events.program_mode_off)
		}
		return
	}

	; App detection stuff
	enable_heartbeat(){
		this.debug("Enabling Heartbeat")
		global adhd_limit_application
		global adhd_limit_application_on
		
		if (adhd_limit_application_on == 1 && adhd_limit_application != ""){
			SetTimer, adhd_heartbeat, 500
		}
		return
	}

	disable_heartbeat(){
		this.debug("Disabling Heartbeat")
		SetTimer, adhd_heartbeat, Off
		return
	}

	heartbeat(){
		global adhd_limit_application
		
		; Check current app here.
		; Not used to enable or disable hotkeys, used to start or stop author macros etc
		IfWinActive, % "ahk_class " adhd_limit_application
		{
			WinGetPos,,,limit_w,limit_h, % "ahk_class " adhd_limit_application
			; ToDo: Bodged
			;WinGet, tmp, MinMax, % "ahk_class " adhd_limit_application
			;if (tmp == -1 || limit_h <= 30)
			if (limit_h <= 30){
				this.debug("Minimized app - not firing change")
				return
			}
			; If the size has changed since the last heartbeat
			if ( (this.limit_app_w != limit_w) || (this.limit_app_h != limit_h)){
				if ((this.limit_app_w == -1) && (this.limit_app_h == -1)){
					fire_change := 0
				} else {
					fire_change := 1
				}
				this.limit_app_last_w := this.limit_app_w
				this.limit_app_last_h := this.limit_app_h
				this.limit_app_w := limit_w
				this.limit_app_h := limit_h
				if (fire_change){
					this.debug("Resolution change detected (" this.limit_app_last_w "x" this.limit_app_last_h " --> " this.limit_app_w "x" this.limit_app_h ")- firing change")
					this.fire_event(this.events.resolution_changed)
					  
				} else {
					this.debug("First detection of resolution - not firing change")
				}
			}
			this.app_active(1)
		}
		else
		{
			this.app_active(0)
		}
		return
	}

	limit_app_get_size(){
		return {w: this.limit_app_w, h:this.limit_app_h}
	}
	
	limit_app_get_last_size(){
		return {w: this.limit_app_last_w, h:this.limit_app_last_h}	
	}
	
	app_active(act){
		if (act){
			if (this.app_act_curr == 0){
				; Changing from inactive to active
				this.app_act_curr := 1
				this.debug("Firing app_active")
				this.fire_event(this.events.app_active)
			}
		} else {
			if (this.app_act_curr == 1 || this.app_act_curr == -1){
				; Changing from active to inactive or on startup
				; Stop Author Timers
				this.app_act_curr := 0
				
				; Fire event hooks
				this.fire_event(this.events.disable_timers)
				this.debug("Firing app_inactive")
				this.fire_event(this.events.app_inactive)
				;Gosub, adhd_disable_author_timers	; Fire the Author hook
			}
		}
	}

	limit_app_is_active(){
		if (this.app_act_curr){
			return true
		} else {
			return false
		}
	}
	
	; Hotkey detection routines
	enable_hotkeys(){
		global adhd_limit_application
		global adhd_limit_application_on
		
		; ToDo: Should not submit gui here, triggering save...
		this.debug("enable_hotkeys")
		
		Gui, Submit, NoHide
		Loop % this.hotkey_list.MaxIndex(){
			name := this.hotkey_index_to_name(A_Index)
			if (this.hotkey_mappings[name].modified != ""){
				;msgbox % this.hotkey_mappings[name].modified " -> " this.hotkey_list[A_Index,"subroutine"]
				hotkey_string := this.hotkey_mappings[name].modified
				hotkey_subroutine := this.hotkey_list[A_Index,"subroutine"]

				this.debug("Adding hotkey: " hotkey_string " sub: " hotkey_subroutine " wild: " this.hotkey_mappings[name].wild)
				; Bind down action of hotkey
				prefix := "~"
				if (this.hotkey_mappings[name].wild){
					prefix .= "*"
				}
				Hotkey, %prefix%%hotkey_string% , %hotkey_subroutine%
				Hotkey, %prefix%%hotkey_string% , %hotkey_subroutine%, On
				
				if (IsLabel(hotkey_subroutine "Up")){
					; Bind up action of hotkey
					Hotkey, %prefix%%hotkey_string% up , %hotkey_subroutine%Up
					Hotkey, %prefix%%hotkey_string% up , %hotkey_subroutine%Up, On
				}
				; ToDo: Up event does not fire for wheel "buttons" - send dupe event or something?

			}
		}
	}

	disable_hotkeys(mode){
		global adhd_limit_application
		global adhd_limit_application_on
		
		this.debug("disable_hotkeys")

		max := this.hotkey_list.MaxIndex()
		; If 1 passed to mode, do not disable the last hotkey (Functionality Toggle)
		if (mode){
			max -= 1
		}
		Loop, % max
		{
			name := this.hotkey_index_to_name(A_Index)
			if (this.hotkey_mappings[name].modified != ""){
				hotkey_string := this.hotkey_mappings[name].modified
				hotkey_subroutine := this.hotkey_list[A_Index,"subroutine"]

				this.debug("Removing hotkey: " hotkey_string " sub: " hotkey_subroutine " wild: " this.hotkey_mappings[name].wild)

				prefix := "~"
				if (this.hotkey_mappings[name].wild){
					prefix .= "*"
				}

				; Bind down action of hotkey
				Hotkey, %prefix%%hotkey_string% , %hotkey_subroutine%, Off
				
				if (IsLabel(hotkey_subroutine "Up")){
					; Bind up action of hotkey
					Hotkey, %prefix%%hotkey_string% up , %hotkey_subroutine%Up, Off
				}
				; ToDo: Up event does not fire for wheel "buttons" - send dupe event or something?

			}
		}
		return
	}

	; Removes a hotkey - called at end of a timer, not a general purpose functions
	DeleteHotkey(){
		soundbeep
		this.disable_hotkeys()
		name := this.hotkey_index_to_name(this.HKLastHotkey)
		this.hotkey_mappings[name].modified := ""
		this.hotkey_mappings[name].type := 0
		
		this.option_changed()
		return
	}

	/*
	get_hotkey_string(hk){
		;Get hotkey string - could be keyboard or mouse
		tmp := adhd_hk_k_%hk%
		if (tmp == ""){
			tmp := adhd_hk_m_%hk%
			if (tmp == "None"){
				tmp := ""
			}
		}
		return tmp
	}
	*/

	/*
	; Special key detection routines
	special_key_pressed(ctrl){
		modifier := ""
		If GetKeyState("Shift","P")
			modifier .= "+"
		If GetKeyState("Ctrl","P")
			modifier .= "^"
		If GetKeyState("Alt","P")
			modifier .= "!"
		Gui, Submit, NoHide											;If BackSpace is the first key press, Gui has never been submitted.
		If (A_ThisHotkey == "*BackSpace" && %ctrl% && !modifier)	;If the control has text but no modifiers held,
			GuiControl,,%ctrl%                                      ;  allow BackSpace to clear that text.
		Else                                                     	;Otherwise,
			GuiControl,,%ctrl%, % modifier SubStr(A_ThisHotkey,2)	;  show the hotkey.
		this.debug("special key detect calling key_changed")
		this.key_changed(ctrl)
		return
	}

	hotkey_ctrl_has_focus() {
		GuiControlGet, ctrl, Focus       ;ClassNN
		If InStr(ctrl,"hotkey") {
			GuiControlGet, ctrl, FocusV     ;Associated variable
			Return, ctrl
		}
	}

	; Builds the prefix that sets how Modifier Keys (Ctrl, Shift, Alt) work with the hotkey
	build_prefix(hk){
		out := ""
		tmp = adhd_hk_c_%hk%
		GuiControlGet,%tmp%
		if (adhd_hk_c_%hk% == 1){
			out := out "^"
		}
		if (adhd_hk_a_%hk% == 1){
			out := out "!"
		}
		if (adhd_hk_s_%hk% == 1){
			out := out "+"
		}
		
		; If Ctrl, Shift or Alt are not selected, make key work when any combination of modifiers held
		if (out == ""){
			out := "*"
		}
		
		return out
	}
	*/
	functionality_toggle(){
		if (this.functionality_enabled){
			this.functionality_enabled := 0
			soundbeep, 400, 200
			; pass 1 as a parameter to disable_hotkeys to tell it to not disable functionality toggle
			this.disable_hotkeys(1)
		} else {
			this.functionality_enabled := 1
			soundbeep, 800, 200
			this.enable_hotkeys()
		}
	}
	
	; Run as admin code from http://www.autohotkey.com/board/topic/46526-
	run_as_admin() {
		Global 0
		IfEqual, A_IsAdmin, 1, Return 0
		Loop, %0% {
			params .= A_Space . %A_Index%
		}
		DllCall("shell32\ShellExecute" (A_IsUnicode ? "":"A"),uint,0,str,"RunAs",str,(A_IsCompiled ? A_ScriptFullPath
			: A_AhkPath),str,(A_IsCompiled ? "": """" . A_ScriptFullPath . """" . A_Space) params,str,A_WorkingDir,int,1)
		ExitApp
	}

	; Semantic version comparison from http://www.autohotkey.com/board/topic/81789-semverahk-compare-version-numbers/
	semver_validate(version){
		return !!RegExMatch(version, "^(\d+)\.(\d+)\.(\d+)(\-([0-9A-Za-z\-]+\.)*[0-9A-Za-z\-]+)?(\+([0-9A-Za-z\-]+\.)*[0-9A-Za-z\-]+)?$")
	}

	semver_parts(version, byRef out_major, byRef out_minor, byRef out_patch, byRef out_prerelease, byRef out_build){
		return !!RegExMatch(version, "^(?P<major>\d+)\.(?P<minor>\d+)\.(?P<patch>\d+)(\-(?P<prerelease>([0-9A-Za-z\-]+\.)*([0-9A-Za-z\-]+)))?(\+?(?P<build>([0-9A-Za-z\-]+\.)*([0-9A-Za-z\-]+)))?$", out_)
	}

	semver_compare(version1, version2){
		if (!this.semver_parts(version1, maj1, min1, pat1, pre1, bld1))
			throw Exception("Invalid version: " version1)
		if (!this.semver_parts(version2, maj2, min2, pat2, pre2, bld2))
			throw Exception("Invalid version: " version2)
	 
		for each, part in ["maj", "min", "pat"]
		{
			%part%1 += 0, %part%2 += 0
			if (%part%1 < %part%2)
				return -1
			else if (%part%1 > %part%2)
				return +1
		}
	 
		for each, part in ["pre", "bld"] ; { "pre" : 1, "bld" : -1 }
		{
			if (%part%1 && %part%2)
			{
				StringSplit part1_, %part%1, .
				StringSplit part2_, %part%2, .
				Loop % part1_0 < part2_0 ? part1_0 : part2_0 ; use the smaller amount of parts
				{
					if part1_%A_Index% is digit
					{
						if part2_%A_Index% is digit ; both are numeric: compare numerically
						{
							part1_%A_Index% += 0, part2_%A_Index% += 0
							if (part1_%A_Index% < part2_%A_Index%)
								return -1
							else if (part1_%A_Index% > part2_%A_Index%)
								return +1
							continue
						}
					}
					; at least one is non-numeric: compare by characters
					if (part1_%A_Index% < part2_%A_Index%)
						return -1
					else if (part1_%A_Index% > part2_%A_Index%)
						return +1
				}
				; all compared parts were equal - the longer one wins
				if (part1_0 < part2_0)
					return -1
				else if (part1_0 > part2_0)
					return +1
			}
			else if (!%part%1 && %part%2) ; only version2 has prerelease -> version1 is higher
				return (part == "pre") ? +1 : -1
			else if (!%part%2 && %part%1) ; only version1 has prerelease -> it is smaller
				return (part == "pre") ? -1 : +1
		}
		return 0
	}

	; pad version numbers to have 3 numbers (x.y.z) at a minimum.
	pad_version(ver){
		stringsplit, ver, ver,.

		if (ver0 < 3){
			ctr := 3-ver0
			Loop, %ctr% {
				ver .= ".0"
			}
		}
		return ver
	}

	; Create tooltips for core script and author script versions
	version_tooltip_create(diff,rem,loc){
		tt := ""

		if (diff == 0){
			tt .= "Same (" loc ")"
		} else if (diff > 0){
			tt .= "Newer (" rem ", you have " loc ")"
		} else {
			tt .= "Older (" rem ", you have " loc ")"
		}

		return tt
	}
}

; Tooltip function from http://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry598735
; ToDo: Has to be here as when handling an OnMessage callback, it has no concept of "this"
adhd_mouse_move(){
	static CurrControl, PrevControl, _TT
	CurrControl := A_GuiControl
	If (CurrControl <> PrevControl){
			SetTimer, ADHD_DisplayToolTip, -750 	; shorter wait, shows the tooltip faster
			PrevControl := CurrControl
	}
	return
	
	ADHD_DisplayToolTip:
	try
			ToolTip % %CurrControl%_TT
	catch
			ToolTip
	SetTimer, ADHD_RemoveToolTip, -10000
	return
	
	ADHD_RemoveToolTip:
	ToolTip
	return
}


; Label triggers

adhd_profile_changed:
	ADHD.profile_changed()
	return

adhd_option_changed:
	ADHD.option_changed()
	return

adhd_set_binding:
	ADHD.set_binding(substr(A_GuiControl,14))
	return

adhd_add_profile:
	ADHD.add_profile("")	; just clicking the button calls with empty param
	return

; Delete Profile pressed
adhd_delete_profile:
	ADHD.delete_profile(adhd_current_profile)	; Just clicking the button deletes the current profile
	return

adhd_duplicate_profile:
	ADHD.duplicate_profile("")
	return
	
adhd_rename_profile:
	ADHD.rename_profile()
	return

adhd_tab_changed:
	ADHD.tab_changed()
	return

adhd_key_changed:
	ADHD.key_changed(A_GuiControl)
	return

adhd_mouse_changed:
	ADHD.mouse_changed()
	return

adhd_enable_hotkeys:
	ADHD.enable_hotkeys()
	return

adhd_disable_hotkeys:
	ADHD.disable_hotkeys(0)
	return

adhd_show_window_spy:
	ADHD.show_window_spy()
	return

adhd_debug_window_change:
	ADHD.debug_window_change()
	return

adhd_debug_change:
	ADHD.debug_change()
	return
	
adhd_clear_log:
	ADHD.clear_log()
	return

adhd_program_mode_changed:
	ADHD.program_mode_changed()
	return

adhd_heartbeat:
	ADHD.heartbeat()
	return

adhd_functionality_toggle:
	ADHD.functionality_toggle()
	return



ADHD_DeleteHotkey:
	SetTimer, ADHD_DeleteHotkey, Off
	ADHD.DeleteHotKey()
	return

ADHD_EscapeReleased:
	hotkey, Escape up, ADHD_EscapeReleased, OFF
	SetTimer, ADHD_DeleteHotkey, Off
	return
	
; === SHOULD NOT NEED TO EDIT BELOW HERE! ===========================================================================


; Kill the macro if the GUI is closed
adhd_exit_app:
GuiClose:
	ADHD.exit_app()
	return

/*
; ==========================================================================================================================
; Code from http://www.autohotkey.com/board/topic/47439-user-defined-dynamic-hotkeys/
; This code enables extra keys in a Hotkey GUI control
#MenuMaskKey vk07                 ;Requires AHK_L 38+
#If adhd_ctrl := ADHD.hotkey_ctrl_has_focus()
	*AppsKey::                       ;Add support for these special keys,
	*BackSpace::                     ;  which the hotkey control does not normally allow.
	*Delete::
	*Enter::
	*Escape::
	*Pause::
	*PrintScreen::
	*Space::
	*Tab::
	; Can use mouse hotkeys like this - it detects them but does not display them
	;~*WheelUp::
	; ToDo: Pass A_ThisHotkey also?
	ADHD.special_key_pressed(adhd_ctrl)
	return
#If
*/

; Detects Modifiers and Mouse Buttons in BindMode
#If BindMode
	; Detect key down of modifier keys
	*lctrl::
	*rctrl::
	*lalt::
	*ralt::
	*lshift::
	*rshift::
	*lwin::
	*rwin::
		adhd_tmp_modifier := substr(A_ThisHotkey,2)
		ADHD.SetModifier(adhd_tmp_modifier,1)
		return

	; Detect key up of modifier keys
	*lctrl up::
	*rctrl up::
	*lalt up::
	*ralt up::
	*lshift up::
	*rshift up::
	*lwin up::
	*rwin up::
		; Strip * from beginning, " up" from end etc
		adhd_tmp_modifier := substr(substr(A_ThisHotkey,2),1,strlen(A_ThisHotkey) -4)
		if (ADHD.CurrentModifierCount() == 1){
			; If CurrentModifierCount is 1 when an up is received, then that is a Solitary Modifier
			; It cannot be a modifier + normal key, as this code would have quit on keydown of normal key

			ADHD.HKControlType := 1
			ADHD.HKSecondaryInput := adhd_tmp_modifier

			; Send Escape - This will cause the Input command to quit with an EndKey of Escape
			; But we stored the modifier key, so we will know it was not really escape
			Send {Escape}
		}
		ADHD.SetModifier(adhd_tmp_modifier,0)
		return

	; Detect Mouse buttons
	lbutton::
	rbutton::
	mbutton::
	xbutton1::
	xbutton2::
	wheelup::
	wheeldown::
	wheelleft::
	wheelright::
		ADHD.HKControlType := 2
		ADHD.HKSecondaryInput := A_ThisHotkey
		Send {Escape}
		return
#If

