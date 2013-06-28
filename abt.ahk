; evilC's Macro Template
; To add an extra hotkey, duplicate the lines between the vvv and ^^^ blocks
; vvvvvvvvv
; Like this
; ^^^^^^^^^
; And replace old name (eg HotKeyOne) with a new name - eg HotKeyThree


; ===== Do not edit the Header ======
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#InstallKeybdHook
#InstallMouseHook

OnExit, GuiClose

debug := 0
EditingHotKey := ""
MouseButtons := "Esc,LButton,RButton,MButton,XButton1,XButton2,WheelUp,WheelDown,WheelLeft,WheelRight"

ignore_events := 1	; Setting this to 1 while we load the GUI allows us to ignore change messages generated while we build the GUI

IniRead, gui_x, %A_ScriptName%.ini, Settings, gui_x, 0
IniRead, gui_y, %A_ScriptName%.ini, Settings, gui_y, 0
if (gui_x == ""){
	gui_x := 0	; in case of crash empty values can get written
}
if (gui_y == ""){
	gui_y := 0
}
; ===== End Header =====

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Uncomment and alter to limit hotkeys to one specific program
;Hotkey, IfWinActive, ahk_class CryENGINE

; Set up the GUI

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Add the GUI for HotKeyOne
Gui, Add, Text,x5,HotKey One
Gui, Add, Edit, yp-5 xp+70 W70 vHotKeyOne gUIChanged ReadOnly, Unset
IniRead, HotKeyOne, %A_ScriptName%.ini, HotKeys, HotKeyOne, Unset
GuiControl,, HotKeyOne, %HotKeyOne%

Gui, Add, Button, xp+75 yp-2 gProgramHotKeyOne, Program
; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Add the GUI for HotKeyTwo
Gui, Add, Text,x5,HotKey Two
Gui, Add, Edit, yp-5 xp+70 W70 vHotKeyTwo gUIChanged ReadOnly, Unset
IniRead, HotKeyTwo, %A_ScriptName%.ini, HotKeys, HotKeyTwo, Unset
GuiControl,, HotKeyTwo, %HotKeyTwo%

Gui, Add, Button, xp+75 yp-2 gProgramHotKeyTwo, Program
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; Show the GUI =====================================
Gui, Show, x%gui_x% y%gui_y%
ignore_events := 0

return

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKeyOne

; Fired on key down
HotKeyOne:
	Send 1
	return

; Fired on key up
HotKeyOneUp:
	Send q
	return

; Button for Program HotKeyOne pressed
ProgramHotKeyOne:
	EditingHotKey := "HotKeyOne"
	gosub, GetInput
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKeyTwo

; Fired on key down
HotKeyTwo:
	Send 2
	return

; Fired on key up
HotKeyTwoUp:
	Send w
	return

; Button for Program HotKeyTwo pressed
ProgramHotKeyTwo:
	EditingHotKey := "HotKeyTwo"
	gosub, GetInput
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; UI Changed - save changes and bind keys
UIChanged:
	if (ignore_events != 1){
		Gui, Submit, NoHide
		
		; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		UpdateINI("HotKeyOne", "HotKeys", HotKeyOne, "Unset")
		if (HotKeyOne != "Unset"){
			UpdateINI("HotKeyOne", "HotKeys", HotKeyOne, "Unset")
			Hotkey, %HotKeyOne%, HotKeyOne
			Hotkey, %HotKeyOne% up, HotKeyOneUp
		}
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
		
		; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
		if (HotKeyTwo != "Unset"){
			UpdateINI("HotKeyTwo", "HotKeys", HotKeyTwo, "Unset")
			Hotkey, %HotKeyTwo%, HotKeyTwo
			Hotkey, %HotKeyTwo% up, HotKeyTwoUp
		}
		;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

	}
	return

; === SHOULD NOT NEED TO EDIT BELOW HERE!===========================================================================

; Program pressed - DO NOT DIRECTLY CALL WITH A BUTTON, SET EditingHotKey FIRST!
GetInput:
	gui, 2:-caption +0x40000
	Gui, 2:Add, Button, gGetKey, Keyboard
	Gui, 2:Add, Button, gGetMouse xp+70 yp, Mouse
	Gui, 2:Show
	WinGet, GuiID, ID, A
	WinSet, AlwaysOnTop, On, A
	return

; Keyboard option chosen
GetKey:
	getInput(0)
	return

; Mouse option chosen
GetMouse:
	getInput(1)
	return
	
; Wait for user input
getInput(type){
	global debug
	global EditingHotKey

	Gui, 2:Destroy
	gui, 2:-caption +0x40000
	Gui, 2:Add, Text,, Press a button, ESC to cancel
	Gui, 2:Show
	WinGet, GuiID, ID, A
	WinSet, AlwaysOnTop, On, A

	// Disable hotkeys whilst in program mode
	Suspend, On
	
	Loop
	{
		if (type == 0){
			val := getKey()
		} else {
			val := getMouse()
		}
		if (val == -1){
			; -1 (No input) returned - go to next loop
			continue
		}
		; Input detected
		Gui, 2:Destroy
		if (val == -2){
			; Esc pressed - do nothing
			return
		}
		guicontrol, 1:text, %EditingHotKey%, %val%
		Gui, Submit, NoHide

		// Re-enable hotkeys
		Suspend, Off

		return
	}
}

; Detect Keyboard input
getKey(){
	Input, bp, L1, T0.1
	if (bp == "")
	{
		return -2
	}
	if (ErrorLevel == "Timeout")
	{
		return -1
	}
	else
	{
		return bp
	}
}

; Detect Mouse (Plus Esc to cancel) input
getMouse(){
	global MouseButtons
	
	Loop, parse, MouseButtons, `,
	{
		if (getkeystate(A_LoopField,"P")){
			if (A_LoopField == "Esc"){
				return -2
			} else {
				return A_LoopField
			}
		}
	}
	return -1
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