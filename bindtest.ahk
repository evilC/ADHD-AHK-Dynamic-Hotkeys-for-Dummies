; Proof of concept for replacement of Hotkey GUI Item

/*

ToDo:
* AHK hotkey command does not support Joystick buttons plus modifiers - triggers without modifier.
  Solution probably requires detecting joystick with GetKeyState loop.
  GetKeyState would be required to support up events anyway.
* Joystick POV support
  Again, GetKeyState loop would fix
* Allow adding to EXTRA_KEY_LIST by users
* Hold Escape to clear binding?
* Encapsulate into Object
* Do not allow duplicate hotkeys

Known issues:

*/

#InstallKeybdHook
#InstallMouseHook

; Build list of "End Keys" for Input command
EXTRA_KEY_LIST := "{Escape}"	; DO NOT REMOVE! - Used to quit binding
; Standard non-printables
EXTRA_KEY_LIST .= "{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}"
EXTRA_KEY_LIST .= "{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BackSpace}{Pause}"
; Numpad - Numlock ON
EXTRA_KEY_LIST .= "{Numpad0}{Numpad1}{Numpad2}{Numpad3}{Numpad4}{Numpad5}{Numpad6}{Numpad7}{Numpad8}{Numpad9}{NumpadDot}{NumpadMult}{NumpadAdd}{NumpadSub}"
; Numpad - Numlock OFF
EXTRA_KEY_LIST .= "{NumpadIns}{NumpadEnd}{NumpadDown}{NumpadPgDn}{NumpadLeft}{NumpadClear}{NumpadRight}{NumpadHome}{NumpadUp}{NumpadPgUp}{NumpadDel}"
; Numpad - Common
EXTRA_KEY_LIST .= "{NumpadMult}{NumpadAdd}{NumpadSub}{NumpadDiv}{NumpadEnter}"
; Stuff we may or may not want to trap
;EXTRA_KEY_LIST .= "{Numlock}"
EXTRA_KEY_LIST .= "{Capslock}"
;EXTRA_KEY_LIST .= "{PrintScreen}"
; Browser keys
EXTRA_KEY_LIST .= "{Browser_Back}{Browser_Forward}{Browser_Refresh}{Browser_Stop}{Browser_Search}{Browser_Favorites}{Browser_Home}"
; Media keys
EXTRA_KEY_LIST .= "{Volume_Mute}{Volume_Down}{Volume_Up}{Media_Next}{Media_Prev}{Media_Stop}{Media_Play_Pause}"
; App Keys
EXTRA_KEY_LIST .= "{Launch_Mail}{Launch_Media}{Launch_App1}{Launch_App2}"

; BindMode vars
HKModifierState := {}	; The state of the modifiers at the end of the last detection sequence
HKControlType := 0		; The kind of control that the last hotkey was. 0 = regular key, 1 = solitary modifier, 2 = mouse, 3 = joystick
HKSecondaryInput := ""	; Set to button pressed if the last detected bind was a Mouse button, Joystick button or Solitary Modifier

; Misc vars
ININame := BuildIniName()
HotkeyList := []
NumHotkeys := 2

; Create the GUI
Gui Add, Text,, Blah

Gui, Add, Edit, Disabled vHotkeyName1 w250 x5 yp+25, None
Gui, Add, Button, gBind vBind1 yp-1 xp+260, Set Hotkey

Gui, Add, Edit, Disabled vHotkeyName2 w250 x5 yp+30, None
Gui, Add, Button, gBind vBind2 yp-1 xp+260, Set Hotkey

Gui, Show, Center w350 h90 x0 y0, Keybind Test

; Set GUI State
LoadSettings()

; Enable defined hotkeys
EnableHotkeys()

return

; Test that bound hotkeys work
DoHotkey1:
	soundbeep
	msgbox You pressed Hotkey 1.
	return

DoHotkey2:
	soundbeep
	msgbox You pressed Hotkey 2.
	return


; Detects a pressed key combination
Bind:
	Bind(substr(A_GuiControl,5))
	return

