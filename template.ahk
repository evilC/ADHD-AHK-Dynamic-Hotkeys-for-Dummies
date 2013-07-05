; evilC's Macro Template

; Macro authors should only edit blocks between the vvv and ^^^ lines
; vvvvvvvvv
; Like this
; ^^^^^^^^^

; When writing code, as long as none of your function or variable names begin with adh_ then you should not have any conflicts!

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; SETUP SECTION

; Authors - configure this section according to your macro.
; You should not add extra things here (except add more records to adh_hotkeys etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box
adh_macro_name := "Fire Control"					; Change this to your macro name
adh_version := 1.0									; The version number of your script
adh_author := "evilC"								; Your Name
adh_link_text := "HomePage"							; The text of a link to your page about this macro
adh_link_url := "http://evilc.com/proj/firectrl"		; The URL for the homepage of your script

; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
; Set it to blank ("") to disable altogether, DO NOT DELETE!
adh_default_app := "CryENGINE"

; GUI size
adh_gui_w := 375
adh_gui_h := 220

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
adh_hotkeys := []
adh_hotkeys.Insert({uiname: "Fire", subroutine: "Fire"})
adh_hotkeys.Insert({uiname: "Change Fire Rate", subroutine: "ChangeFireRate"})
adh_hotkeys.Insert({uiname: "Weapon Toggle", subroutine: "WeaponToggle"})


if (adh_hotkeys.MaxIndex() < 1){
	msgbox, No Actions defined, Exiting...
	ExitApp
}
Loop, % adh_hotkeys.MaxIndex()
{
	If (IsLabel(adh_hotkeys[A_Index,"subroutine"]) == false){
		msgbox, % "The label`n`n" adh_hotkeys[A_Index,"subroutine"] ":`n`n does not appear in the script.`nExiting..."
		ExitApp
	}

}

; End Setup section
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
; Debug vars
adh_debug_mode := 0
adh_debug_window := 0
adh_debug_ready := 0
adh_log_contents := ""
; Indicates that we are starting up - ignore errant events, always log until we have loaded settings etc use this value
adh_starting_up := 1

ADH.debug("Starting up...")
adh_num_hotkeys := adh_hotkeys.MaxIndex()
adh_app_act_curr := 0						; Whether the current app is the "Limit To" app or not

; ToDo:
; BUGS:

; Before next release:

; Features:

; Long-term:
; Can you use "% myvar" notation in guicontrols? Objects of guicontrols would be better
; Perform checking on adh_hotkeys to ensure sane values (No dupes, labels do not already exist etc)
; Replace label names in ini with actual label names instead of 1, 2, 3 ?

; Start ADH init vars and settings
adh_core_version := 0.3

; Variables to be stored in the INI file - will be populated by code later
; [Variable Name, Control Type, Default Value]
; eg ["MyControl","Edit","None"]
adh_ini_vars := []
; Holds a REFERENCE copy of the hotkeys so authors can access the info (to eg send a keyup after the trigger key is pressed)
adh_hotkey_mappings := {}

#InstallKeybdHook
#InstallMouseHook
#MaxHotKeysPerInterval, 200

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; Make sure closing the GUI using X exits the script
OnExit, GuiClose

; List of mouse buttons
adh_mouse_buttons := "LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight"

IniRead, adh_gui_x, %A_ScriptName%.ini, Settings, gui_x, unset
IniRead, adh_gui_y, %A_ScriptName%.ini, Settings, gui_y, unset
if (adh_gui_x == "unset"){
	msgbox, Welcome to this ADH based macro.`n`nThis window is appearing because no settings file was detected, one will now be created in the same folder as the script`nIf you wish to have an icon on your desktop, it is recommended you place this file somewhere other than your desktop and create a shortcut, to avoid clutter or accidental deletion.`n`nIf you need further help, look in the About tab for links to Author(s) sites.`nYou may find help there, you may also find a Donate button...
	adh_gui_x := 0	; initialize
}
if (adh_gui_y == "unset"){
	adh_gui_y := 0
}

if (adh_gui_x == ""){
	adh_gui_x := 0	; in case of crash empty values can get written
}
if (adh_gui_y == ""){
	adh_gui_y := 0
}

; Get list of profiles
IniRead, adh_profile_list, %A_ScriptName%.ini, Settings, profile_list, Default
; Get current profile
IniRead, adh_current_profile, %A_ScriptName%.ini, Settings, current_profile, Default

; Set up the GUI ====================================================
Gui, Add, Tab2, x0 w%adh_gui_w% h%adh_gui_h% gadh_tab_changed, Main|Bindings|Profiles|About

adh_tabtop := 40
adh_current_row := adh_tabtop + 20

Gui, Tab, 1
; MAIN TAB
; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; AUTHORS - PLACE CUSTOM GUI ITEMS IN HERE
; If you want their state saved in the ini file, add a line like this after you add the control:
; adh_ini_vars.Insert(["MyControl","DropDownList",1])
; The format is Name, Control Type, Default Value
; DO NOT give a control the same name as one of your hotkeys (eg Fire, ChangeFireRate)

Gui, Add, Text, x5 y%adh_tabtop%, Fire Sequence
Gui, Add, Edit, xp+120 yp W120 vFireSequence gadh_option_changed,
adh_ini_vars.Insert(["FireSequence","Edit",""])
FireSequence_TT := "A comma separated list of keys to hit - eg 1,2,3,4"

Gui, Add, Text, x5 yp+25, Fire Rate (ms)
Gui, Add, Edit, xp+120 yp W120 vFireRate gadh_option_changed,
adh_ini_vars.Insert(["FireRate","Edit",100])

Gui, Add, Text, x5 yp+25, Weapon Toggle group
Gui, Add, DropDownList, xp+120 yp-2 W50 vWeaponToggle gadh_mouse_changed, None|1|2|3|4|5|6
adh_ini_vars.Insert(["WeaponToggle","DropDownList","None"])

Gui, Add, CheckBox, x5 yp+30 vLimitFire gadh_option_changed, Limit fire rate to specified rate (Stop "Over-Clicking")
adh_ini_vars.Insert(["LimitFire","CheckBox",0])

Gui, Add, Link, x5 yp+35, Works with many games, perfect for <a href="http://mwomercs.com">MechWarrior Online</a> (FREE GAME!)

adh_tmp := adh_gui_h - 40
Gui, Add, Link, x5 y%adh_tmp%, <a href="http://evilc.com/proj/adh">ADH Instructions</a>    <a href="http://evilc.com/proj/firectrl">%adh_macro_name% Instructions</a>


; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Gui, Tab, 2
; BINDINGS TAB
Gui, Add, Text, x5 y40 W100 Center, Action
Gui, Add, Text, xp+100 W70 Center, Keyboard
Gui, Add, Text, xp+90 W70 Center, Mouse
Gui, Add, Text, xp+82 W30 Center, Ctrl
Gui, Add, Text, xp+30 W30 Center, Shift
Gui, Add, Text, xp+30 W30 Center, Alt

; Add hotkeys
Loop, % adh_hotkeys.MaxIndex()
{
	adh_tmpname := adh_hotkeys[A_Index,"uiname"]
	Gui, Add, Text,x5 W100 y%adh_current_row%, %adh_tmpname%
	Gui, Add, Hotkey, yp-5 xp+100 W70 vadh_hk_k_%A_Index% gadh_key_changed
	Gui, Add, DropDownList, yp xp+80 W90 vadh_hk_m_%A_Index% gadh_mouse_changed, None||%adh_mouse_buttons%
	Gui, Add, CheckBox, xp+100 yp+5 W25 vadh_hk_c_%A_Index% gadh_option_changed
	Gui, Add, CheckBox, xp+30 yp W25 vadh_hk_s_%A_Index% gadh_option_changed
	Gui, Add, CheckBox, xp+30 yp W25 vadh_hk_a_%A_Index% gadh_option_changed
	adh_current_row := adh_current_row + 30
}

; Limit application toggle
Gui, Add, CheckBox, x5 yp+25 W160 vadh_limit_application_on gadh_option_changed, Limit to Application: ahk_class

; Limit application Text box
Gui, Add, Edit, xp+170 yp+2 W120 vadh_limit_application gadh_option_changed,

; Launch window spy
Gui, Add, Button, xp+125 yp-1 W15 gadh_show_window_spy, ?
adh_limit_application_TT := "Enter a value here to make hotkeys only trigger when a specific application is open.`nUse the window spy (? Button to the right) to find the ahk_class of your application.`nCaSe SenSitIve !!!"

; Program mode toggle
Gui, Add, Checkbox, x5 yp+30 vadh_program_mode gadh_program_mode_changed, Program Mode
adh_program_mode_TT := "Turns on program mode and lets you program keys. Turn off again to enable hotkeys"


Gui, Tab, 3
; PROFILES TAB
adh_current_row := adh_tabtop + 20
Gui, Add, Text,x5 W40 y%adh_current_row%,Profile
Gui, Add, DropDownList, xp+35 yp-5 W150 vadh_current_profile gadh_profile_changed, Default||%adh_profile_list%
Gui, Add, Button, xp+152 yp-1 gadh_add_profile, Add
Gui, Add, Button, xp+35 yp gadh_delete_profile, Delete
Gui, Add, Button, xp+47 yp gadh_duplicate_profile, Copy
Gui, Add, Button, xp+40 yp gadh_rename_profile, Rename
GuiControl,ChooseString, adh_current_profile, %adh_current_profile%

Gui, Tab, 4
; ABOUT TAB
adh_current_row := adh_tabtop + 20
Gui, Add, Link,x5 y%adh_current_row%, This macro was created using AHK Dynamic Hotkeys by Clive "evilC" Galway
Gui, Add, Link,x5 yp+25, <a href="http://evilc.com/proj/adh">HomePage</a>    <a href="https://github.com/evilC/AHK-Dynamic-Hotkeys">GitHub Page</a>
Gui, Add, Link,x5 yp+35, This macro ("%adh_macro_name%") was created by %adh_author%
Gui, Add, Link,x5 yp+25, <a href="%adh_link_url%">%adh_link_text%</a>

Gui, Tab

; Add a Status Bar for at-a-glance current profile readout
Gui, Add, StatusBar,,


; Show the GUI =====================================
Gui, Show, x%adh_gui_x% y%adh_gui_y% w%adh_gui_w% h%adh_gui_h%, %adh_macro_name% v%adh_version% (ADH v%adh_core_version%)

;Hook for Tooltips
OnMessage(0x200, "adh_mouse_move")

; Add Debug window controls
Gui, Tab
adh_tmp := adh_gui_w - 90
Gui, Add, CheckBox, x%adh_tmp% y10 vadh_debug_window gadh_debug_window_change, Show Window
	
adh_tmp := adh_gui_w - 180
Gui, Add, CheckBox, x%adh_tmp% y10 vadh_debug_mode gadh_debug_change, Debug Mode
	
; Fire GuiSubmit while adh_starting_up is on to set all the variables
Gui, Submit, NoHide

; Create the debug GUI, but do not show yet
adh_tmp := adh_gui_w - 30
Gui, 2:Add,Edit,w%adh_tmp% h350 vadh_log_contents ReadOnly,
Gui, 2:Add, Button, gadh_clear_log, clear
adh_debug_ready := 1

; Finish setup =====================================
GoSub, adh_profile_changed
ADH.debug_window_change()

ADH.debug("Finished startup")

; Finished startup, allow change of controls to fire events
adh_starting_up := 0

return

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; AUTHORS - PLACE YOUR HOTKEY DEFINITIONS AND ASSOCIATED FUNCTIONS HERE
; When writing code, DO NOT create variables or functions starting adh_
; You can use the existing ones obviously

; Initialize your variables and stuff here
adh_init_author_vars:
	fire_array := []
	current_weapon := 1
	fire_divider := 1
	nextfire := 0		; A timer for when we are next allowed to press the fire button
	weapon_toggle_mode := false
	Gosub, ResetToggle
	return
	
; This is fired when settings change (including on load). Use it to pre-calculate values etc.
; DO NOT delete it entirely or remove it. It can be empty though
adh_change_event:
	; This gets called in Program Mode, so now would be a good time to re-initialize
	Gosub, adh_init_author_vars
	StringSplit, adh_tmp, FireSequence, `,
	Loop, %adh_tmp0%
	{
		if (adh_tmp%A_Index% != ""){
			fire_array[A_Index] := adh_tmp%A_Index%
		}
	}
	return

; Hotkey block - this is where you define labels that the various bindings trigger
; Make sure you call them the same names as you set in the settings at the top of the file (eg Fire, FireRate)

; Set up HotKey 1

; Fired on key down
Fire:
	; Many games do not work properly with autofire unless this is enabled.
	; You can try leaving it out.
	; MechWarrior Online for example will not do fast (<~500ms) chain fire with weapons all in one group without this enabled
	ADH.send_keyup_on_press("Fire","unmodified")


	; If we clicked the button too early, play a sound and schedule a click when it is OK to fire
	; If the user releases the button, the timer will terminate
	if (A_TickCount < nextfire){
		soundplay, *16
		SetFireTimer(1,true)
		return
	}
	
	; Fire Lazors !!!
	GoSub, DoFire

	; Start the fire timer
	SetFireTimer(1,false)
	return

; Fired on key up
FireUp:
	; Kill the timer when the key is released (Stop auto firing)
	SetFireTimer(0,false)
	return

; Set up HotKey 2

; Fired on key down
ChangeFireRate:
	; More Lazors!! Toggles double speed fire!
	; Toggle divider between 1 and 2
	fire_divider := 3 - fire_divider
	return

; Set up Hotkey 3
WeaponToggle:
	weapon_toggle_mode := !weapon_toggle_mode
	if (weapon_toggle_mode){
		Gosub, EnableToggle
	} else {
		Gosub, DisableToggle
	}
	return
	
	
; End Hotkey block ====================

; Timers need a label to go to, so handle firing in here...
DoFire:
	; Turn the timer off and on again so that if we change fire rate it takes effect after the next fire
	Gosub, DisableTimers
		
	out := fire_array[current_weapon]
	Send {%out%}
	tmp := FireRate / fire_divider
	SetTimer, DoFire, % tmp
	nextfire := A_TickCount + (tmp)

	current_weapon := current_weapon + 1
	if (current_weapon > fire_array.MaxIndex()){
		current_weapon := 1
	}
	return

; used to start or stop the fire timer
SetFireTimer(mode,delay){
	global FireRate
	global nextfire
	global fire_divider
	
	if(mode == 0){
		Gosub, DisableTimers
	} else {
		tim := (FireRate / fire_divider)
		if (delay == false){
			SetTimer, DoFire, %tim%
		} else {
			SetTimer, DoFire, % nextfire - A_TickCount
		}
	}
}

EnableToggle:
	SetScrollLockState, On
	Send {%WeaponToggle% down}
	return

; Put disable toggle code in here so when we leave app we can call it
DisableToggle:
	SetScrollLockState, Off
	Send {%WeaponToggle% up}
	return

; ResetToggle is used to just unset the light
; Using the normal disable while editing an editbox moves the cursor to the start
ResetToggle:
	SetScrollLockState, Off
	return

; Keep this duplicate label here so ADH can stop any timers you start
adh_disable_author_timers:
; Keep all timer disables in here so when we leave app we can stop timers
DisableTimers:
	SetTimer, DoFire, Off
	return
	
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; === SHOULD NOT NEED TO EDIT BELOW HERE! ===========================================================================

Class ADH
{
	; ADH Library
	
	; aka load profile
	profile_changed(){
		global adh_current_profile
		global adh_hotkey_mappings
		global adh_num_hotkeys
		global adh_hotkeys
		global adh_default_app
		global adh_limit_application
		global adh_limit_application_on
		global adh_ini_vars
		global adh_debug_mode
		global adh_debug_window
		
		this.debug("profile_changed")
		Gui, Submit, NoHide

		this.update_ini("current_profile", "Settings", adh_current_profile,"")
		
		SB_SetText("Current profile: " adh_current_profile) 
		
		adh_hotkey_mappings := {}
		
		; Load hotkey bindings
		Loop, % adh_num_hotkeys
		{
			adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]] := {}
			adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]]["index"] := A_Index

			; Keyboard bindings
			tmp := this.read_ini("adh_hk_k_" A_Index,adh_current_profile,A_Space)
			GuiControl,,adh_hk_k_%A_Index%, %tmp%
			adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]]["unmodified"] := tmp
			
			; Mouse bindings
			tmp := this.read_ini("adh_hk_m_" A_Index,adh_current_profile,A_Space)
			GuiControl, ChooseString, adh_hk_m_%A_Index%, %tmp%
			if (tmp != "None"){
				adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]]["unmodified"] := tmp
			}

			; Control Modifier
			adh_modstring := ""
			tmp := this.read_ini("adh_hk_c_" A_Index,adh_current_profile,0)
			GuiControl,, adh_hk_c_%A_Index%, %tmp%
			if (tmp == 1){
				adh_modstring := adh_modstring "^"
			}
			
			; Shift Modifier
			tmp := this.read_ini("adh_hk_s_" A_Index,adh_current_profile,0)
			GuiControl,, adh_hk_s_%A_Index%, %tmp%
			if (tmp == 1){
				adh_modstring := adh_modstring "+"
			}
			
			; Alt Modifier
			tmp := this.read_ini("adh_hk_a_" A_Index,adh_current_profile,0)
			GuiControl,, adh_hk_a_%A_Index%, %tmp%
			if (tmp == 1){
				adh_modstring := adh_modstring "!"
			}
			adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]]["modified"] := adh_modstring adh_hotkey_mappings[adh_hotkeys[A_Index,"subroutine"]]["unmodified"]
		}
		
		; limit application name
		this.remove_glabel("adh_limit_application")
		if (adh_default_app == "" || adh_default_app == null){
			adh_default_app := A_Space
		}
		tmp := this.read_ini("adh_limit_app",adh_current_profile,adh_default_app)
		GuiControl,, adh_limit_application, %tmp%
		this.add_glabel("adh_limit_application")
		
		; limit application status
		tmp := this.read_ini("adh_limit_app_on",adh_current_profile,0)
		GuiControl,, adh_limit_application_on, %tmp%
		
		; Get author vars from ini
		Loop, % adh_ini_vars.MaxIndex()
		{
			adh_def := adh_ini_vars[A_Index,3]
			if (adh_def == ""){
				adh_def := A_Space
			}
			adh_key := adh_ini_vars[A_Index,1]
			adh_sm := this.control_name_to_set_method(adh_ini_vars[A_Index,2])
			
			this.remove_glabel(adh_key)
			tmp := this.read_ini(adh_key,adh_current_profile,adh_def)
			GuiControl,%adh_sm%, %adh_key%, %tmp%
			this.add_glabel(adh_key)
		}

		; Debug settings
		adh_debug_mode := this.read_ini("adh_debug_mode","Settings",0)
		GuiControl,, adh_debug_mode, %adh_debug_mode%
		
		adh_debug_window := this.read_ini("adh_debug_window","Settings",0)
		GuiControl,, adh_debug_window, %adh_debug_window%

		this.program_mode_changed()
		
		Gosub, adh_change_event

		return
	}

	; aka save profile
	option_changed(){
		global adh_starting_up
		global adh_num_hotkeys
		global adh_current_profile
		global adh_profile_list
		global adh_default_app
		global adh_limit_application
		global adh_limit_application_on
		global adh_ini_vars
		global adh_debug_mode
		global adh_debug_window
		
		if (adh_starting_up != 1){
			this.debug("option_changed - control: " A_guicontrol)
			
			Gui, Submit, NoHide

			; Hotkey bindings
			Loop, % adh_num_hotkeys
			{
				this.update_ini("adh_hk_k_" A_Index, adh_current_profile, adh_hk_k_%A_Index%, "")
				this.update_ini("adh_hk_m_" A_Index, adh_current_profile, adh_hk_m_%A_Index%, "None")
				this.update_ini("adh_hk_c_" A_Index, adh_current_profile, adh_hk_c_%A_Index%, 0)
				this.update_ini("adh_hk_s_" A_Index, adh_current_profile, adh_hk_s_%A_Index%, 0)
				this.update_ini("adh_hk_a_" A_Index, adh_current_profile, adh_hk_a_%A_Index%, 0)
			}
			this.update_ini("profile_list", "Settings", adh_profile_list,"")
			
			; Limit app
			if (adh_default_app == "" || adh_default_app == null){
				adh_default_app := A_Space
			}
			this.update_ini("adh_limit_app", adh_current_profile, adh_limit_application, adh_default_app)
			SB_SetText("Current profile: " adh_current_profile)
			
			; Limit app toggle
			this.update_ini("adh_limit_app_on", adh_current_profile, adh_limit_application_on, 0)
			
			; Add author vars to ini
			Loop, % adh_ini_vars.MaxIndex()
			{
				tmp := adh_ini_vars[A_Index,1]
				this.update_ini(tmp, adh_current_profile, %tmp%, adh_ini_vars[A_Index,3])
			}
			Gosub, adh_change_event
			
			; Debug settings
			this.update_ini("adh_debug_mode", "settings", adh_debug_mode, 0)
			this.update_ini("adh_debug_window", "settings", adh_debug_window, 0)
			
		} else {
			this.debug("ignoring option_changed - " A_Guicontrol)
		}
		return
	}

	; Add and remove glabel is useful because:
	; When you use GuiControl to set the contents of an edit...
	; .. it's glabel is fired.
	; So remove glabel, set editbox value, re-add glabel to solve
	add_glabel(ctrl){
		GuiControl, +gadh_option_changed, %ctrl%
	}

	remove_glabel(ctrl){
		GuiControl, -g, %ctrl%
	}

	; Profile management - functions to manage preserving user settings
	add_profile(name){
		global adh_profile_list
		
		if (name == ""){
			InputBox, name, Profile Name, Please enter a profile name
			if (ErrorLevel){
				return
			}
		}
		if (adh_profile_list == ""){
			adh_profile_list := name
		} else {
			adh_profile_list := adh_profile_list "|" name
		}
		Sort, adh_profile_list, D|
		
		GuiControl,, adh_current_profile, |Default||%adh_profile_list%
		GuiControl,ChooseString, adh_current_profile, %name%
		
		this.update_ini("profile_list", "Settings", adh_profile_list, "")
	}

	delete_profile(name, gotoprofile = "Default"){
		Global adh_profile_list
		Global adh_current_profile
		
		if (name != "Default"){
			StringSplit, tmp, adh_profile_list, |
			out := ""
			Loop, %tmp0%{
				if (tmp%a_index% != name){
					if (out != ""){
						out := out "|"
					}
					out := out tmp%a_index%
				}
			}
			adh_profile_list := out
			
			IniDelete, %A_ScriptName%.ini, %name%
			this.update_ini("profile_list", "Settings", adh_profile_list, "")		
			
			; Set new contents of list
			GuiControl,, adh_current_profile, |Default|%adh_profile_list%
			
			; Select the desired new current profile
			GuiControl, ChooseString, adh_current_profile, %gotoprofile%
			
			; Trigger save
			Gui, Submit, NoHide
			
			; Trigger Author Event
			Gosub, adh_profile_changed
		}
		return
	}

	duplicate_profile(name){
		global adh_profile_list
		global adh_current_profile
		
		; Blank name specified - prompt for name
		if (name == ""){
			InputBox, name, Profile Name, Please enter a profile name
			if (ErrorLevel){
				return
			}
		}
		; ToDo: Duplicate - should just need to be able to change current name and save?
		
		; Create the new item in the profile list
		if (adh_profile_list == ""){
			adh_profile_list := name
		} else {
			adh_profile_list := adh_profile_list "|" name
		}
		Sort, adh_profile_list, D|
		
		adh_current_profile := name
		; Push the new list to the profile select box
		GuiControl,, adh_current_profile, |Default||%adh_profile_list%
		; Set the new profile to the currently selected item
		GuiControl,ChooseString, adh_current_profile, %name%
		; Update the profile list in the INI
		this.update_ini("profile_list", "Settings", adh_profile_list, "")
		
		; Firing adh_option_changed saves the current state to the new profile name in the INI
		this.debug("duplicate_profile calling option_changed")
		Gosub, adh_option_changed

		return
	}

	rename_profile(){
		global adh_current_profile
		
		if (adh_current_profile != "Default"){
			old_prof := adh_current_profile
			InputBox, new_prof, Profile Name, Please enter a new name
			if (!ErrorLevel){
				this.duplicate_profile(new_prof)
				this.delete_profile(old_prof,new_prof)
			}
		}
		return
	}

	; End profile management

	; For some games, they will not let you autofire if the triggering key is still held down...
	; even if the triggering key is not the key sent and does nothing in the game!
	; Often a workaround is to send a keyup of the triggering key
	; Calling send_keyup_on_press() in an action will cause this to happen
	send_keyup_on_press(sub,mod){
		global adh_hotkey_mappings
		; adh_hotkey_mappings contains a handy lookup to hotkey mappings !
		; contains "modified" and "unmodified" keys
		; Note, it is REFERENCE ONLY. Changing it has no effect.
		tmp := adh_hotkey_mappings[sub][mod] " up"
		Send {%tmp%}

	}

	tab_changed(){
		global adh_program_mode
		
		; If in program mode on tab change, disable program mode
		if (adh_program_mode == 1){
			GuiControl,,adh_program_mode,0
			this.program_mode_changed()
		}
		return
	}

	; Converts a Control name (eg DropDownList) into the parameter passed to GuiControl to set that value (eg ChooseString)
	control_name_to_set_method(name){
		if (name == "DropDownList"){
			return "ChooseString"
		} else {
			return ""
		}
	}

	key_changed(){
		tmp := %A_GuiControl%
		ctr := 0
		max := StrLen(tmp)
		Loop, %max%
		{
			chr := substr(tmp,ctr,1)
			if (chr != "^" && chr != "!" && chr != "+"){
				ctr := ctr + 1
			}
		}
		; Only modifier keys pressed?
		if (ctr == 0){
			return
		}
		
		; key pressed
		if (ctr < max){
			GuiControl,, %A_GuiControl%, None
			this.debug("key_changed calling option_changed")
			Gosub, adh_option_changed
		}
		else
		{
			tmp := SubStr(A_GuiControl,10)
			; Set the mouse field to blank
			GuiControl,ChooseString, adh_hk_m_%tmp%, None
			this.debug("key_changed calling option_changed")
			Gosub, adh_option_changed
		}
		return
	}

	mouse_changed(){
		tmp := SubStr(A_GuiControl,10)
		; Set the keyboard field to blank
		GuiControl,, adh_hk_k_%tmp%, None
		this.debug("mouse_changed calling option_changed")
		Gosub, adh_option_changed
		return
	}

	; INI manipulation
	
	; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
	update_ini(key, section, value, default){
		tmp := A_ScriptName ".ini"
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
		IniRead, out, %A_ScriptName%.ini, %section%, %key%, %default%
		return out
	}

	; Called on app exit
	exit_app(){	
		Gui, +Hwndgui_id
		WinGetPos, gui_x, gui_y,,, ahk_id %gui_id%
		if (this.read_ini("gui_x","Settings", -1) != gui_x){
			IniWrite, %gui_x%, %A_ScriptName%.ini, Settings, gui_x
		}
		if (this.read_ini("gui_y","Settings", -1) != gui_y){
			IniWrite, %gui_y%, %A_ScriptName%.ini, Settings, gui_y
		}
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
		global adh_debug_window
		global adh_gui_x
		global adh_gui_y
		global adh_gui_w
		global adh_gui_h
		global adh_starting_up
		
		gui, submit, nohide
		if (adh_debug_window == 1){
			tmp := adh_gui_y - 440
			Gui, 2:Show, x%adh_gui_x% y%tmp% w%adh_gui_w% h400, ADH Debug Window
		} else {
			gui, 2:hide
		}
		; On startup do not call adh_option_changed, we are just setting the window open or closed
		if (!adh_starting_up){
			gosub, adh_option_changed
		}
		return
	}

	debug_change(){
		gui, 2:submit, nohide
		gosub, adh_option_changed
		return
	}

	debug(msg){
		global adh_log_contents
		global adh_debug_mode
		global adh_starting_up
		global adh_debug_ready

		; If in debug mode, or starting up...
		if (adh_debug_mode || adh_starting_up){
			adh_log_contents := adh_log_contents "* " msg "`n"
			if (adh_debug_ready){
				guicontrol,2:,adh_log_contents, % adh_log_contents
				gui, 2:submit, nohide
			}
		}
	}

	; Program mode stuff
	program_mode_changed(){
		global adh_limit_application
		global adh_limit_application_on
		global adh_program_mode
		
		;adh_debug("program_mode_changed")
		Gui, Submit, NoHide
		
		if (adh_program_mode == 1){
			;adh_debug("Entering Program Mode")
			; Enable controls, stop hotkeys, kill timers
			GoSub, adh_disable_hotkeys
			Gosub, adh_disable_author_timers
			this.disable_heartbeat()
			GuiControl, enable, adh_limit_application
			GuiControl, enable, adh_limit_application_on
		} else {
			; Disable controls, start hotkeys, start heartbeat timer
			;adh_debug("Exiting Program Mode")
			GoSub, adh_enable_hotkeys
			this.enable_heartbeat()
			GuiControl, disable, adh_limit_application
			GuiControl, disable, adh_limit_application_on
		}
		return
	}

	; App detection stuff
	enable_heartbeat(){
		;adh_debug("Enabling Heartbeat")
		global adh_limit_application
		global adh_limit_application_on
		
		if (adh_limit_application_on == 1 && adh_limit_application != ""){
			SetTimer, adh_heartbeat, 500
		}
		return
	}

	disable_heartbeat(){
		;adh_debug("Disabling Heartbeat")
		SetTimer, adh_heartbeat, Off
		return
	}

	heartbeat(){
		global adh_limit_application
		
		; Check current app here.
		; Not used to enable or disable hotkeys, used to start or stop author macros etc
		IfWinActive, % "ahk_class " adh_limit_application
		{
			this.app_active(1)
		}
		else
		{
			this.app_active(0)
		}
		return
	}

	app_active(act){
		Global adh_app_act_curr
		
		if (act){
			if (adh_app_act_curr != 1){
				; Changing from inactive to active
				adh_app_act_curr := 1
			}
		} else {
			if (adh_app_act_curr != 0){
				; Changing from active to inactive
				; Stop Author Timers
				Gosub, adh_disable_author_timers
				; Reset author macro
				Gosub, adh_init_author_vars
				adh_app_act_curr := 0
			}
		}
	}


}


