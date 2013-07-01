; evilC's Macro Template
; To add an extra hotkey, duplicate the lines between the vvv and ^^^ blocks
; vvvvvvvvv
; Like this
; ^^^^^^^^^
; And replace old name (eg HotKey2) with a new name - eg HotKey3

; Change the number of hotkeys here
num_hotkeys := 2

; You *may* need to edit some of these settings - eg Sendmode for some games

#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

; ===== Do not edit the Header =================================================================================================
#InstallKeybdHook
#InstallMouseHook
#MaxHotKeysPerInterval, 200
 
OnExit, GuiClose

debug := 0
EditingHotKey := ""
NewHotKey := ""
;MouseButtons := "Esc,LButton,RButton,MButton,XButton1,XButton2,WheelUp,WheelDown,WheelLeft,WheelRight"
MouseButtons := "LButton|RButton|MButton|XButton1|XButton2|WheelUp|WheelDown|WheelLeft|WheelRight"
StateCtrl := ""
StateAlt := ""
StateShift := ""

ignore_events := 1	; Setting this to 1 while we load the GUI allows us to ignore change messages generated while we build the GUI

IniRead, gui_x, %A_ScriptName%.ini, Settings, gui_x, 0
IniRead, gui_y, %A_ScriptName%.ini, Settings, gui_y, 0
if (gui_x == ""){
	gui_x := 0	; in case of crash empty values can get written
}
if (gui_y == ""){
	gui_y := 0
}

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Uncomment and alter to limit hotkeys to one specific program
;Hotkey, IfWinActive, ahk_class CryENGINE

; Set up the GUI

gui_w := 375
gui_h := 200

Gui, Add, Tab2, x0 w%gui_w% h%gui_h%, Main|Bindings|Profiles

Gui, Tab, 1
Gui, Add, Text, x5 y40 w%gui_w%, Add your settings here...`n`nFire rate, weapon selection etc

Gui, Tab, 2

Gui, Add, Text, x5 y40 W70 Center, Name
Gui, Add, Text, xp+70 W70 Center, Keyboard
Gui, Add, Text, xp+90 W70 Center, Mouse
Gui, Add, Text, xp+92 W30 Center, Ctrl
Gui, Add, Text, xp+30 W30 Center, Shift
Gui, Add, Text, xp+30 W30 Center, Alt

tabtop := 40
row := tabtop + 20

IniRead, ProfileList, %A_ScriptName%.ini, Settings, profile_list, Default
IniRead, CurrentProfile, %A_ScriptName%.ini, Settings, current_profile, Default

Loop, %num_hotkeys%
{
	Gui, Add, Text,x5 W70 y%row%,HotKey %A_Index%
	
	IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKK%A_Index%, 
	Gui, Add, Hotkey, yp-5 xp+70 W70 vHKK%A_Index% gKeyChanged, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKM%A_Index%, None
	Gui, Add, DropDownList, yp xp+80 W90 vHKM%A_Index% gMouseChanged, None||%MouseButtons%
	GuiControl, ChooseString, HKM%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKC%A_Index%, 0
	Gui, Add, CheckBox, xp+110 yp+5 W30 vHKC%A_Index% gOptionChanged
	GuiControl,, HKC%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKS%A_Index%, 0
	Gui, Add, CheckBox, xp+30 yp W30 vHKS%A_Index% gOptionChanged
	GuiControl,, HKS%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKA%A_Index%, 0
	Gui, Add, CheckBox, xp+30 yp W30 vHKA%A_Index% gOptionChanged
	GuiControl,, HKA%A_Index%, %tmp%
	
	row := row + 30
}

Gui, Add, Checkbox, x5 yp+30 vProgramMode gProgramModeToggle, Program Mode

Gui, Tab, 3
row := tabtop + 20
Gui, Add, Text,x5 W70 y%row%,Profile
Gui, Add, DropDownList, xp+70 yp-5 W90 vCurrentProfile gProfileChanged, Default||%ProfileList%
GuiControl,ChooseString, CurrentProfile, %CurrentProfile%


; Show the GUI =====================================
Gui, Show, x%gui_x% y%gui_y% w%gui_w% h%gui_h%

Gui, Submit, NoHide	; Fire GuiSubmit while ignore_events is on to set all the variables
ignore_events := 0

GoSub, ProgramModeToggle

return
; ===== End Header ==============================================================================================================




; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKey 1

; Fired on key down
HotKey1:
	tooltip, 1 down
	;Send 1
	return

; Fired on key up
HotKey1_up:
	tooltip, 1 up
	;Send q
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKey 2

; Fired on key down
HotKey2:
	tooltip, 2 down
	;Send 2
	return

; Fired on key up
HotKey2_up:
	tooltip, 2 up
	;Send w
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; === SHOULD NOT NEED TO EDIT BELOW HERE!===========================================================================

ProfileChanged:
	Gosub, DisableHotKeys
	Gui, Submit, NoHide
	;msgbox, % CurrentProfile
	UpdateINI("current_profile", "Settings", CurrentProfile,"")

	Loop, %num_hotkeys%
	{
		IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKK%A_Index%, 
		GuiControl,,HKK%A_Index%, %tmp%
		
		IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKM%A_Index%, None
		GuiControl, ChooseString, HKM%A_Index%, %tmp%
		
		IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKC%A_Index%, 0
		GuiControl,, HKC%A_Index%, %tmp%
		
		IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKS%A_Index%, 0
		GuiControl,, HKS%A_Index%, %tmp%
		
		IniRead, tmp, %A_ScriptName%.ini, %CurrentProfile%, HKA%A_Index%, 0
		GuiControl,, HKA%A_Index%, %tmp%
	}

	Gosub, EnableHotKeys
	
	return
	
