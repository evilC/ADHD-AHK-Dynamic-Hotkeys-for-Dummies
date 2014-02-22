; Fire Control - Sample ADHD macro

#SingleInstance Off

; Create an instance of the library
ADHD := New ADHDLib

; Ensure running as admin
ADHD.run_as_admin()

; ============================================================================================
; CONFIG SECTION - Configure ADHD

; Authors - Edit this section to configure ADHD according to your macro.
; You should not add extra things here (except add more records to hotkey_list etc)
; Also you should generally not delete things here - set them to a different value instead

; You may need to edit these depending on game
SendMode, Event
SetKeyDelay, 0, 50

; Stuff for the About box

ADHD.config_about({name: "Fire Control", version: 3.0, author: "evilC", link: "<a href=""http://evilc.com/proj/firectrl"">Homepage</a>"})
; The default application to limit hotkeys to.
; Starts disabled by default, so no danger setting to whatever you want
ADHD.config_default_app("CryENGINE")

; GUI size
ADHD.config_size(450,335)

; Configure update notifications:
ADHD.config_updates("http://evilc.com/files/ahk/mwo/firectrl/firectrl.au.txt")

; Defines your hotkeys 
; subroutine is the label (subroutine name - like MySub: ) to be called on press of bound key
; uiname is what to refer to it as in the UI (ie Human readable, with spaces)
ADHD.config_hotkey_add({uiname: "Fire", subroutine: "Fire"})
ADHD.config_hotkey_add({uiname: "Change Fire Rate", subroutine: "ChangeFireRate"})
ADHD.config_hotkey_add({uiname: "Weapon Toggle", subroutine: "WeaponToggle"})
ADHD.config_hotkey_add({uiname: "Arm Lock Toggle", subroutine: "ArmLockToggle"})
ADHD.config_hotkey_add({uiname: "Fire Mode Toggle", subroutine: "FireModeToggle"})
ADHD.config_hotkey_add({uiname: "Jump Jet Spam", subroutine: "JumpJetSpam"})
adhd_hk_k_5_TT := "Jump Jet spam will hit the Jump Jet key (Specified on the Main tab) quickly.`nThis helps prevent RSI when climbing hills etc."
;ADHD.config_hotkey_add({uiname: "Functionality Toggle", subroutine: "FunctionalityToggle"})

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
ADHD.gui_add("Edit", "FireSequence", "xp+120 yp-2 W240", "", "")
; Create tooltip by adding _TT to the end of the Variable Name of a control
FireSequence_TT := "A comma separated list of keys to hit - eg 1,2,3,4"

Gui, Add, Text, x5 yp+30, Fire Rate (ms)
ADHD.gui_add("Edit", "FireRate", "xp+120 yp-2 W50", "", 100)

Gui, Add, Text, x5 yp+30, Weapon Toggle group
ADHD.gui_add("DropDownList", "WeaponToggle", "xp+120 yp-2 W50", "None|1|2|3|4|5|6|7|8|9|0", "None")

Gui, Add, Text, x5 yp+30, Arm Lock Toggle key
ADHD.gui_add("DropDownList", "ArmLockToggle", "xp+120 yp-2 W50", "None|7|8|9|0|l", "None")

ADHD.gui_add("CheckBox", "LimitFire", "x5 yp+30", "Limit fire rate to specified rate (Stop 'Over-Clicking')", 0)

Gui, Add, Text, x5 yp+30, Scroll Lock indicates status of
ADHD.gui_add("DropDownList", "ScrollLockSetting", "xp+150 yp-2", "None|Weapon Toggle|Arm Lock Toggle|Fire Rate|Fire Mode", "None")

Gui, Add, Text, x5 yp+35, MWO Jump Jet key
ADHD.gui_add("Edit", "JumpJetKey", "xp+100 yp-2 W50", "", "Space")
JumpJetKey_TT := "The key bound to Jump Jets in MWO.`nOnly needed if you use the 'Jump Jet Spam' feature."

Gui, Add, Text, xp+80 yp+2, Jump Jet Spam Rate (ms)
ADHD.gui_add("Edit", "JumpJetRate", "xp+130 yp-2 W50", "", "250")
JumpJetKey_TT := "The rate at which Jump Jet Spam hits the Jump Jet key (in ms).`nOnly needed if you use the 'Jump Jet Spam' feature."

Gui, Add, Link, x5 yp+40, Works with many games, perfect for <a href="http://mwomercs.com">MechWarrior Online</a> (FREE GAME!)

