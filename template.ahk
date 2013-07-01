; evilC's Macro Template
; To add an extra hotkey, duplicate the lines between the vvv and ^^^ blocks
; vvvvvvvvv
; Like this
; ^^^^^^^^^
; And replace old name (eg HotKey2) with a new name - eg HotKey3

; Change the number of hotkeys here
num_hotkeys := 2

; ===== Do not edit the Header =================================================================================================
#NoEnv  ; Recommended for performance and compatibility with future AutoHotkey releases.
; #Warn  ; Enable warnings to assist with detecting common errors.
;SendMode Input  ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir %A_ScriptDir%  ; Ensures a consistent starting directory.

#InstallKeybdHook
#InstallMouseHook
 
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
Gui, Add, Text, x5 W70 Center, Name
Gui, Add, Text, xp+70 W70 Center, Keyboard
Gui, Add, Text, xp+90 W70 Center, Mouse
Gui, Add, Text, xp+92 W30 Center, Ctrl
Gui, Add, Text, xp+30 W30 Center, Shift
Gui, Add, Text, xp+30 W30 Center, Alt


Loop, %num_hotkeys%
{
	Gui, Add, Text,x5 W70 yp+30,HotKey %A_Index%
	
	IniRead, tmp, %A_ScriptName%.ini, HotKeys, HKK%A_Index%, None
	Gui, Add, Hotkey, yp-5 xp+70 W70 vHKK%A_Index% gKeyChanged, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, HotKeys, HKM%A_Index%, None
	Gui, Add, DropDownList, yp xp+80 W90 vHKM%A_Index% gMouseChanged, None||%MouseButtons%
	GuiControl, ChooseString, HKM%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, HotKeys, HKC%A_Index%, 0
	Gui, Add, CheckBox, xp+110 yp+5 W30 vHKC%A_Index% gOptionChanged
	GuiControl,, HKC%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, HotKeys, HKS%A_Index%, 0
	Gui, Add, CheckBox, xp+30 yp W30 vHKS%A_Index% gOptionChanged
	GuiControl,, HKS%A_Index%, %tmp%
	
	IniRead, tmp, %A_ScriptName%.ini, HotKeys, HKA%A_Index%, 0
	Gui, Add, CheckBox, xp+30 yp W30 vHKA%A_Index% gOptionChanged
	GuiControl,, HKA%A_Index%, %tmp%
}

; Show the GUI =====================================
Gui, Show, x%gui_x% y%gui_y%

Gui, Submit, NoHide	; Fire GuiSubmit while ignore_events is on to set all the variables
ignore_events := 0

Gosub, SetHotKeys

return
; ===== End Header ==============================================================================================================




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

; === SHOULD NOT NEED TO EDIT BELOW HERE!===========================================================================

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
			UpdateINI("HKK" A_Index, "HotKeys", HKK%A_Index%, "")
			UpdateINI("HKM" A_Index, "HotKeys", HKM%A_Index%, "None")
			UpdateINI("HKC" A_Index, "HotKeys", HKC%A_Index%, 0)
			UpdateINI("HKS" A_Index, "HotKeys", HKS%A_Index%, 0)
			UpdateINI("HKA" A_Index, "HotKeys", HKA%A_Index%, 0)
		}
	}	
	return

SetHotKeys:
	Loop, %num_hotkeys%
	{
		;soundplay, *16
		tmp := HKK%A_Index%
		if (tmp != ""){
			Hotkey, ~%tmp% , HotKey%A_Index%
			;Hotkey, ~%tmp% , On
			Hotkey, ~%tmp% up , HotKey%A_Index%_up
			;Hotkey, ~%tmp% up , On
		}
	}
	return

	
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
			}
		}
		Gosub, SetHotKeys
	}
	return

/*
SetHotKeys:
	Loop, %num_hotkeys%
	{
		;soundplay, *16
		tmp := HotKey%A_Index%
		if (tmp != "Unset"){
			Hotkey, ~%tmp% , HotKey%A_Index%
			Hotkey, ~%tmp% , On
			Hotkey, ~%tmp% up , HotKey%A_Index%_up
			Hotkey, ~%tmp% up , On
		}
	}
	return
*/

EnableHotKeys:
	;Tooltip, Hotkeys enabled
	Loop, %num_hotkeys%
	{
		tmp := HotKey%A_Index%
		if (tmp != "Unset"){
			Hotkey, ~%tmp% , On
			Hotkey, ~%tmp% up , On
		}
	}
	return
	
