; GoogleEarthHotkeys.ahk
; by David Tryse   davidtryse@gmail.com
; http://earth.tryse.net/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPLv2+
;
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; Creates a small GUI to modify hotkeys for showing/hiding layers within the Google Earth client
;
; Needs _libGoogleEarth.ahk library:  http://earth.tryse.net/


#NoEnv
#SingleInstance force
#include _libGoogleEarthCOM.ahk
version = 1.01
title = Google Earth Hotkeys %version%

; ---------------- handle command line parameters -------------------
IfEqual, 1, /start
{
	If not IsGErunning() {
		IsGEinit() ; start Google Earth application by calling any COM API function
	}
}

; -------- create right-click menu -------------
Menu, context, add, Always On Top, OnTop
Menu, context, add,
Menu, context, add, Check for updates, webHome
Menu, context, add, About, About

Menu, Tray, NoStandard
Menu, Tray, Tip, Google Earth Hotkeys
Menu, Tray, Click, 1 ; one click on tray icon to run default menu item (hideshow)
Menu, Tray, add, HideShow, HideShow
Menu, Tray, Default, HideShow	; make tray icon click hide/show window
Menu, Tray, add, About, About
Menu, Tray, add, Exit, ExitSub

; ---------------- make GUI -------------------
offset = 46
gap = 36
gap2 = 30
width=420
dropdown := "Borders and Labels|Borders|Labels|Photos|Roads|3D Buildings|Trees|Ocean|Weather|Gallery|Global Awareness|Geographic Features|Temporary Places|Everything|-Everything|---|Play Time Slider|Pause Time Slider|Toggle Sidebar|Toggle Toolbar|Toggle Sidebar+Toolbar|Edit Hotkeys"

Gui Add, Text, xm+0 yp+17, F1: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF1 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F1: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF1 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F2: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF2 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F2: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF2 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F3: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF3 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F3: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF3 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F4: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF4 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F4: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF4 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F5: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF5 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F5: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF5 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F6: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF6 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F6: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF6 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F7: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF7 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F7: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF7 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F8: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF8 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F8: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF8 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F9: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF9 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F9: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF9 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F10: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF10 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F10: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF10 gSubmit , %dropdown%

; Gui Add, Text, xm+0 yp+%gap%, F11: 
; Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF11 gSubmit , %dropdown%
; Gui Add, Text, xm+0 yp+%gap2%, shift F11: 
; Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF11 gSubmit , %dropdown%

Gui Add, Text, xm+0 yp+%gap%, F12: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vF12 gSubmit , %dropdown%
Gui Add, Text, xm+0 yp+%gap2%, shift F12: 
Gui Add, ComboBox, xm+%offset% yp-4 w%width% vSF12 gSubmit , %dropdown%

Gui Font,CGray
Gui Add, Text, xm+0 yp+%gap2%+5 gAbout, (hint; start a layer name with a minus sign to hide, separate multiple layers with the pipe | character)

RegRead, default_loaded, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys,default_loaded
if (default_loaded != 1)
	Gosub Default

Gosub Load
Gui, Show, Hide, %title%
return


Submit:
	Gui, Submit, nohide
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F1, %F1%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF1, %sF1%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F2, %F2%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF2, %sF2%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F3, %F3%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF3, %sF3%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F4, %F4%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF4, %sF4%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F5, %F5%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF5, %sF5%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F6, %F6%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF6, %sF6%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F7, %F7%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF7, %sF7%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F8, %F8%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF8, %sF8%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F9, %F9%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF9, %sF9%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F10, %F10%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF10, %sF10%
	; RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F11, %F11%
	; RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF11, %sF11%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F12, %F12%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF12, %sF12%
return

