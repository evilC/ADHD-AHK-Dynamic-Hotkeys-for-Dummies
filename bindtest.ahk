; Proof of concept for replacement of Hotkey GUI Item

#InstallKeybdHook
#InstallMouseHook

EXTRA_KEY_LIST := "{Esc}{F1}{F2}{F3}{F4}{F5}{F6}{F7}{F8}{F9}{F10}{F11}{F12}{Left}{Right}{Up}{Down}{Home}{End}{PgUp}{PgDn}{Del}{Ins}{BS}{Capslock}{Numlock}{PrintScreen}{Pause}{Media_Play_Pause}"

SingleKey := ""

ModifierState := {}
lasthk := ""

Gui, Add, Edit, Disabled vHotkeyName w250, None
Gui, Add, Button, gBind yp-1 xp+260, Set Hotkey
Gui, Show, Center w350 h50, Keybind Test
return

Bind:
	Bind()
	return

Bind(){
	global ModifierState
	global BindMode
	global EXTRA_KEY_LIST
	global lasthk
	global found

	found := 0
	ModifierState := {ctrl: 0, alt: 0, shift: 0, win: 0}
	Gui, 2:Add, text, center, Please press the desired key combination.`n`n Supports most keyboard keys and all mouse buttons. Also Ctrl, Alt, Shift, Win as modifiers or individual keys.`n`nHit Escape to cancel
	Gui, 2:-Border +AlwaysOnTop
	Gui, 2:Show

	BindMode := 1
	Loop {
		Input, SingleKey, L1 M T0.1, %EXTRA_KEY_LIST%
		if (ErrorLevel == "Max" ) {
			found := SingleKey
		} else if (substr(ErrorLevel,1,7) == "EndKey:"){
			tmp := substr(ErrorLevel,8)
			if (tmp == "Escape"){
				break
			}
			found := tmp
		}
		if (found){
			break
		}
	}
	BindMode := 0
	Gui, 2:Submit
	if (found){
		outstring := ""
		outhk := ""
		if (ModifierCount()){
			; List modifiers in a specific order
			modifiers := ["ctrl","alt","shift","win"]

			Loop, 4 {
				key := modifiers[A_Index]
				value := ModifierState[modifiers[A_Index]]
				if (value){
					if (outstring != ""){
						outstring .= " + "
					}
					stringupper, tmp, key
					outstring .= tmp

					if (key == "ctrl"){
						outhk .= "^"
					} else if (key == "alt"){
						outhk .= "!"
					} else if (key == "shift"){
						outhk .= "+"
					} else if (key == "win"){
						outhk .= "#"
					}
				}
			}
			if (outstring != ""){
				outstring .= " + "
			}
			outhk .= found
			StringUpper, found, found
			outstring .= found
		} else {
			StringUpper, found, found
			mod := substr(found,2)
			pref := substr(found,1,1)
			if (pref == "L"){
				pref := "LEFT"
			} else if (pref == "R"){
				pref := "RIGHT"
			}
			outstring := pref " " mod
			outhk := found
		}

		if (lasthk != ""){
			hotkey, ~*%lasthk%, Off
		}
		lasthk := outhk
		hotkey, ~*%outhk%, DoHotkey

		GuiControl,, HotkeyName, %outstring%
		;msgbox % "Hotkey Detected.`n`nHuman-Readable: " outstring "`nAHK Hotkey string: " outhk
	}
	return
}

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
		;if other modifiers still held, do not set found
		found := mod
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
	soundbeep
	found := A_ThisHotkey
	return

#If

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