DisableHotKeys:
	;Tooltip, Hotkeys disabled
	Loop, %num_hotkeys%
	{
		tmp := HotKey%A_Index%
		if (tmp != "Unset"){
			Hotkey, ~%tmp% , Off
			Hotkey, ~%tmp% up , Off
		}
	}
	return

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
	global NewHotKey
	Global StateCtrl
	Global StateAlt

	Gui, 2:Destroy
	gui, 2:-caption +0x40000
	Gui, 2:Add, Text,, Press a button, ESC to cancel
	Gui, 2:Show
	WinGet, GuiID, ID, A
	WinSet, AlwaysOnTop, On, A

	;Disable hotkeys whilst in program mode
	;Suspend, On
	Gosub, DisableHotKeys
	
	; Add hotkeys to detect modifiers
	HotKey, *~Ctrl, ModifierDown
	HotKey, *~Ctrl up, ModifierUp
	StateCtrl := ""		; initialize just in case
	
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
			; Esc pressed - exit
			Gosub, EnableHotKeys
			return
		}
		; Preserve state of Modifiers early - they may change a modifier key goes up while processing
		sc := StateCtrl
		
		if (type == 1){
			tmp := sc val
			;msgbox, % tmp
		} else {
			; Transforming the result thusly turns ctrl-c into c
			; We are detecting Ctrl state,so we can add it back.
			; This is a solution to ctrl-c etc not being readable
			Transform, tmp, Asc, %tmp%
			if (sc == "^"){
				soundplay, *16
				tmp := tmp + 96
			}
			Transform, tmp, Chr, %val%
			tmp := sc val
		}
		;Tooltip, % val
		;Tooltip, % "*" sc "*"
		GuiControlGet,HotKey%EditingHotKey%
		if (HotKey%EditingHotKey% != val){
			; Remove old hotkey (If present)
			RemoveHotKey(EditingHotKey)
			; Only actually do the program if the key has not changed
			;NewHotKey := val
			NewHotKey := tmp
			if (type == 1){
				/*
				Tooltip, %tmp%
				HotKey, ~%tmp% up, ProgrammedKeyReleased
				HotKey, ~%tmp% up, On
				*/
				Tooltip, *%sc%%val%/%tmp%*
				test := sc val
				HotKey, ~%tmp% up, ProgrammedKeyReleased
				;HotKey, ~^MButton up, On
			}
			else
			{
				HotKey, ~%val% up, ProgrammedKeyReleased
			}
		}
		return
	}
}

; The key just programmed was released
ProgrammedKeyReleased:
	;soundplay, *16
	; Disable detection of modifer keys
	;HotKey, ~Ctrl, Off
	;HotKey, ~Ctrl up, Off
		
	HotKey, %A_ThisHotkey%, Off
	
	; Set textbox to new hotkey - this will trigger saving and applying of hotkeys
	GuiControl, 1:text, HotKey%EditingHotKey%, %NewHotKey%
	;GUI, submit, nohide
	
	;Re-enable hotkeys
	Suspend, Off
	Gosub, EnableHotKeys
	
	NewHotKey := ""
	return


RemoveHotKey(hk){
	tmp := HotKey%hk%
	if (tmp != "Unset"){
		; ToDo: Is there a better way to remove a hotkey?
		HotKey, ~%tmp%, DoNothing
		HotKey, ~%tmp% up, DoNothing
	}
}

; An empty stub to redirect unbound hotkeys to
DoNothing:
	return
	
ModifierDown:
	; detect modifier keys (ctrl, alt etc)
	StateCtrl := "^"
	;Send {LCtrl up}
	return

ModifierUp:
	; Modifier released - use to detect "press" of a modifier and thus binding
	StateCtrl := ""
	;if (NewHotKey != ""){
	;	Gosub, ProgrammedKeyReleased
	;}
	return

; Detect Keyboard input
getKey(){
	Input, bp, L1 M, T0.1
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
		if (getkeystate(A_LoopField)){
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

; Code from http://www.autohotkey.com/board/topic/47439-user-defined-dynamic-hotkeys/
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
  Gui, Submit, NoHide             ;If BackSpace is the first key press, Gui has never been submitted.
  If (A_ThisHotkey == "*BackSpace" && %ctrl% && !modifier)   ;If the control has text but no modifiers held,
   GuiControl,,%ctrl%                                       ;  allow BackSpace to clear that text.
  Else                                                     ;Otherwise,
   GuiControl,,%ctrl%, % modifier SubStr(A_ThisHotkey,2)  ;  show the hotkey.
  ;validateHK(ctrl)
 return
#If

HotkeyCtrlHasFocus() {
 GuiControlGet, ctrl, Focus       ;ClassNN
 If InStr(ctrl,"hotkey") {
  GuiControlGet, ctrl, FocusV     ;Associated variable
  Return, ctrl
 }
}