KeyChanged:
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
		Gosub, OptionChanged
	}
	else
	{
		tmp := SubStr(A_GuiControl,4)
		; Set the mouse field to blank
		GuiControl,ChooseString, HKM%tmp%, None
		Gosub, OptionChanged
	}
	return

MouseChanged:
	tmp := SubStr(A_GuiControl,4)
	; Set the keyboard field to blank
	GuiControl,, HKK%tmp%, None
	Gosub, OptionChanged
	return

OptionChanged:
	if (ignore_events != 1){
		Gui, Submit, NoHide
		
		Loop, %num_hotkeys%
		{
			UpdateINI("HKK" A_Index, CurrentProfile, HKK%A_Index%, "")
			UpdateINI("HKM" A_Index, CurrentProfile, HKM%A_Index%, "None")
			UpdateINI("HKC" A_Index, CurrentProfile, HKC%A_Index%, 0)
			UpdateINI("HKS" A_Index, CurrentProfile, HKS%A_Index%, 0)
			UpdateINI("HKA" A_Index, CurrentProfile, HKA%A_Index%, 0)
		}
		UpdateINI("profile_list", "Settings", ProfileList,"")
	}	
	return

EnableHotKeys:
	Loop, %num_hotkeys%
	{
		pre := BuildPrefix(A_Index)
		tmp := HKK%A_Index%
		if (tmp == ""){
			tmp := HKM%A_Index%
			if (tmp == "None"){
				tmp := ""
			}
		}
		if (tmp != ""){
			set := pre tmp
			Hotkey, ~%set% , HotKey%A_Index%
			Hotkey, ~%set% up , HotKey%A_Index%_up
			/*
			; Up event does not fire for wheel "buttons", but cannot bind two events to one hotkey ;(
			if (tmp == "WheelUp" || tmp == "WheelDown" || tmp == "WheelLeft" || tmp == "WheelRight"){
				Hotkey, ~%set% , HotKey%A_Index%_up
			} else {
				Hotkey, ~%set% up , HotKey%A_Index%_up
			}
			*/
		}
		GuiControl, Disable, HKK%A_Index%
		GuiControl, Disable, HKM%A_Index%
		GuiControl, Disable, HKC%A_Index%
		GuiControl, Disable, HKS%A_Index%
		GuiControl, Disable, HKA%A_Index%
	}
	return

DisableHotKeys:
	Loop, %num_hotkeys%
	{
		pre := BuildPrefix(A_Index)
		tmp := HKK%A_Index%
		if (tmp == ""){
			tmp := HKM%A_Index%
			if (tmp == "None"){
				tmp := ""
			}
		}
		if (tmp != ""){
			set := pre tmp
			; ToDo: Is there a better way to remove a hotkey?
			HotKey, ~%set%, DoNothing
			HotKey, ~%set% up, DoNothing
		}
		GuiControl, Enable, HKK%A_Index%
		GuiControl, Enable, HKM%A_Index%
		GuiControl, Enable, HKC%A_Index%
		GuiControl, Enable, HKS%A_Index%
		GuiControl, Enable, HKA%A_Index%
	}
	return

; An empty stub to redirect unbound hotkeys to
DoNothing:
	return

BuildPrefix(hk){
	out := ""
	tmp = HKC%hk%
	GuiControlGet,%tmp%
	if (HKC%hk% == 1){
		out := out "^"
	}
	if (HKA%hk% == 1){
		out := out "!"
	}
	if (HKS%hk% == 1){
		out := out "+"
	}
	return out
}
	
; Updates the settings file. If value is default, it deletes the setting to keep the file as tidy as possible
UpdateINI(key, section, value, default){
	tmp := A_ScriptName ".ini"
	if (value != default){
		IniWrite,  %value%, %tmp%, %section%, %key%
	} else {
		IniDelete, %tmp%, %section%, %key%
	}
}

; Kill the macro if the GUI is closed
GuiClose:
	Gui, +Hwndgui_id
	WinGetPos, gui_x, gui_y,,, ahk_id %gui_id%
	IniWrite, %gui_x%, %A_ScriptName%.ini, Settings, gui_x
	IniWrite, %gui_y%, %A_ScriptName%.ini, Settings, gui_y
	ExitApp
	return

; Code from http://www.autohotkey.com/board/topic/47439-user-defined-dynamic-hotkeys/
; This code enables extra keys in a Hotkey GUI control
#MenuMaskKey vk07                 ;Requires AHK_L 38+
#If ctrl := HotkeyCtrlHasFocus()
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
	;validateHK(ctrl)
	Gosub, OptionChanged
	return
#If

HotkeyCtrlHasFocus() {
	GuiControlGet, ctrl, Focus       ;ClassNN
	If InStr(ctrl,"hotkey") {
		GuiControlGet, ctrl, FocusV     ;Associated variable
		Return, ctrl
	}
}

ProgramModeToggle:
	Gui, Submit, NoHide
	if (ProgramMode == 1){
		; Enable controls, stop hotkeys
		GoSub, DisableHotKeys
	} else {
		; Disable controls, start hotkeys
		GoSub, EnableHotKeys
	}
	return
	
