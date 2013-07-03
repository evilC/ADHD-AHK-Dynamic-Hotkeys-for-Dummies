; evilC's Macro Template

; Macro authors should only edit blocks between the vvv and ^^^ lines
; vvvvvvvvv
; Like this
; ^^^^^^^^^

; When writing code, as long as none of your function or variable names begin with adh_ then you should not have any conflicts!

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; SETUP SECTION

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box
adh_macro_name := "My Macro"			; Change this to your macro name
adh_version := 0.1						; The version number of your script
adh_author := "Insert Name Here"		; Your Name
adh_link_text := "HomePage"				; The text of a link to your page about this macro
adh_link_url := "http://google.com"		; The URL for the homepage of your script

; GUI size
adh_gui_w := 375
adh_gui_h := 150

; Number of Hotkeys
adh_num_hotkeys := 2
; Defines your hotkeys 
; The first item in each pair is what to display to the user in the UI
; The second item in each pair is the name of the subroutine called when it is triggered
adh_hotkeys := [["Fire","Fire"],["Change Fire Rate","ChangeFireRate"]]

; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; ToDo:
; Add option to limit controls to only a specific window
;Hotkey, IfWinActive, ahk_class CryENGINE
; Give macro authors a way to find out what hotkey is bound to a function (eg to send hotkey up when doing autofire)
; Allow macro authors to not have to specify an up label (Use IsLabel() to detect if label exists)
; Perform checking on adh_hotkeys to ensure sane values (No dupes, labels do not already exist etc)
; Add explanation somewhere that all hotkeys are passthroughs
; Check if labels exist on start (like AHK already does) but provide easier to understand explanation if not found ("Add a label for your hotkeys!")

adh_core_version := 0.1
; [Variable Name, Control Type, Default Value]
; eg ["MyControl","Edit","None"]
adh_ini_vars := []

#InstallKeybdHook
#InstallMouseHook
#MaxHotKeysPerInterval, 200

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.
 
OnExit, adh_gui_close

adh_mouse_buttons := "LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight"

adh_ignore_events := 1	; Setting this to 1 while we load the GUI allows us to ignore change messages generated while we build the GUI

IniRead, adh_gui_x, %A_ScriptName%.ini, Settings, gui_x, 0
IniRead, adh_gui_y, %A_ScriptName%.ini, Settings, gui_y, 0
if (adh_gui_x == ""){
	adh_gui_x := 0	; in case of crash empty values can get written
}
if (adh_gui_y == ""){
	adh_gui_y := 0
}

; Set up the GUI

Gui, Add, Tab2, x0 w%adh_gui_w% h%adh_gui_h%, Main|Bindings|Profiles|About

adh_tabtop := 40
adh_current_row := adh_tabtop + 20

Gui, Tab, 1
; MAIN TAB
; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; PLACE CUSTOM GUI ITEMS IN HERE

Gui, Add, Text, x5 y%adh_tabtop%, Weapon Group
Gui, Add, DropDownList, xp+80 yp-5 W30 vWeaponGroup gadh_option_changed, 1||2|3|4|5|6
; Add the previous control to adh_ini_vars so it gets stored in the INI file
; The format is Name, Control Type, Default Value
adh_ini_vars.Insert(["WeaponGroup","DropDownList",1])

Gui, Add, Text, x5 yp+25, Fire Rate (ms)
Gui, Add, Edit, xp+80 yp W40 vFireRate gadh_option_changed
adh_ini_vars.Insert(["FireRate","Edit",100])

; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
Gui, Tab, 2
; BINDINGS TAB
Gui, Add, Text, x5 y40 W100 Center, Name
Gui, Add, Text, xp+100 W70 Center, Keyboard
Gui, Add, Text, xp+90 W70 Center, Mouse
Gui, Add, Text, xp+82 W30 Center, Ctrl
Gui, Add, Text, xp+30 W30 Center, Shift
Gui, Add, Text, xp+30 W30 Center, Alt

