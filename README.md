AHK-Dynamic-Hotkeys
=====================

An AutoHotKey GUI script template that allows you to easily create AHK macros.
Provides functionality to allow the user to configure which button triggers a macro via a GUI.
Similar to binding a key to a function in a game's options.
Key bindings and other settings are stored in an INI file and are remembered between runs.


Features:
* Bind any single key or any single mouse button to each macro
* Supports 7 mouse buttons (L,R,M,WheelUp/Down/Left/Right,Extra buttons 1+2) 
* Library to handle loading and saving of settings, with with default settings removed from INI
* Supports up and key down events for each trigger button

Usage:
; To add an extra hotkey, duplicate the lines between the vvv and ^^^ blocks
; vvvvvvvvv
; Like this
; ^^^^^^^^^
; These blocks should come in pairs - one for each hotkey
; And replace old name (eg HotKeyOne) with a new name - eg HotKeyThree
