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
* Expand to multiple hotkeys (two as an example)
* Remove so much use of global vars.

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

ModifierState := {}
HKLast := ""		; Holds the last detected hotkey
HKJoystick := 0		; Set to 1 if the last detected bind was a Joystick button
HKModifier := 0		; Set to 1 if the last detected bind was a "Solitary Modifier" (A Modifier on it's own)
ININame := BuildIniName()

; Create the GUI
Gui, Add, Edit, Disabled vHotkeyName w250, None
Gui, Add, Button, gBind yp-1 xp+260, Set Hotkey
Gui, Show, Center w350 h50, Keybind Test

; Set GUI State
LoadSettings()

; Enable defined hotkeys
EnableHotkeys()

return

; Detects a pressed key combination
Bind:
	Bind()
	return

Bind(){
	global ModifierState
	global BindMode
	global EXTRA_KEY_LIST
	global HKLast
	global HKFound
	global HKModifier
	global HKJoystick

	; init vars
	HKFound := 0
	HKModifier := 0
	HKJoystick := 0
	ModifierState := {ctrl: 0, alt: 0, shift: 0, win: 0}

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

	Loop {
		; Use input box to detect normal (non-modifier) keyboard keys
		Input, SingleKey, L1 M T0.1, %EXTRA_KEY_LIST%
		if (ErrorLevel == "Max" ) {
			; A normal key was pressed
			HKFound := SingleKey
		} else if (substr(ErrorLevel,1,7) == "EndKey:"){
			; A "Special" (Non-printable) key was pressed
			tmp := substr(ErrorLevel,8)
			if (tmp == "Escape"){
				break
			}
			HKFound := tmp
		}

		; We use HKFound to decide whether to break out of the loop, so modifier key, mouse and joystick detection can be detected elsewhere
		if (HKFound){
			break
		}
	}
	; Stop listening to mouse, keyboard etc
	BindMode := 0
	JoystickDetection(0)

	; Hide prompt
	Gui, 2:Submit

	; Process results

	modct := ModifierCount()

	if (HKFound && modct && HKJoystick){
		msgbox ,,Error, Modifiers (Ctrl, Alt, Shift, Win) are currently not supported with Joystick buttons.
		HKFound := ""
	}

	if (HKFound){
		; Escape was not pressed
		outhk := BuildHotkeyString()

		; Store the hotkey so it can be disabled later
		HKLast := outhk

		; Enable the hotkeys
		EnableHotkeys()

		; Write settings to INI file
		SaveSettings()

		; Update the GUI control
		;val := BuildHotkeyName(HKLast,HKJoystick)
		;GuiControl,, HotkeyName, %val%
		LoadSettings()
	} else {
		; Escape was pressed - resotre original hotkey, if any
		EnableHotkeys()
	}
	return
}

; Enables User-Defined Hotkeys
EnableHotkeys(){
	global HKLast

	if (HKLast != ""){
		hotkey, ~*%HKLast%, DoHotkey, ON
	}
}

; Disables User-Defined Hotkeys
DisableHotkeys(){
	global HKLast

	if (HKLast != ""){
		hotkey, ~*%HKLast%, , Off
	}
}

; Write settings to the INI
SaveSettings(){
	global ININame
	global HKLast
	global HKJoystick

	iniwrite, %HKLast%, %ININame%, Hotkeys, hk_1
	iniwrite, %HKJoystick%, %ININame%, Hotkeys, hk_1_j
}

; Read settings from the INI
LoadSettings(){
	global HKLast
	global ININame
	global HKJoystick

	IniRead, tmp, %ININame% , Hotkeys, hk_1,
	if (tmp != "ERROR"){
		HKLast := tmp

		tmp := BuildHotkeyName(HKLast,0)
		GuiControl,, HotkeyName, %tmp%

		IniRead, tmp, %ININame% , Hotkeys, hk_1_j, 0
		if (tmp != "ERROR"){
			HKJoystick := tmp

			tmp := BuildHotkeyName(HKLast,HKJoystick)
			GuiControl,, HotkeyName, %tmp%
		}
	}
}

; Builds an AHK String (eg "^c" for CTRL + C) from the last detected hotkey
BuildHotkeyString(){
	global HKFound
	global HKModifier
	global ModifierState

		;StringUpper, HKFound, HKFound
		outhk := ""
		modct := ModifierCount()

		if (HKModifier){
			; Solitary modifier key used (eg Left / Right Alt)
			outhk := HKFound
		} else {
			if (modct){
				; Modifiers used in combination with something else - List modifiers in a specific order
				modifiers := ["CTRL","ALT","SHIFT","WIN"]

				Loop, 4 {
					key := modifiers[A_Index]
					value := ModifierState[modifiers[A_Index]]
					if (value){
						;stringupper, tmp, key

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
			; Modifiers etc processed, complete the strings
			outhk .= HKFound
		}

		; Store the hotkey so it can be disabled later
		return outhk
}

; Builds a Human-Readable form of a Hotkey string (eg "^C" -> "CTRL + C")
BuildHotkeyName(hk,joy){
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

	if (joy){
		pos := instr(hk,"JOY")
		id := substr(hk,1,pos-1)
		button := substr(hk,5)
		outstr .= "JOYSTICK " id " BTN " button
	} else {
		tmp := instr(hk,"NUMPAD")
		if (tmp){
			outstr .= "NUMPAD " substr(hk,7)
		} else {
			; Replace underscores with spaces
			StringReplace, hk, hk, _ , %A_SPACE%, All
			outstr .= hk
		}
	}


	return outstr
}

; Test that bound hotkeys work
DoHotkey:
	msgbox You pressed the Hotkey.
	return

; Detects Modifiers in BindMode
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
		SetModifier(mod,0)
		if (!ModifierCount()){
			;if other modifiers still held, do not set HKFound
			HKModifier := 1
			HKFound := mod
		}
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
		HKFound := A_ThisHotkey
		return
#If

; A Joystick button was pressed while in Binding mode
JoystickPressed:
	HKJoystick := 1
	HKFound := A_ThisHotkey
	return

; Sets the state of the ModifierState object to reflect the state of the modifier keys
SetModifier(hk,state){
	global ModifierState

	if (hk == "lctrl" || hk == "rctrl"){
		ModifierState.ctrl := state
	} else if (hk == "lalt" || hk == "ralt"){
		ModifierState.alt := state
	} else if (hk == "lshift" || hk == "rshift"){
		ModifierState.shift := state
	} else if (hk == "lwin" || hk == "rwin"){
		ModifierState.win := state
	}
	return
}

; Counts how many modifier keys are held
ModifierCount(){
	global ModifierState

	return ModifierState.ctrl + ModifierState.alt + ModifierState.shift  + ModifierState.win
}

; Enables or Disables detection of joystick buttons
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

BuildIniName(){
	tmp := A_Scriptname
	Stringsplit, tmp, tmp,.
	return tmp1 ".ini"
}