Load:
	RegRead, F1, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F1
	RegRead, sF1, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF1
	RegRead, F2, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F2
	RegRead, sF2, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF2
	RegRead, F3, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F3
	RegRead, sF3, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF3
	RegRead, F4, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F4
	RegRead, sF4, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF4
	RegRead, F5, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F5
	RegRead, sF5, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF5
	RegRead, F6, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F6
	RegRead, sF6, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF6
	RegRead, F7, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F7
	RegRead, sF7, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF7
	RegRead, F8, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F8
	RegRead, sF8, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF8
	RegRead, F9, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F9
	RegRead, sF9, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF9
	RegRead, F10, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F10
	RegRead, sF10, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF10
	; RegRead, F11, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F11
	; RegRead, sF11, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF11
	RegRead, F12, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F12
	RegRead, sF12, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF12
	GuiControl,Text, F1, %F1%
	GuiControl,Text, sF1, %sF1%
	GuiControl,Text, F2, %F2%
	GuiControl,Text, sF2, %sF2%
	GuiControl,Text, F3, %F3%
	GuiControl,Text, sF3, %sF3%
	GuiControl,Text, F4, %F4%
	GuiControl,Text, sF4, %sF4%
	GuiControl,Text, F5, %F5%
	GuiControl,Text, sF5, %sF5%
	GuiControl,Text, F6, %F6%
	GuiControl,Text, sF6, %sF6%
	GuiControl,Text, F7, %F7%
	GuiControl,Text, sF7, %sF7%
	GuiControl,Text, F8, %F8%
	GuiControl,Text, sF8, %sF8%
	GuiControl,Text, F9, %F9%
	GuiControl,Text, sF9, %sF9%
	GuiControl,Text, F10, %F10%
	GuiControl,Text, sF10, %sF10%
	; GuiControl,Text, F11, %F11%
	; GuiControl,Text, sF11, %sF11%
	GuiControl,Text, F12, %F12%
	GuiControl,Text, sF12, %sF12%
return

#IfWinActive ahk_class QWidget, LayerWidget			; === Google Earth ===
	F1::launchKey(A_ThisHotkey)
	+F1::launchKey(A_ThisHotkey)
	F2::launchKey(A_ThisHotkey)
	+F2::launchKey(A_ThisHotkey)
	F3::launchKey(A_ThisHotkey)
	+F3::launchKey(A_ThisHotkey)
	F4::launchKey(A_ThisHotkey)
	+F4::launchKey(A_ThisHotkey)
	F5::launchKey(A_ThisHotkey)
	+F5::launchKey(A_ThisHotkey)
	F6::launchKey(A_ThisHotkey)
	+F6::launchKey(A_ThisHotkey)
	F7::launchKey(A_ThisHotkey)
	+F7::launchKey(A_ThisHotkey)
	F8::launchKey(A_ThisHotkey)
	+F8::launchKey(A_ThisHotkey)
	F9::launchKey(A_ThisHotkey)
	+F9::launchKey(A_ThisHotkey)
	F10::launchKey(A_ThisHotkey)
	+F10::launchKey(A_ThisHotkey)
	; F11::launchKey(A_ThisHotkey)
	; +F11::launchKey(A_ThisHotkey)
	F12::launchKey(A_ThisHotkey)
	+F12::launchKey(A_ThisHotkey)
#IfWinActive
#+g::launchGE()	; win+shift+G - launch or activate Google Earth - global hotkey

launchGE() {
	If (IsGErunning()) {
		WinActivate ahk_class QWidget, LayerWidget
	} Else {
		IsGEinit() ; start Google Earth application by calling any COM API function
	}
}

launchKey(key) {
	key := RegexReplace(key,"\+","s")
	RegRead, action, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, %key%
	If (action = "") {
		Send {%key%}
	} else if (action = "Play Time Slider") {
		GEtimePlay()
	} else if (action = "Pause Time Slider") {
		GEtimePause()
	} else if (action = "Edit Hotkeys") {
		Gui, Show
	} else if (action = "Toggle Sidebar") {
		Send ^!b
	} else if (action = "Toggle Toolbar") {
		Send ^!t
	} else if (action = "Toggle Sidebar+Toolbar") {
		Send ^!b^!t
	} else {
		Loop, parse, action, |
		{
			Layer = %A_LoopField%
			If (SubStr(Layer,1,1) == "-") {
				Layer := SubStr(Layer,2)
				Hide(layer)
			} Else If (SubStr(Layer,1,1) == "+") {
				Layer := SubStr(Layer,2)
				Show(layer)
			} Else {
				Show(layer)
			}
		}
	}
}