IniRead, adh_profile_list, %A_ScriptName%.ini, Settings, profile_list, Default
IniRead, adh_current_profile, %A_ScriptName%.ini, Settings, current_profile, Default

Loop, % adh_hotkeys.MaxIndex()
{
	adh_tmpname := adh_hotkeys[A_Index,1]
	Gui, Add, Text,x5 W100 y%adh_current_row%, %adh_tmpname%
	Gui, Add, Hotkey, yp-5 xp+100 W70 vadh_hk_k_%A_Index% gadh_key_changed
	Gui, Add, DropDownList, yp xp+80 W90 vadh_hk_m_%A_Index% gadh_mouse_changed, None||%adh_mouse_buttons%
	Gui, Add, CheckBox, xp+100 yp+5 W25 vadh_hk_c_%A_Index% gadh_option_changed
	Gui, Add, CheckBox, xp+30 yp W25 vadh_hk_s_%A_Index% gadh_option_changed
	Gui, Add, CheckBox, xp+30 yp W25 vadh_hk_a_%A_Index% gadh_option_changed
	adh_current_row := adh_current_row + 30
}

Gui, Add, Checkbox, x5 yp+30 vadh_program_mode gadh_program_mode_toggle, Program Mode
Gui, Add, Text, xp+100 yp, Limit to Application: ahk_class
Gui, Add, Edit, xp+150 yp-5 W100 vadh_limit_application
Gui, Add, Button, xp+101 yp W10 gadh_show_window_spy, ?
adh_limit_application_TT := "Enter a value here to make hotkeys only trigger when a specific application is open.`nUse the window spy (? Button to the right) to find the ahk_class of your application"

Gui, Tab, 3
; PROFILES TAB
adh_current_row := adh_tabtop + 20
Gui, Add, Text,x5 W40 y%adh_current_row%,Profile
Gui, Add, DropDownList, xp+40 yp-5 W150 vadh_current_profile gadh_profile_changed, Default||%adh_profile_list%
Gui, Add, Button, xp+160 yp-2 gadh_add_profile, Add
Gui, Add, Button, xp+40 yp gadh_delete_profile, Delete
Gui, Add, Button, xp+50 yp gadh_duplicate_profile, Duplicate
GuiControl,ChooseString, adh_current_profile, %adh_current_profile%

Gui, Tab, 4
; ABOUT TAB
adh_current_row := adh_tabtop + 10
Gui, Add, Link,x5 y%adh_tabtop%, This macro was created using AHK Dynamic Hotkeys by Clive "evilC" Galway
Gui, Add, Link,x5 yp+25, <a href="http://evilc.com/proj/adh">HomePage</a>    <a href="https://github.com/evilC/AHK-Dynamic-Hotkeys">GitHub Page</a>
Gui, Add, Link,x5 yp+35, This macro ("%adh_macro_name%") was created by %adh_author%
Gui, Add, Link,x5 yp+25, <a href="%adh_link_url%">%adh_link_text%</a>



; Show the GUI =====================================
Gui, Show, x%adh_gui_x% y%adh_gui_y% w%adh_gui_w% h%adh_gui_h%, %adh_macro_name% v%adh_version% (ADH v%adh_core_version%)

OnMessage(0x200, "adh_mouse_move")

Gui, Submit, NoHide	; Fire GuiSubmit while adh_ignore_events is on to set all the variables
adh_ignore_events := 0

GoSub, adh_program_mode_toggle
Gosub, adh_profile_changed

return

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; PLACE YOUR HOTKEY DEFINITIONS HERE

; Make sure you call them the same names as you set in the settings at the top of the file (eg Fire, FireRate)

; Set up HotKey 1

; Fired on key down
Fire:
	tooltip, 1 down
	;Send 1
	return

; Fired on key up
FireUp:
	tooltip, 1 up
	;Send q
	return

