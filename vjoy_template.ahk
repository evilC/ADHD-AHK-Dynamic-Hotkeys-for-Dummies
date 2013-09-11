; vJoy Template for ADHD
; An example script to show how to build a virtual joystick app with ADHD

; Uses Shaul's vJoy - http://http://vjoystick.sourceforge.net/site/ - install this first
; Then you need the AHK vJoy library - grab the VJoyLib folder from my UJR project: 
; https://github.com/evilC/AHK-Universal-Joystick-Remapper/tree/master/VJoyLib
; And place it in your AutoHotkey Lib folder (C:\Program Files\Autohotkey\Lib)
; So you end up with a C:\Program Files\Autohotkey\Lib\VjoyLib folder.
; (The vJoyLib folder is also packaged in the UJR release zip) - http://evilc.com/proj/ujr


; Create an instance of the library
ADHD := New ADHDLib

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "vJoy Template", version: 0.1, author: "evilC", link: "<a href=""http://evilc.com/proj/adhd"">Homepage</a>"})
; The default application to limit hotkeys to.

; GUI size
ADHD.config_size(375,200)

; We need no actions, so disable warning
ADHD.config_ignore_noaction_warning()

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("option_changed", "option_changed_hook")

ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

axis_list_ahk := Array("X","Y","Z","R","U","V")

Gui, Add, GroupBox, x5 yp+25 W365 R2 section, Input Configuration
Gui, Add, Text, x15 ys+20, Joystick ID
ADHD.gui_add("DropDownList", "JoyID", "xp+80 yp-5 W50", "1|2|3|4|5|6|7|8", "1")
JoyID_TT := "The ID (Order in Windows Game Controllers?) of your Joystick"

Gui, Add, Text, xp+60 ys+20, Axis
ADHD.gui_add("DropDownList", "JoyAxis", "xp+80 yp-5 W50", "1|2|3|4|5|6", "1")
JoyAxis_TT := "The Axis on that stick that you wish to use"

ADHD.gui_add("CheckBox", "InvertAxis", "xp+60  yp+5", "Invert Axis", 0)
InvertAxis_TT := "Inverts the input axis.`nNot intended to be used with ""Use Half Axis"""

Gui, Add, GroupBox, x5 yp+45 R2 W365 section, Debugging
Gui, Add, Text, x15 ys+15, Current axis value
Gui, Add, Edit, xp+120 yp-2 W50 R1 vAxisValueIn ReadOnly,
AxisValueIn_TT := "Raw input value of the axis.`nIf you have Joystick ID and axis set correctly,`nmoving the axis should change the numbers here"

Gui, Add, Text, xp+60 ys+15, Adjusted axis value
Gui, Add, Edit, xp+100 yp-2 W50 R1 vAxisValueOut ReadOnly,
AxisValueOut_TT := "Input value adjusted according to options`nShould be 0 at center, 100 at full deflection"

; End GUI creation section
; ============================================================================================


axis_list_ahk := Array("X","Y","Z","R","U","V")

; Start vJoy setup
axis_list_vjoy := Array("X","Y","Z","RX","RY","RZ","SL0","SL1")

#include <VJoy_lib>
LoadPackagedLibrary() {
	SplitPath, A_AhkPath,,tmp
    if (A_PtrSize < 8) {
        dllpath := tmp "\Lib\VJoyLib\x86\vJoyInterface.dll"
    } else {
        dllpath := tmp "\Lib\VJoyLib\x64\vJoyInterface.dll"
    }
    hDLL := DLLCall("LoadLibrary", "Str", dllpath)
    if (!hDLL) {
        MsgBox, [%A_ThisFunc%] Failed to find DLL at %dllpath%
    }
    return hDLL
}
; Load DLL
LoadPackagedLibrary()

; ID of the virtual stick (1st virtual stick is 1)
vjoy_id := 1

; Init Vjoy library
VJoy_Init(vjoy_id)
; End vjoy setup

ADHD.finish_startup()

; Loop runs endlessly...
Loop, {
	; Get the value of the axis the user has selected as input
	axis := conform_axis()
	
	; Assemble the string which sets which virtual axis will be manipulated
	vjaxis := axis_list_vjoy[2]
	
	; input is in range 0->100, but vjoy operates in 0->32767, so convert to correct output format
	axis := axis * 327.67
	
	; Set the vjoy axis
	VJoy_SetAxis(axis, vjoy_id, HID_USAGE_%vjaxis%)
	
	; Sleep a bit to chew up less CPU time
	Sleep, 10
	
}
return

; Conform the input value from an axis to a range between 0 and 100
; Handles invert, half axis usage (eg xbox left trigger) etc
conform_axis(){
	global axis_list_ahk
	global JoyID
	global JoyAxis
	global InvertAxis
	global HalfAxis
	global DeadZone
	
	tmp := JoyID "Joy" axis_list_ahk[JoyAxis]
	GetKeyState, axis, % tmp
	
	GuiControl,,AxisValueIn, % round(axis,1)
	
	if (InvertAxis){
		axis := 100 - axis
	}

	GuiControl,,AxisValueOut, % round(axis,1)
	
	return axis
}

app_active_hook(){

}

app_inactive_hook(){

}

option_changed_hook(){
	global ADHD

}

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