Bind(ctrlnum){
	global HKModifierState
	global BindMode
	global EXTRA_KEY_LIST
	global HKControlType
	global HKSecondaryInput

	global HotkeyList

	; init vars
	HKControlType := 0
	HKModifierState := {ctrl: 0, alt: 0, shift: 0, win: 0}

	; Disable existing hotkeys
	DisableHotkeys()

	; Enable Joystick detection hotkeys
	JoystickDetection(1)

	; Start Bind Mode - this starts detection for mouse buttons and modifier keys
	BindMode := 1

	; Show the prompt
	prompt := "Please press the desired key combination.`n`n"
	prompt .= "Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n"
	prompt .= "Joystick buttons are also supported, but currently not with modifiers.`n"
	prompt .= "`nHit Escape to cancel"
	Gui, 2:Add, text, center, %prompt%
	Gui, 2:-Border +AlwaysOnTop
	Gui, 2:Show

	outhk := ""

	Input, detectedkey, L1 M, %EXTRA_KEY_LIST%

	if (substr(ErrorLevel,1,7) == "EndKey:"){
		; A "Special" (Non-printable) key was pressed
		tmp := substr(ErrorLevel,8)
		detectedkey := tmp
		if (tmp == "Escape"){
			; Detection ended by Escape
			if (HKControlType > 0){
				; The Escape key was sent because a special button was used
				detectedkey := HKSecondaryInput
			}
		}
	}

	; Stop listening to mouse, keyboard etc
	BindMode := 0
	JoystickDetection(0)

	; Hide prompt
	Gui, 2:Submit


	; Process results

	modct := CurrentModifierCount()

	if (detectedkey && modct && HKControlType == 3){
		msgbox ,,Error, Modifiers (Ctrl, Alt, Shift, Win) are currently not supported with Joystick buttons.
		detectedkey := ""
	}

	if (detectedkey){
		; Update the hotkey object
		outhk := BuildHotkeyString(detectedkey,HKControlType)
		HotkeyList[ctrlnum] := {hk: outhk, type: HKControlType}

		; Write settings to INI file
		SaveSettings()

		; Update the GUI control
		UpdateHotkeyControls()

		; Enable the hotkeys
		EnableHotkeys()
	} else {
		; Escape was pressed - resotre original hotkey, if any
		EnableHotkeys()
	}
	return
}

; Enables User-Defined Hotkeys
EnableHotkeys(){
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index].hk
		if (hk != ""){
			hotkey, ~*%hk%, DoHotkey%A_Index%, ON
		}
	}
}

; Disables User-Defined Hotkeys
DisableHotkeys(){
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index].hk
		if (hk != ""){
			hotkey, ~*%hk%, DoHotkey%A_Index%, OFF
		}
	}
}

; Write settings to the INI
SaveSettings(){
	global ININame
	global NumHotkeys
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index].hk
		type := HotkeyList[A_Index].type

		if (hk != ""){
			iniwrite, %hk%, %ININame%, Hotkeys, hk_%A_Index%
			iniwrite, %type%, %ININame%, Hotkeys, hk_%A_Index%_t
		}
	}
	return
}

; Read settings from the INI
LoadSettings(){
	global ININame
	global NumHotkeys
	global HotkeyList

	Loop % NumHotkeys {
		IniRead, val, %ININame% , Hotkeys, hk_%A_Index%,
		IniRead, type, %ININame% , Hotkeys, hk_%A_Index%_t,
		if (val != "ERROR"){
			IniRead, ctrltype, %ININame% , Hotkeys, hk_%A_Index%_t, 0
			if (ctrltype == "ERROR"){
				ctrltype := 0
			}

			HotkeyList[A_Index] := {hk: val, type: type}
		}
	}
	UpdateHotkeyControls()
}

; Update the GUI controls with the hotkey names
UpdateHotkeyControls(){
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		if (HotkeyList[A_Index].hk != ""){
			tmp := BuildHotkeyName(HotkeyList[A_Index].hk,HotkeyList[A_Index].type)
			GuiControl,, HotkeyName%A_Index%, %tmp%
		}
	}
}