adh_profile_changed:
	ADH.profile_changed()
	return


adh_option_changed:
	ADH.option_changed()
	return


adh_add_profile:
	ADH.add_profile("")	; just clicking the button calls with empty param
	return

; Delete Profile pressed
adh_delete_profile:
	ADH.delete_profile(adh_current_profile)	; Just clicking the button deletes the current profile
	return


adh_duplicate_profile:
	ADH.duplicate_profile("")
	return
	
adh_rename_profile:
	ADH.rename_profile()
	return


adh_tab_changed:
	ADH.tab_changed()
	return

adh_key_changed:
	ADH.key_changed()
	return

adh_mouse_changed:
	ADH.mouse_changed()
	return


adh_get_hotkey_string(hk){
	;Get hotkey string - could be keyboard or mouse
	tmp := adh_hk_k_%hk%
	if (tmp == ""){
		tmp := adh_hk_m_%hk%
		if (tmp == "None"){
			tmp := ""
		}
	}
	return tmp
}

adh_enable_hotkeys:
	adh_enable_hotkeys()
	return

adh_enable_hotkeys(){
	global adh_num_hotkeys
	global adh_limit_application
	global adh_limit_application_on
	global adh_hotkeys
	
	; ToDo: Should not submit gui here, triggering save...
	;adh_debug("enable_hotkeys")

	Gui, Submit, NoHide
	Loop, % adh_num_hotkeys
	{
		hotkey_prefix := adh_build_prefix(A_Index)
		hotkey_keys := adh_get_hotkey_string(A_Index)
		
		if (hotkey_keys != ""){
			hotkey_string := hotkey_prefix hotkey_keys
			hotkey_subroutine := adh_hotkeys[A_Index,"subroutine"]
			if (adh_limit_application_on == 1){
				if (adh_limit_application !=""){
					; Enable Limit Application for all subsequently declared hotkeys
					Hotkey, IfWinActive, ahk_class %adh_limit_application%
				}
			} else {
				; Disable Limit Application for all subsequently declared hotkeys
				Hotkey, IfWinActive
			}
			
			; Bind down action of hotkey
			Hotkey, ~%hotkey_string% , %hotkey_subroutine%
			
			if (IsLabel(hotkey_subroutine "Up")){
				; Bind up action of hotkey
				Hotkey, ~%hotkey_string% up , %hotkey_subroutine%Up
			}
			; ToDo: Up event does not fire for wheel "buttons" - send dupe event or something?
		}
		
		; ToDo: Disabling of GUI controls should not be in here - put them in program mode
		GuiControl, Disable, adh_hk_k_%A_Index%
		GuiControl, Disable, adh_hk_m_%A_Index%
		GuiControl, Disable, adh_hk_c_%A_Index%
		GuiControl, Disable, adh_hk_s_%A_Index%
		GuiControl, Disable, adh_hk_a_%A_Index%
	}
	return
}