; End GUI creation section
; ============================================================================================

ADHD.finish_startup()
fire_divider := 1
last_divider := 1
arm_lock_toggle_mode := false
weapon_toggle_mode := false
jj_active := 0

; Turn off scroll lock if it is used to indicate a status
if (ScrollLockSetting != "None"){
	SetScrollLockState, Off
}

return

; ============================================================================================
; CODE SECTION

; Place your hotkey definitions and associated functions here
; When writing code, DO NOT create variables or functions starting adhd_



; Macro is trying to fire - timer label
DoFire:
	now := A_TickCount
	out := fire_array[current_weapon]
	if (groupmode){
		tmp := groupmode_array[1]
		Send {%tmp% down}
	} else {
		; If it is the first shot, process stagger...
		if (fire_array_count == 1 && stagger_array[current_weapon] != ""){
			nextfire := now + stagger_array[current_weapon]
			SetFireTimer(1,1)
		} else {
			nextfire := now + (FireRate / fire_divider)
			SetFireTimer(1,false)
		}
		Send % out
	}
	/*
	; If fire rate changes mid-fire, stop the timer and re-start it at new rate
	if (last_divider != fire_divider){
		SetFireTimer(1,false)
	}
	*/

	fire_array_count++
	current_weapon := current_weapon + 1
	if (current_weapon > fire_array.MaxIndex()){
		current_weapon := 1
	}
	return

; used to start or stop the fire timer
; mode: 0|1 - Enables / Disables timer
; delay: 0 - next fire is FireRate ms from now
; delay: 1 - next fire is at nextfire ("Limit Fire Rate" is being used - schedule fire for when window is up)
SetFireTimer(mode,delay){
	global FireRate
	global nextfire
	global fire_divider
	global last_divider
	
	; Set last_divider, so we tell when the fire_divider changes
	last_divider := fire_divider
	
	if(mode == 0){
		Gosub, DisableTimers
	} else {
		tim := (FireRate / fire_divider)
		if (delay){
			SetTimer, DoFire, % nextfire - A_TickCount
		} else {
			SetTimer, DoFire, %tim%
		}
	}
}

; Turn the weapon toggle on
EnableToggle:
	if (ScrollLockSetting == "Weapon Toggle"){
		SetScrollLockState, On
	}
	weapon_toggle_mode := true
	Send {%WeaponToggle% down}
	return

; Turn the weapon toggle off
DisableToggle:
	if (ScrollLockSetting == "Weapon Toggle"){
		SetScrollLockState, Off
	}
	weapon_toggle_mode := false
	Send {%WeaponToggle% up}
	return

; Turn the arm lock toggle on
EnableArmLockToggle:
	if (ScrollLockSetting == "Arm Lock Toggle"){
		SetScrollLockState, On
	}
	arm_lock_toggle_mode := true
	Send {%ArmLockToggle% down}
	return