; Set up HotKey 2

; Fired on key down
ChangeFireRate:
	tooltip, 2 down
	;Send 2
	return

; Fired on key up
ChangeFireRateUp:
	tooltip, 2 up
	;Send w
	return
	
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^


; === SHOULD NOT NEED TO EDIT BELOW HERE! ===========================================================================

; Profile management - functions to manage preserving user settings

; aka load profile
adh_profile_changed:
	Gosub, adh_disable_hotkeys
	Gui, Submit, NoHide
	adh_update_ini("current_profile", "Settings", adh_current_profile,"")

	Loop, %adh_num_hotkeys%
	{
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_k_%A_Index%, 
		GuiControl,,adh_hk_k_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_m_%A_Index%, None
		GuiControl, ChooseString, adh_hk_m_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_c_%A_Index%, 0
		GuiControl,, adh_hk_c_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_s_%A_Index%, 0
		GuiControl,, adh_hk_s_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_a_%A_Index%, 0
		GuiControl,, adh_hk_a_%A_Index%, %adh_tmp%
	}
	; Get user vars from ini
	Loop, % adh_ini_vars.MaxIndex()
	{
		adh_def := adh_ini_vars[A_Index,3]
		adh_key := adh_ini_vars[A_Index,1]
		adh_sm := adh_control_name_to_set_method(adh_ini_vars[A_Index,2])
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, %adh_key%, %adh_def%
		GuiControl,%adh_sm%, %adh_key%, %adh_tmp%
	}

	Gosub, adh_enable_hotkeys
	
	return

; aka save profile
adh_option_changed:
if (adh_ignore_events != 1){
	Gui, Submit, NoHide
	
	Loop, %adh_num_hotkeys%
	{
		adh_update_ini("adh_hk_k_" A_Index, adh_current_profile, adh_hk_k_%A_Index%, "")
		adh_update_ini("adh_hk_m_" A_Index, adh_current_profile, adh_hk_m_%A_Index%, "None")
		adh_update_ini("adh_hk_c_" A_Index, adh_current_profile, adh_hk_c_%A_Index%, 0)
		adh_update_ini("adh_hk_s_" A_Index, adh_current_profile, adh_hk_s_%A_Index%, 0)
		adh_update_ini("adh_hk_a_" A_Index, adh_current_profile, adh_hk_a_%A_Index%, 0)
	}
	adh_update_ini("profile_list", "Settings", adh_profile_list,"")
	; Add user vars to ini
	Loop, % adh_ini_vars.MaxIndex()
	{
		adh_tmp := adh_ini_vars[A_Index,1]
		adh_update_ini(adh_tmp, adh_current_profile, %adh_tmp%, adh_ini_vars[A_Index,3])
	}
}	
return


adh_add_profile:
	InputBox, adh_tmp, Profile Name, Please enter a profile name
	adh_add_profile(adh_tmp)
	Gosub, adh_profile_changed
	return

adh_add_profile(name){
	global adh_profile_list
	if (adh_profile_list == ""){
		adh_profile_list := name
	} else {
		adh_profile_list := adh_profile_list "|" name
	}
	Sort, adh_profile_list, D|
	
	GuiControl,, adh_current_profile, |Default||%adh_profile_list%
	GuiControl,ChooseString, adh_current_profile, %name%
	
	adh_update_ini("profile_list", "Settings", adh_profile_list, "")
}

adh_delete_profile:
	if (adh_current_profile != "Default"){
		StringSplit, adh_tmp, adh_profile_list, |
		adh_out := ""
		Loop, %adh_tmp0%{
			if (adh_tmp%a_index% != adh_current_profile){
				if (adh_out != ""){
					adh_out := adh_out "|"
				}
				adh_out := adh_out adh_tmp%a_index%
			}
		}
		adh_profile_list := adh_out
		
		IniDelete, %A_ScriptName%.ini, %adh_current_profile%
		adh_update_ini("profile_list", "Settings", adh_profile_list, "")		
		
		GuiControl,, adh_current_profile, |Default||%adh_profile_list%
		Gui, Submit, NoHide
				
		Gosub, adh_profile_changed
	}
	return

