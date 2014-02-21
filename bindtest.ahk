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
* Hotkeys broken on load

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

; Detection vars
ModifierState := {}			; The state of the modifiers at the end of the last detection sequence
HKControlType := 0			; The kind of control that the last hotkey was. 0 = regular key, 1 = mouse, 2 = joystick
HKSecondaryInput := ""		; Set to button pressed if the last detected bind was a Mouse or Joystick button
HKSolitaryModifier := 0		; Set to modifier pressed if the last detected bind was a "Solitary Modifier" (A Modifier on it's own)

; To be removed
HKLast := ""		; Holds the last detected hotkey
HKMouse := 0		; Set to button pressed if the last detected bind was a Mouse button
HKJoystick := 0		; Set to button pressed if the last detected bind was a Joystick button


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

; Detects a pressed key combination
Bind:
	Bind(substr(A_GuiControl,5))
	return

Bind(ctrlnum){
	global ModifierState
	global BindMode
	global EXTRA_KEY_LIST
	global HKSolitaryModifier
	global HKControlType
	global HKSecondaryInput

	global HKLast
	global HKFound
	global HKMouse
	global HKJoystick
	global HotkeyList

	; init vars
	HKFound := 0
	HKSolitaryModifier := 0
	HKControlType := 0
	HKMouse := 0
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

	;Loop {
		; Use input box to detect normal (non-modifier) keyboard keys
		;Input, SingleKey, L1 M T0.1, %EXTRA_KEY_LIST%
		Input, SingleKey, L1 M, %EXTRA_KEY_LIST%
		if (ErrorLevel == "Max" ) {
			; A normal key was pressed
			HKFound := SingleKey
		} else if (substr(ErrorLevel,1,7) == "EndKey:"){
			; A "Special" (Non-printable) key was pressed
			tmp := substr(ErrorLevel,8)
			HKFound := tmp
			if (tmp == "Escape"){
				; Detection ended by Escape
				if (HKSolitaryModifier){
					; The Escape key was sent by a Solitary Modifier being released - set the Found key to the modifier
					HKFound := HKSolitaryModifier
				} else if (HKControlType){
					HKFound := HKSecondaryInput
				}
			}
		}

		; We use HKFound to decide whether to break out of the loop, so modifier key, mouse and joystick detection can be detected elsewhere
		;if (HKFound){
		;	break
		;}
	;}
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

		; Update the hotkey object
		HotkeyList[ctrlnum] := outhk

		; Write settings to INI file
		SaveSettings()

		; Enable the hotkeys
		EnableHotkeys()

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
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index]
		if (hk != ""){
			hotkey, ~*%hk%, DoHotkey, ON
		}
	}
}

; Disables User-Defined Hotkeys
DisableHotkeys(){
	global HotkeyList

	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index]
		if (hk != ""){
			hotkey, ~*%hk%, DoHotkey, OFF
		}
	}
}

; Write settings to the INI
SaveSettings(){
	global ININame
	global HKLast
	global HKJoystick
	global NumHotkeys
	global HotkeyList

	;msgbox % HotkeyList[1] "," HotkeyList[2]
	Loop % HotkeyList.MaxIndex(){
		hk := HotkeyList[A_Index]
		if (hk != ""){
			iniwrite, %hk%, %ININame%, Hotkeys, hk_%A_Index%
			;iniwrite, %HKJoystick%, %ININame%, Hotkeys, hk_1_j
		}
	}
	return
}

; Read settings from the INI
LoadSettings(){
	global HKLast
	global ININame
	global HKJoystick
	global NumHotkeys
	global HotkeyList

	Loop % NumHotkeys {
		IniRead, val, %ININame% , Hotkeys, hk_%A_Index%,
		if (val != "ERROR"){
			IniRead, ctrltype, %ININame% , Hotkeys, hk_%A_Index%_t, 0
			if (ctrltype == "ERROR"){
				ctrltype := 0
			}
			tmp := BuildHotkeyName(val,ctrltype)

			HotkeyList[A_Index] := val
			GuiControl,, HotkeyName%A_Index%, %tmp%
		}
	}
}

; Builds an AHK String (eg "^c" for CTRL + C) from the last detected hotkey
BuildHotkeyString(){
	global HKFound
	global HKSolitaryModifier
	global ModifierState

		;StringUpper, HKFound, HKFound
		outhk := ""
		modct := ModifierCount()

		if (HKSolitaryModifier){
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
		if (hk == "MBUTTON") {
			outstr .= "MIDDLE MOUSE"
		}
	} else if (ctrltype == 2){
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
		if (ModifierCount() == 1){
			; If ModifierCount is 1 when an up is received, then that is a Solitary Modifier
			; It cannot be a modifier + normal key, as this code would have quit on keydown of normal key

			HKSolitaryModifier := mod

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
		HKControlType := 1
		HKSecondaryInput := A_ThisHotkey
		;HKFound := A_ThisHotkey
		Send {Escape}
		return
#If

; A Joystick button was pressed while in Binding mode
JoystickPressed:
	;HKJoystick := 1
	;HKFound := A_ThisHotkey
	HKControlType := 2
	HKSecondaryInput := A_ThisHotkey
	Send {Escape}
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