; Turn the arm lock off
DisableArmLockToggle:
	if (ScrollLockSetting == "Arm Lock Toggle"){
		SetScrollLockState, Off
	}
	arm_lock_toggle_mode := false
	Send {%ArmLockToggle% up}
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
	global ADHD
	global FireSequence
	global fire_array := []
	global groupmode := 0
	global groupmode_array := []
	global stagger_array := []
	global fire_array_reset_on_release := 0
	global fire_array_count := 1
	global current_weapon := 1
	global fire_divider
	global nextfire := 0		; A timer for when we are next allowed to press the fire button
	global weapon_toggle_mode
	global arm_lock_toggle_mode
	global fire_on := 0
	
	; Only release toggle keys if we are not in program mode
	if (!ADHD.get_program_mode()){
		if (arm_lock_toggle_mode){
			Gosub, DisableArmLockToggle
		}
		if (weapon_toggle_mode){
			Gosub, DisableToggle
		}
	}
	
	; This gets called in Program Mode, so now would be a good time to re-initialize
	
	; Reset fire rate if on double rate
	if (fire_divider != 1){
		Gosub, ChangeFireRate
	}
	
	; Split FireSequence box from comma separated list to array
	;StringSplit, tmp, FireSequence, `,
	; Strip all spaces
	StringReplace, array_list, FireSequence, %A_SPACE%,, All
	StringLower, array_list, array_list
	array_list := RegExMatchGlobal(array_list, "(\w*\(\w*[,\w]*\)|[\w)]+)")
	;array_list := RegExMatchGlobal(array_list, "(\w*\(\w*,\w*\)|[\w)]+)")
	;array_list := RegExMatchGlobal(FireSequence, "\s*(\w*\(\s*\w*\s*,\s*\w*\s*\)|[\w)]+)\s*")
	array_ctr := 1
	Loop, % array_list.MaxIndex(){
		array_item := array_list[A_Index].Value(0)
		;msgbox % A_Index ": " array_item
		if (array_item != ""){
			if (array_item == "reset"){
				fire_array_reset_on_release := 1
			} else if (substr(array_item,1,7) == "stagger"){
				;remove brackets
				tmp := substr(array_item,8)
				tmp := substr(tmp,2,strlen(tmp)-2)
				; split by commas
				StringSplit, tmp, tmp, `,
				stagger_array[tmp1] := tmp2
			} else if(substr(array_item,1,9) == "groupmode"){
				;remove brackets
				tmp := substr(array_item,10)
				tmp := substr(tmp,2,strlen(tmp)-2)
				groupmode_array[1] := tmp
			} else {
				fire_array[array_ctr] := array_item
				array_ctr ++
			}
		}
	}
	return
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
	global ADHD
	; called at start, so do not run if ADHD is starting up
	if (!ADHD.starting_up){
		firectrl_init()
		Gosub, DisableTimers
	}
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
	; This is a key that may be held down, so we need to handle keyboard repeat.
	; If a keyboard key is held down - windows will repeat that character.
	if (fire_on == 0){
		fire_on := 1
	} else {
		return
	}
	
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

	return

; Fired on key up
FireUp:
	if (fire_on){
		; Send up event for held key
		tmp := groupmode_array[1]
		Send {%tmp% up}
	}
	fire_on := 0
	; Kill the timer when the key is released (Stop auto firing)
	SetFireTimer(0,false)
	if (fire_array_reset_on_release){
		current_weapon := 1
	}
	fire_array_count := 1
	return

; Set up HotKey 2

; Fired on key down
ChangeFireRate:
	; More Lazors!! Toggles double speed fire!
	; Toggle divider between 1 and 2
	fire_divider := 3 - fire_divider
	if (ScrollLockSetting == "Fire Rate"){
		if (fire_divider == 1){
			SetScrollLockState, Off
		} else {
			SetScrollLockState, On
		}
	}
	return

; Set up Hotkey 3
WeaponToggle:
	if (weapon_toggle_mode){
		Gosub, DisableToggle
	} else {
		Gosub, EnableToggle
	}
	return

ArmLockToggle:
	if (arm_lock_toggle_mode){
		Gosub, DisableArmLockToggle
	} else {
		Gosub, EnableArmLockToggle
	}
	return

JumpJetSpam:
	if (!jj_active){
		jj_active := 1
		SetTimer, do_jj, %JumpJetRate%
		Gosub, do_jj
	}
	return

JumpJetSpamUp:
	jj_active := 0
	SetTimer, do_jj, Off
	return

do_jj:
	Send {Space down}
	Sleep, 100
	Send {Space up}
	return

FireModeToggle:
	groupmode := 1-groupmode
	if (groupmode){
		if (fire_on){
			SetFireTimer(0,0)
			Gosub, DoFire
		}
	} else {
		if(fire_on){
			; Send up event for held key
			tmp := groupmode_array[1]
			Send {%tmp% up}
			Gosub, DoFire
		}
	}
	if (ScrollLockSetting == "Fire Mode"){
		if (groupmode){
			SetScrollLockState, On
		} else {
			SetScrollLockState, Off
		}
	}
	Return

; From http://www.autohotkey.com/board/topic/14817-grep-global-regular-expression-match/page-2#entry578137
RegExMatchGlobal(ByRef Haystack, NeedleRegEx) {
   Static Options := "U)^[imsxACDJOPSUX`a`n`r]+\)"
   NeedleRegEx := (RegExMatch(NeedleRegEx, Options, Opt) ? (InStr(Opt, "O", 1) ? "" : "O") : "O)") . NeedleRegEx
   Match := {Len: {0: 0}}, Matches := [], FoundPos := 1
   While (FoundPos := RegExMatch(Haystack, NeedleRegEx, Match, FoundPos + Match.Len[0]))
      Matches[A_Index] := Match
   Return Matches
}

; ===================================================================================================
; FOOTER SECTION

; KEEP THIS AT THE END!!
;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this
