; ADHD Bare bones template
; Simply creates an edit box and binds a hotkey to send the contents of the edit box on press of the hotkey

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
;ADHD.config_ignore_x64_warning()	; Uncomment this if you need to compile an x64 ADHD exe
ADHD.config_about({name: "Template", version: 1.0, author: "nobody", link: "<a href=""http://google.com"">Somewhere</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("Notepad")

; GUI size
;ADHD.config_size(375,150)

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "Fire", subroutine: "Fire"})

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("program_mode_on", "program_mode_on_hook")
ADHD.config_event("program_mode_off", "program_mode_off_hook")
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("disable_timers", "disable_timers_hook")
ADHD.config_event("resolution_changed", "resolution_changed_hook")


; End Setup section
; ============================================================================================

ADHD.init()
ADHD.create_gui()

; The "Main" tab is tab 1
Gui, Tab, 1
; ============================================================================================
; GUI SECTION

; Create your GUI here
; If you want a GUI item's state saved in the ini file, create it like this:
; ADHD.gui_add("ControlType", "MyControl", "MyOptions", "Param3", "Default")
; eg ADHD.gui_add("DropDownList", "MyDDL", "xp+120 yp W120", "1|2|3|4|5", "3")
; The order is Control Type,(Variable)Name, Options, Param3, Default Value
; the Format is basically the same as an AHK Gui, Add command
; DO NOT give a control the same name as one of your hotkeys (eg Fire, ChangeFireRate)

; Otherwise, for GUI items that do not need to be saved, create them as normal

; Create normal label
Gui, Add, Text, x5 y40, String to Send
; Create Edit box that has state saved in INI
ADHD.gui_add("Edit", "StringToSend", "xp+120 yp W120", "", "")
; Create tooltip by adding _TT to the end of the Variable Name of a control
StringToSend_TT := "Speed at which to Fire"

; End GUI creation section
; ============================================================================================


ADHD.finish_startup()
return


; ============================================================================================
; CODE SECTION

; Place your hotkey definitions and associated functions here
; When writing code, DO NOT create variables or functions starting adhd_

; Hook functions. We declared these in the config phase - so make sure these names match the ones defined above

; This is fired when settings change (including on load). Use it to pre-calculate values etc.
option_changed_hook(){
	return
}

; Gets called when the "Limited" app gets focus
app_active_hook(){
	return
}

; Gets called when the "Limited" app loses focus
app_inactive_hook(){
	Gosub, DisableTimers
}

; Gets called if ADHD wants to stop your timers
disable_timers_hook(){
	Gosub, DisableTimers
}

; Gets called when we enter program mode
program_mode_on_hook(){
	Gosub, DisableTimers
}

; Gets called when we exit program mode
program_mode_off_hook(){
	Gosub, DisableTimers
}

; Fired when the limited app changes resolution. Useful for some games that have a windowed matchmaker and fullscreen game
resolution_changed_hook(){

}

; Keep all timer disables in here so various hooks and stuff can stop all your timers easily.
; DisableTimers is referened by the hooks
DisableTimers:
	;SetTimer, MyTimer, Off
	return


; ==========================================================================================
; HOTKEYS SECTION

; This is where you define labels that the various bindings trigger
; Make sure you call them the same names as you set in the settings at the top of the file (eg Fire, FireRate)

; Set up HotKey 1

; Fired on key down
Fire:
	; Many games do not work properly with autofire unless this is enabled.
	; You can try leaving it out.
	; MechWarrior Online for example will not do fast (<~500ms) chain fire with weapons all in one group without this enabled
	ADHD.send_keyup_on_press("Fire","unmodified")
	
	Send %StringToSend%
	return

; Fired on key up
FireUp:
	; Kill the timer when the key is released (Stop auto firing)
	return

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
