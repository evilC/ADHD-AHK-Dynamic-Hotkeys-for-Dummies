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

Installation:
1) Install Autohotkey
2) Place the adhdlib.ahk file in your Autohotkey Lib folder
This is probably one of:
C:\Program Files\Autohotkey\Lib
C:\Program Files (x86)\Autohotkey\Lib
3) Place a client script (eg template.ahk or firectrl.ahk) anywhere on your hard disk
4) Double click the client script to run it

Demo / Sample Script: "Fire Control"
Please see http://evilc.com/proj/firectrl 

Writing your own scripts using ADH:
Please examine the sample scripts (template.ahk or firectrl.ahk) for now
