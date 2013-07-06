ADHD - AHK Dynamic Hotkeys for Dummies
======================================

By Clive Galway - evilc@evilc.com
http://evilc.com/proj/adh

An AutoHotKey GUI library that allows authors to easily create AHK macros.
Provides functionality to allow the end-user to configure which button triggers a macro via a GUI.
Similar to binding a key to a function in a game's options.
Key bindings and other settings are stored in an INI file and are remembered between runs.


Features:
* Bind any key or mouse button (With optional Ctrl, Shift, Alt modifiers) to each macro
* Supports 7 mouse buttons (L,R,M,WheelUp/Down/Left/Right,Extra buttons 1+2) 
* Library to handle loading and saving of settings, with with default settings removed from INI
* Supports up and key down events for each trigger button
* Profile support
* Provides app detection (Limiting hotkeys to only work inside an app)
* Hooks to make sure that timers etc are stopped to help ensure app-specific hotkey functions stay app-specific
* Sample macro included
* Easy for someone with even a basic knowledge of AHK to write scripts with these features
* Built-in system to link to a URL for information on your macro

Obatining ADHD:
If you wish to write macros, you are advised to download the ZIP from my homepage: http://evilc.com/proj/adhd
The files on GitHub (https://github.com/evilC/ADHD-AHK-Dynamic-Hotkeys-for-Dummies) are likely to be bleeding-edge and may be broken

Installation:
1) Install Autohotkey
Then do one or both of the following:

2a) LIBRARY METHOD:
(Best used for scripts you run day to day)
Place the adhdlib.ahk file in your Autohotkey Lib folder
This is probably one of:
C:\Program Files\Autohotkey\Lib
C:\Program Files (x86)\Autohotkey\Lib
Place a client script (eg template.ahk or firectrl.ahk) anywhere on your hard disk
Make sure the end of the client script reads like this:
	;#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
	#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this

2b) LOCAL METHOD
(Best used for development and testing changes)
Place a client script (eg template.ahk or firectrl.ahk) anywhere on your hard disk
Place the adhlib.ahk file in the same folder as the client script
Make sure the end of the client script reads like this:
	#Include ADHDLib.ahk		; If you have the library in the same folder as your macro, use this
	;#Include <ADHDLib>			; If you have the library in the Lib folder (C:\Program Files\Autohotkey\Lib), use this

3) Double click the client script to run it

Demo / Sample Script: "Fire Control"
A stand-alone executable for this script can be found at:
Please see http://evilc.com/proj/firectrl 

Writing your own scripts using ADH:
Please examine the sample scripts (template.ahk or firectrl.ahk) for now

If editing with notepad++, you can get AHK syntax highlighting here: https://github.com/twiz-ahk/npp-ahk
Put the xml file in your notepad++ folder, restart then Language -> Autohotkey in np++

If trying to compile an ADHD script to exe, be sure to be running the x86 (32-bit) version of AHK.
x64 exes will not work on x86 windows, but x86 exes will work on x64 windows
An ADHD macro will warn you on startup if you have compiled an x64 exe
So if compiling to exe on x64 windows, just run the compiled exe, and if you do not get a warning, anyone should be able to run it