adh_disable_hotkeys:
	adh_disable_hotkeys()
	return

adh_disable_hotkeys(){
	global adh_num_hotkeys
	global adh_limit_application
	global adh_limit_application_on
	global adh_hotkeys
	
	;adh_debug("disable_hotkeys")

	Loop, % adh_num_hotkeys
	{
		hotkey_prefix := adh_build_prefix(A_Index)
		hotkey_keys :=  := adh_get_hotkey_string(A_Index)
		if (hotkey_keys != ""){
			hotkey_string := hotkey_prefix hotkey_keys
			; ToDo: Is there a better way to remove a hotkey?
			HotKey, ~%hotkey_string%, adh_do_nothing
			if (IsLabel(hotkey_subroutine "Up")){
				; Bind up action of hotkey
				HotKey, ~%hotkey_string% up, adh_do_nothing
			}
		}
		GuiControl, Enable, adh_hk_k_%A_Index%
		GuiControl, Enable, adh_hk_m_%A_Index%
		GuiControl, Enable, adh_hk_c_%A_Index%
		GuiControl, Enable, adh_hk_s_%A_Index%
		GuiControl, Enable, adh_hk_a_%A_Index%
	}
	return
}

; An empty stub to redirect unbound hotkeys to
adh_do_nothing:
	return