adh_duplicate_profile:
	InputBox, adh_tmp, Profile Name, Please enter a profile name
	adh_duplicate_profile(adh_tmp)
	return

adh_duplicate_profile(name){
	global adh_profile_list
	global adh_current_profile
	
	if (adh_profile_list == ""){
		adh_profile_list := name
	} else {
		adh_profile_list := adh_profile_list "|" name
	}
	Sort, adh_profile_list, D|
	
	GuiControl,, adh_current_profile, |Default||%adh_profile_list%
	GuiControl,ChooseString, adh_current_profile, %name%
	adh_update_ini("profile_list", "Settings", adh_profile_list, "")
	
	Loop, %adh_num_hotkeys%
	{
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_k_%A_Index%, 	
		GuiControl,,adh_hk_k_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_m_%A_Index%, None
		GuiControl, ChooseString, adh_hk_m_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_c_%A_Index%, 0
		GuiControl,, adh_hk_c_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_s_%A_Index%, 0
		GuiControl,, adh_hk_s_%A_Index%, %adh_tmp%
		
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, adh_hk_a_%A_Index%, 0
		GuiControl,, adh_hk_a_%A_Index%, %adh_tmp%
	}
	adh_update_ini("current_profile", "Settings", name,"")
	
	Loop, % adh_ini_vars.MaxIndex()
	{
		adh_key := adh_ini_vars[A_Index,1]		
		adh_def := adh_ini_vars[A_Index,3]
		adh_sm := adh_control_name_to_set_method(adh_ini_vars[A_Index,2])
	
		IniRead, adh_tmp, %A_ScriptName%.ini, %adh_current_profile%, %adh_key%, %adh_def%
		GuiControl,%adh_sm%, %adh_key%, %adh_tmp%
	}
	
	Gosub, adh_option_changed
	;Gosub, adh_profile_changed

	return
}

; End profile management

; Converts a Control name (eg DropDownList) into the parameter passed to GuiControl to set that value (eg ChooseString)
adh_control_name_to_set_method(name){
	if (name == "DropDownList"){
		return "ChooseString"
	} else {
		return ""
	}
}

adh_key_changed:
	adh_tmp := %A_GuiControl%
	adh_ctr := 0
	adh_max := StrLen(adh_tmp)
	Loop, %adh_max%
	{
		chr := substr(adh_tmp,adh_ctr,1)
		if (chr != "^" && chr != "!" && chr != "+"){
			adh_ctr := adh_ctr + 1
		}
	}
	; Only modifier keys pressed?
	if (adh_ctr == 0){
		return
	}
	
	; key pressed
	if (adh_ctr < adh_max){
		GuiControl,, %A_GuiControl%, None
		Gosub, adh_option_changed
	}
	else
	{
		adh_tmp := SubStr(A_GuiControl,10)
		; Set the mouse field to blank
		GuiControl,ChooseString, adh_hk_m_%adh_tmp%, None
		Gosub, adh_option_changed
	}
	return

adh_mouse_changed:
	adh_tmp := SubStr(A_GuiControl,10)
	; Set the keyboard field to blank
	GuiControl,, adh_hk_k_%adh_tmp%, None
	Gosub, adh_option_changed
	return

