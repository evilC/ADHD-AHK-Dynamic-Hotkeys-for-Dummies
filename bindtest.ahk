; Proof of concept for replacement of Hotkey GUI Item

/*

ToDo:
* Joystick buttons plus modifiers does not work - triggers without modifier.
  Probably requires detecting joystick with GetKeyState loop.
  GetKeyState would be required to support up events anyway.
* Joystick POV support
  Again, GetKeyState loop would fix
* Allow adding to EXTRA_KEY_LIST by users

*/

#InstallKeybdHook
#InstallMouseHook

EXTRA_KEY_LIST := "{Esc}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Media_Play_Pause}"

SingleKey := ""

ModifierState := {}
HKLast := ""

HKJoystick := 0
HKModifier := 0

Gui, Add, Edit, Disabled vHotkeyName w250, None
Gui, Add, Button, gBind yp-1 xp+260, Set Hotkey
Gui, Show, Center w350 h50, Keybind Test
return

Bind:
	Bind()
	return


; Detects a pressed key combination
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

	; Disable existing hotkey
	if (HKLast != ""){
		hotkey, ~*%HKLast%, , Off
	}

	; Enable Joystick detection hotkeys
	JoystickDetection(1)

	; Start Bind Mode - this starts detection for mouse buttons and modifier keys
	BindMode := 1

	; Show the prompt
	Gui, 2:Add, text, center, Please press the desired key combination.`n`n Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n`nHit Escape to cancel
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
		StringUpper, HKFound, HKFound
		outstring := ""
		outhk := ""

		if (HKModifier){
			; Solitary modifier key used (eg Left / Right Alt)
			mod := substr(HKFound,2)
			pref := substr(HKFound,1,1)
			if (pref == "L"){
				pref := "LEFT"
			} else if (pref == "R"){
				pref := "RIGHT"
			}
			outstring := pref " " mod
			outhk := HKFound
		} else {
			if (modct){
				; Modifiers used in combination with something else - List modifiers in a specific order
				modifiers := ["CTRL","ALT","SHIFT","WIN"]

				Loop, 4 {
					key := modifiers[A_Index]
					value := ModifierState[modifiers[A_Index]]
					if (value){
						if (outstring != ""){
							outstring .= " + "
						}
						stringupper, tmp, key
						outstring .= tmp

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
				if (outstring != ""){
					outstring .= " + "
				}
			}
			; Modifiers etc processed, complete the strings
			outhk .= HKFound
			if (HKJoystick){
				pos := instr(HKFound,"JOY")
				id := substr(HKFound,1,pos-1)
				button := substr(HKFound,5)
				outstring .= "JOYSTICK " id " BTN " button
			} else {
				outstring .= HKFound
			}
		}

		; Store the hotkey so it can be disabled later
		HKLast := outhk

		; Enable the hotkey
		hotkey, ~*%outhk%, DoHotkey, ON

		; Update the GUI control
		GuiControl,, HotkeyName, %outstring%
	} else {
		; Escape was pressed - resotre original hotkey
		if (HKLast != ""){
			hotkey, ~*%HKLast%, DoHotkey, ON
		}
	}
	return
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