; Builds an AHK String (eg "^c" for CTRL + C) from the last detected hotkey
BuildHotkeyString(str, type := 0){
	global HKModifierState

	outhk := ""
	modct := CurrentModifierCount()

	if (type == 1){
		; Solitary modifier key used (eg Left / Right Alt)
		outhk := str
	} else {
		if (modct){
			; Modifiers used in combination with something else - List modifiers in a specific order
			modifiers := ["CTRL","ALT","SHIFT","WIN"]

			Loop, 4 {
				key := modifiers[A_Index]
				value := HKModifierState[modifiers[A_Index]]
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

; Detects Modifiers and Mouse Buttons in BindMode
#If BindMode
	*lctrl::
	*rctrl::
	*lalt::
	*ralt::
	*lshift::
	*rshift::
	*lwin::
	*rwin::
		mod := substr(A_ThisHotkey,2)
		SetModifier(mod,1)
		return

	*lctrl up::
	*rctrl up::
	*lalt up::
	*ralt up::
	*lshift up::
	*rshift up::
	*lwin up::
	*rwin up::
		mod := substr(substr(A_ThisHotkey,2),1,strlen(A_ThisHotkey) -4)
		if (CurrentModifierCount() == 1){
			; If CurrentModifierCount is 1 when an up is received, then that is a Solitary Modifier
			; It cannot be a modifier + normal key, as this code would have quit on keydown of normal key

			HKControlType := 1
			HKSecondaryInput := mod

			; Send Escape - This will cause the Input command to quit with an EndKey of Escape
			; But we stored the modifier key, so we will know it was not really escape
			Send {Escape}
		}
		SetModifier(mod,0)
		return

	lbutton::
	rbutton::
	mbutton::
	xbutton1::
	xbutton2::
	wheelup::
	wheeldown::
	wheelleft::
	wheelright::
		HKControlType := 2
		HKSecondaryInput := A_ThisHotkey
		Send {Escape}
		return
#If

; Adds / removes hotkeys to detect Joystick Buttons in BindMode
JoystickDetection(mode := 1){
	if (mode){
		mode := "ON"
	} else {
		mode := "OFF"
	}
	Loop , 16 {
		stickid := A_Index
		Loop, 32 {
			buttonid := A_Index
			hotkey, %stickid%Joy%buttonid%, JoystickPressed, %mode%
		}
	}
}

; A Joystick button was pressed while in Binding mode
JoystickPressed:
	HKControlType := 2
	HKSecondaryInput := A_ThisHotkey
	Send {Escape}
	return

; Sets the state of the HKModifierState object to reflect the state of the modifier keys
SetModifier(hk,state){
	global HKModifierState

	if (hk == "lctrl" || hk == "rctrl"){
		HKModifierState.ctrl := state
	} else if (hk == "lalt" || hk == "ralt"){
		HKModifierState.alt := state
	} else if (hk == "lshift" || hk == "rshift"){
		HKModifierState.shift := state
	} else if (hk == "lwin" || hk == "rwin"){
		HKModifierState.win := state
	}
	return
}

; Counts how many modifier keys are currently held
CurrentModifierCount(){
	global HKModifierState

	return HKModifierState.ctrl + HKModifierState.alt + HKModifierState.shift  + HKModifierState.win
}

; Takes the start of the file name (before .ini or .exe and replaces it with .ini)
BuildIniName(){
	tmp := A_Scriptname
	Stringsplit, tmp, tmp,.
	ini_name := ""
	last := ""
	Loop, % tmp0
	{
		; build the string up to the last period (.)
		if (last != ""){
			if (ini_name != ""){
				ini_name := ini_name "."
			}
			ini_name := ini_name last
		}
		last := tmp%A_Index%
	}
	;this.ini_name := ini_name ".ini"
	return ini_name ".ini"

}