adh_build_prefix(hk){
	out := ""
	tmp = adh_hk_c_%hk%
	GuiControlGet,%tmp%
	if (adh_hk_c_%hk% == 1){
		out := out "^"
	}
	if (adh_hk_a_%hk% == 1){
		out := out "!"
	}
	if (adh_hk_s_%hk% == 1){
		out := out "+"
	}
	return out
}
	

; Kill the macro if the GUI is closed
adh_exit_app:
GuiClose:
	ADH.exit_app()
	return

adh_show_window_spy:
	ADH.show_window_spy()
	return

adh_debug_window_change:
	ADH.debug_window_change()
	return

adh_debug_change:
	ADH.debug_change()
	return
	
adh_clear_log:
	adh_log_contents := ""
	GuiControl,,adh_log_contents,%adh_log_contents%
	return

adh_program_mode_changed:
	ADH.program_mode_changed()
	return

adh_heartbeat:
	ADH.heartbeat()
	return
	

; ==========================================================================================================================
; Code from http://www.autohotkey.com/board/topic/47439-user-defined-dynamic-hotkeys/
; This code enables extra keys in a Hotkey GUI control
#MenuMaskKey vk07                 ;Requires AHK_L 38+
#If ctrl := adh_hotkey_ctrl_has_focus()
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
	adh_modifier := ""
	If GetKeyState("Shift","P")
		adh_modifier .= "+"
	If GetKeyState("Ctrl","P")
		adh_modifier .= "^"
	If GetKeyState("Alt","P")
		adh_modifier .= "!"
	Gui, Submit, NoHide											;If BackSpace is the first key press, Gui has never been submitted.
	If (A_ThisHotkey == "*BackSpace" && %ctrl% && !adh_modifier)	;If the control has text but no modifiers held,
		GuiControl,,%ctrl%                                      ;  allow BackSpace to clear that text.
	Else                                                     	;Otherwise,
		GuiControl,,%ctrl%, % adh_modifier SubStr(A_ThisHotkey,2)	;  show the hotkey.
	;validateHK(ctrl)
	ADH.debug("special key detect calling option_changed")
	Gosub, adh_option_changed
	return
#If

adh_hotkey_ctrl_has_focus() {
	GuiControlGet, ctrl, Focus       ;ClassNN
	If InStr(ctrl,"hotkey") {
		GuiControlGet, ctrl, FocusV     ;Associated variable
		Return, ctrl
	}
}
	
; Tooltip function from http://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry598735
adh_mouse_move(){
	static CurrControl, PrevControl, _TT
	CurrControl := A_GuiControl
	If (CurrControl <> PrevControl){
			SetTimer, DisplayToolTip, -750 	; shorter wait, shows the tooltip faster
			PrevControl := CurrControl
	}
	return
	
	DisplayToolTip:
	try
			ToolTip % %CurrControl%_TT
	catch
			ToolTip
	SetTimer, RemoveToolTip, -10000
	return
	
	RemoveToolTip:
	ToolTip
	return
}