adh_enable_hotkeys:
	Gui, Submit, NoHide
	Loop, %adh_num_hotkeys%
	{
		adh_pre := adh_build_prefix(A_Index)
		adh_tmp := adh_hk_k_%A_Index%
		if (adh_tmp == ""){
			adh_tmp := adh_hk_m_%A_Index%
			if (adh_tmp == "None"){
				adh_tmp := ""
			}
		}
		if (adh_tmp != ""){
			adh_set := adh_pre adh_tmp
			adh_hotkey_sub := adh_hotkeys[A_Index,2]
			Hotkey, ~%adh_set% , %adh_hotkey_sub%
			Hotkey, ~%adh_set% up , %adh_hotkey_sub%Up
			; ToDo: Up event does not fire for wheel "buttons" - send dupe event or something?
		}
		GuiControl, Disable, adh_hk_k_%A_Index%
		GuiControl, Disable, adh_hk_m_%A_Index%
		GuiControl, Disable, adh_hk_c_%A_Index%
		GuiControl, Disable, adh_hk_s_%A_Index%
		GuiControl, Disable, adh_hk_a_%A_Index%
	}
	return

adh_disable_hotkeys:
	Loop, %adh_num_hotkeys%
	{
		adh_pre := adh_build_prefix(A_Index)
		adh_tmp := adh_hk_k_%A_Index%
		if (adh_tmp == ""){
			adh_tmp := adh_hk_m_%A_Index%
			if (adh_tmp == "None"){
				adh_tmp := ""
			}
		}
		if (adh_tmp != ""){
			adh_set := adh_pre adh_tmp
			; ToDo: Is there a better way to remove a hotkey?
			HotKey, ~%adh_set%, adh_do_nothing
			HotKey, ~%adh_set% up, adh_do_nothing
		}
		GuiControl, Enable, adh_hk_k_%A_Index%
		GuiControl, Enable, adh_hk_m_%A_Index%
		GuiControl, Enable, adh_hk_c_%A_Index%
		GuiControl, Enable, adh_hk_s_%A_Index%
		GuiControl, Enable, adh_hk_a_%A_Index%
	}
	return

; An empty stub to redirect unbound hotkeys to
adh_do_nothing:
	return

adh_build_prefix(hk){
	adh_out := ""
	adh_tmp = adh_hk_c_%hk%
	GuiControlGet,%adh_tmp%
	if (adh_hk_c_%hk% == 1){
		adh_out := adh_out "^"
	}
	if (adh_hk_a_%hk% == 1){
		adh_out := adh_out "!"
	}
	if (adh_hk_s_%hk% == 1){
		adh_out := adh_out "+"
	}
	return adh_out
}
	
; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
adh_update_ini(key, section, value, default){
	adh_tmp := A_ScriptName ".ini"
	if (value != default){
		IniWrite,  %value%, %adh_tmp%, %section%, %key%
	} else {
		IniDelete, %adh_tmp%, %section%, %key%
	}
}

; Kill the macro if the GUI is closed
adh_gui_close:
	Gui, +Hwndgui_id
	WinGetPos, adh_gui_x, adh_gui_y,,, ahk_id %gui_id%
	IniWrite, %adh_gui_x%, %A_ScriptName%.ini, Settings, gui_x
	IniWrite, %adh_gui_y%, %A_ScriptName%.ini, Settings, gui_y
	ExitApp
	return

adh_show_window_spy:
	adh_show_window_spy()
	return

adh_show_window_spy(){
	SplitPath, A_AhkPath,,tmp
	tmp := tmp "\AU3_Spy.exe"
	IfExist, %tmp%
		Run, %tmp%
}

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

adh_program_mode_toggle:
	Gui, Submit, NoHide
	if (adh_program_mode == 1){
		; Enable controls, stop hotkeys
		GoSub, adh_disable_hotkeys
	} else {
		; Disable controls, start hotkeys
		GoSub, adh_enable_hotkeys
	}
	return
	
; Tooltip function from http://www.autohotkey.com/board/topic/81915-solved-gui-control-tooltip-on-hover/#entry598735
adh_mouse_move(){
	static CurrControl, PrevControl, _TT
	CurrControl := A_GuiControl
	If (CurrControl <> PrevControl){
			SetTimer, DisplayToolTip, -300 	; shorter wait, shows the tooltip faster
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