Show(layer) {
	If (Layer == "Everything" or Layer == "everything" or Layer == "All" or Layer == "ALL" or Layer == "all") {
		GEfeature("Borders and Labels",1)
		GEfeature("Photos",1)
		GEfeature("Roads",1)
		GEfeature("3D Buildings",1)
		GEfeature("Ocean",1)
		GEfeature("Weather",1)
		GEfeature("Gallery",1)
		GEfeature("Global Awareness",1)
		GEfeature("More",1)
		GEfeature("Imagery",1)
		GEfeature("Terrain",1)
		GEfeature("Places",1)
		GEfeature("Panoramio Photos",1)
		GEfeature("Earth Pro (US)",1)
		GEfeature("Street View",1)
	} Else
		GEfeature(Layer,1)
}

Hide(layer) {
	If (Layer == "Everything" or Layer == "everything" or Layer == "All" or Layer == "ALL" or Layer == "all") {
		GEfeature("Primary Database",0)
		GEfeature("kh.google.com",0)
		GEfeature("Imagery",1)
		GEfeature("Terrain",1)
	} Else
		GEfeature(Layer,0)
}

Default:
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F1, 
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF1
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F2
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF2
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F3
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF3
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F4, Toggle Sidebar+Toolbar
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF4
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F5, Temporary Places
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF5, -Temporary Places|-My Places
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F6, Borders and Labels|3D Buildings
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF6, -Borders and Labels|-3D Buildings
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F7, -Everything
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF7
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F8, -Everything|Borders and Labels|Photos|Roads|3D Buildings|Ocean|Gallery|Global Awareness|More|-Spot Image|-DigitalGlobe Coverage|-US Government|Imagery|Terrain
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF8
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F9
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF9
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F10, Play Time Slider
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF10, Pause Time Slider
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, F12, Edit Hotkeys
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, sF12,
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthHotkeys, default_loaded, 1
return

GuiEscape:
HideShow:
	IfWinExist, %title%
	{
		Gosub Submit
		Gui, Show, Hide
	} Else {
		Gui, Show
	}
return

OnTop:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  Winset, AlwaysOnTop, Toggle, A
  OnTop := (OnTop - 1)**2	; toggle value 1/0
return

GuiContextMenu:
  Menu, context, Show
return

ExitSub:
ExitApp

; GuiClose:
; ExitApp

About:
  Gui 2:Destroy
  Gui 2:+Owner
  Gui 1:+Disabled
  Gui 2:Font,Bold
  Gui 2:Add,Text,x+0 yp+10, %title%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+16, by David Tryse
  Gui 2:Add,Text,xm yp+22, A small program for configuring hotkeys for Google Earth.
  Gui 2:Add,Text,xm yp+16, When configuring hotkeys, start a layer name with a minus sign to hide it.
  Gui 2:Add,Text,xm yp+16, Separate multiple layers to show or hide with the pipe | character.
  Gui 2:Add,Text,xm yp+16, Use the Win key + Shift + G global hotkey to launch Google Earth.
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, License: GPLv2+
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, Check for updates here:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gwebHome yp+15, http://earth.tryse.net
  Gui 2:Add,Text,xm gwebCode yp+15, http://googleearth-autohotkey.googlecode.com
  Gui 2:Font
  Gui 2:Add,Text,xm yp+24, For bug reports or suggestions email:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gEmaillink yp+15, davidtryse@gmail.com
  Gui 2:Font
  Gui 2:Add,Button,gAboutOk Default w90 h60 yp-44 xm+260,&OK
  Gui 2:Show,,About: Google Earth Hotkeys
  Gui 2:+LastFound
  WinSet AlwaysOnTop
Return

webHome:
  Run, http://earth.tryse.net#programs,,UseErrorLevel
Return

webCode:
  Run, http://googleearth-autohotkey.googlecode.com,,UseErrorLevel
Return

Emaillink:
  Run, mailto:davidtryse@gmail.com,,UseErrorLevel
Return

AboutOk:
2GuiClose:
2GuiEscape:
  Gui 1:-Disabled
  Gui 2:Destroy
return
