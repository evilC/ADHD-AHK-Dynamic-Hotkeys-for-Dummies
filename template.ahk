; evilC's Macro Template
; To add an extra hotkey, duplicate the lines between the vvv and ^^^ blocks
; vvvvvvvvv
; Like this
; ^^^^^^^^^
; And replace old name (eg HotKey2) with a new name - eg HotKey3


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
num_hotkeys := 2

Loop, %num_hotkeys%
{
	Gui, Add, Text,x5,HotKey %A_Index%
	IniRead, HotKey%A_Index%, %A_ScriptName%.ini, HotKeys, HotKey%A_Index%, Unset
	tmp := HotKey%A_Index%
	Gui, Add, Edit, yp-5 xp+70 W70 vHotKey%A_Index% gUIChanged ReadOnly, %tmp%
	;hkv := HotKey%A_Index%
	;GuiControl,, HotKey%A_Index%, %hkv%

	Gui, Add, Button, xp+75 yp-2 gProgramHotkey vPHK%A_Index%, Program
}

; Show the GUI =====================================
Gui, Show, x%gui_x% y%gui_y%
ignore_events := 0

Gosub, AddHotKeys

return

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKey 1

; Fired on key down
HotKey1:
	;msgbox, 1
	;Send 1
	return

; Fired on key up
HotKey1_up:
	msgbox, 1 up
	;Send q
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
; Set up HotKey 2

; Fired on key down
HotKey2:
	msgbox, 2
	;Send 2
	return

; Fired on key up
HotKey2_up:
	;Send w
	return
;^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

ProgramHotKey:
	ProgramHotKey(SubStr(A_GuiControl,4))
	return

ProgramHotKey(hk){
	global EditingHotKey
	EditingHotKey := hk
	gosub, GetInput
}
	
; UI Changed - save changes and bind keys
UIChanged:
	if (ignore_events != 1){
		Gui, Submit, NoHide
		
		Loop, %num_hotkeys%
		{
			UpdateINI("HotKey" A_Index, "HotKeys", HotKey%A_Index%, "Unset")
			if (HotKey%A_Index% != "Unset"){
				UpdateINI("HotKey" A_Index, "HotKeys", HotKey%A_Index%, "Unset")
				tmp := HotKey%A_Index%
				Hotkey, ~%tmp% , HotKey%A_Index%
				Hotkey, ~%tmp% up , HotKey%A_Index%_up
			}
		}
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

	;Disable hotkeys whilst in program mode
	Suspend, On
	
	; Add hotkeys to detect modifiers
	HotKey, ~Ctrl, ModifierDown
	HotKey, ~Ctrl up, ModifierUp
	
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
			Suspend, Off
			return
		}
		; Remove old hotkey (If present)
		GuiControlGet,HotKey%EditingHotKey%
		if (HotKey%EditingHotKey% != "Unset"){
			tmp := HotKey%EditingHotKey%
			HotKey, ~%tmp%, Off
			HotKey, ~%tmp% up, Off
		}
		
		; Set textbox to new hotkey - this will trigger saving and applying of hotkey
		GuiControl, 1:text, HotKey%EditingHotKey%, %val%
		
		; ToDo: re-enable hotkeys on up of pressed key?
		;Re-enable hotkeys
		Suspend, Off
		
		; Disable detection of modifer keys
		HotKey, ~Ctrl, Off

		return
	}
}

ModifierDown:
	Suspend		; Allows this label to work in program mode
	; detect modifier keus (ctrl, alt etc)
	return

ModifierUp:
	Suspend
	; Modifier released - use to detect "press" of a modifier and thus binding
	return

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