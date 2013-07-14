; Fire Control - Sample ADHD macro

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

ADHD.config_about({name: "Fire Control", version: 2.5, author: "evilC", link: "<a href=""http://evilc.com/proj/firectrl"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(375,220)

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "Fire", subroutine: "Fire"})
ADHD.config_hotkey_add({uiname: "Change Fire Rate", subroutine: "ChangeFireRate"})
ADHD.config_hotkey_add({uiname: "Weapon Toggle", subroutine: "WeaponToggle"})

; Hook into ADHD events
; First parameter is name of event to hook into, second parameter is a function name to launch on that event
ADHD.config_event("option_changed", "option_changed_hook")
ADHD.config_event("program_mode_on", "program_mode_on_hook")
ADHD.config_event("program_mode_off", "program_mode_off_hook")
ADHD.config_event("app_active", "app_active_hook")
ADHD.config_event("app_inactive", "app_inactive_hook")
ADHD.config_event("disable_timers", "disable_timers_hook")
ADHD.config_event("resolution_changed", "resolution_changed_hook")

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
Gui, Add, Text, x5 y40, Fire Sequence
; Create Edit box that has state saved in INI
ADHD.gui_add("Edit", "FireSequence", "xp+120 yp W120", "", "")
; Create tooltip by adding _TT to the end of the Variable Name of a control
FireSequence_TT := "A comma separated list of keys to hit - eg 1,2,3,4"

Gui, Add, Text, x5 yp+25, Fire Rate (ms)
ADHD.gui_add("Edit", "FireRate", "xp+120 yp W120", "", 100)

Gui, Add, Text, x5 yp+25, Weapon Toggle group
ADHD.gui_add("DropDownList", "WeaponToggle", "xp+120 yp-2 W50", "None|1|2|3|4|5|6", "None")

ADHD.gui_add("CheckBox", "LimitFire", "x5 yp+30", "Limit fire rate to specified rate (Stop 'Over-Clicking')", 0)

Gui, Add, Link, x5 yp+35, Works with many games, perfect for <a href="http://mwomercs.com">MechWarrior Online</a> (FREE GAME!)

; End GUI creation section
; ============================================================================================


ADHD.finish_startup()
return

; ============================================================================================
; CODE SECTION

; Place your hotkey definitions and associated functions here
; When writing code, DO NOT create variables or functions starting adhd_



; Macro is trying to fire - timer label
DoFire:
	; Turn the timer off and on again so that if we change fire rate it takes effect after the next fire
	Gosub, DisableTimers
		
	out := fire_array[current_weapon]
	Send % out
	tmp := FireRate / fire_divider
	SetTimer, DoFire, % tmp
	nextfire := A_TickCount + (tmp)

	current_weapon := current_weapon + 1
	if (current_weapon > fire_array.MaxIndex()){
		current_weapon := 1
	}
	return

; used to start or stop the fire timer
SetFireTimer(mode,delay){
	global FireRate
	global nextfire
	global fire_divider
	
	if(mode == 0){
		Gosub, DisableTimers
	} else {
		tim := (FireRate / fire_divider)
		if (delay == false){
			SetTimer, DoFire, %tim%
		} else {
			SetTimer, DoFire, % nextfire - A_TickCount
		}
	}
}

; Turn the weapon toggle on
EnableToggle:
	SetScrollLockState, On
	Send {%WeaponToggle% down}
	return

; Turn the weapon toggle off
DisableToggle:
	SetScrollLockState, Off
	Send {%WeaponToggle% up}
	return

; Keep all timer disables in here so various hooks and stuff can stop all your timers easily.
DisableTimers:
	SetTimer, DoFire, Off
	return


; Hook functions. We declared these in the config phase - so make sure these names match the ones defined above

; This is fired when settings change (including on load). Use it to pre-calculate values etc.
option_changed_hook(){
	firectrl_init()
	return
}

firectrl_init(){
	global FireSequence
	global fire_array := []
	global current_weapon := 1
	global fire_divider := 1
	global nextfire := 0		; A timer for when we are next allowed to press the fire button
	global weapon_toggle_mode := false
	Gosub, DisableToggle
	
	; This gets called in Program Mode, so now would be a good time to re-initialize
	
	; Split FireSequence box from comma separated list to array
	StringSplit, tmp, FireSequence, `,
	Loop, %tmp0%
	{
		if (tmp%A_Index% != ""){
			fire_array[A_Index] := tmp%A_Index%
		}
	}
}

; Gets called when the "Limited" app gets focus
app_active_hook(){
	
	return
}

; Gets called when the "Limited" app loses focus
app_inactive_hook(){
	firectrl_init()
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
	firectrl_init()
	Gosub, DisableTimers
}

; Fired when the limited app changes resolution. Useful for some games that have a windowed matchmaker and fullscreen game
resolution_changed_hook(){
	global ADHD
	
	curr_size := ADHD.limit_app_get_size()
	last_size := ADHD.limit_app_get_last_size()
	ADHD.debug("Res change: " curr_size.w "x" curr_size.h " --> " last_size.w "x" last_size.h)
	if (curr_size.w > last_size.w || curr_size.h > last_size.h){
		; Got larger - lobby to game
		ADHD.debug("FC: Res got bigger")
	} else {
		; Got smaller game to lobby
		ADHD.debug("FC: Res got smaller")
		firectrl_init()
		Gosub, DisableTimers		
	}
	return
}

; ==========================================================================================
; HOTKEYS SECTION

; This is where you define labels that the various bindings trigger Make sure you call them the same names as you set in the settings at the top of the file (eg Fire, FireRate)

; Set up HotKey 1

; Fired on key down
Fire:
	; Many games do not work properly with autofire unless this is enabled.
	; You can try leaving it out.
	; MechWarrior Online for example will not do fast (<~500ms) chain fire with weapons all in one group without this enabled
	ADHD.send_keyup_on_press("Fire","unmodified")


	; If we clicked the button too early, play a sound and schedule a click when it is OK to fire
	; If the user releases the button, the timer will terminate
	if (LimitFire && A_TickCount < nextfire){
		soundplay, *16
		SetFireTimer(1,true)
		return
	}
	
	; Fire Lazors !!!
	GoSub, DoFire

	; Start the fire timer
	SetFireTimer(1,false)
	return

; Fired on key up
FireUp:
	; Kill the timer when the key is released (Stop auto firing)
	SetFireTimer(0,false)
	return

; Set up HotKey 2

; Fired on key down
ChangeFireRate:
	; More Lazors!! Toggles double speed fire!
	; Toggle divider between 1 and 2
	fire_divider := 3 - fire_divider
	return

; Set up Hotkey 3
WeaponToggle:
	weapon_toggle_mode := !weapon_toggle_mode
	if (weapon_toggle_mode){
		Gosub, EnableToggle
	} else {
		Gosub, DisableToggle
	}
	return
	
; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
