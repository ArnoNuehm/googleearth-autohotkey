; GoogleEarthPosition.ahk  version 1.01
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; License:  GPL 2+
; 
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; Creates a small GUI for reading the current coordinates from the Google Earth client
; * can also edit coordinates to make Google Earth fly to a new location
; * can copy coordinates to the clipboard, either in KML format or tab separated
;   (tab separated = for use with Google's SpreadSheet Mapper: http://earth.google.com/outreach/tutorial_mapper.html )
; 
; Needs _libGoogleEarth.ahk library:  http://david.tryse.net/googleearth/
; Needs ws4ahk.ahk library:  http://www.autohotkey.net/~easycom/
; 
; The script uses the Google Earth COM API  ( http://earth.google.com/comapi/ )

#NoEnv
#SingleInstance off
#NoTrayIcon 
#include _libGoogleEarth.ahk
version = 1.01

;Menu, tray, add
;Menu, tray, add, Window On Top, OnTop
;Menu, tray, Check, Window On Top

Menu, contex, add, Window On Top, OnTop
Menu, contex, Check, Window On Top
Menu, contex, add, About, About

Gui, Add, Text, x10, FocusPointLatitude:
Gui, Add, Edit, yp x140 w150 vFocusPointLatitude,
Gui, Add, Text, x10, FocusPointLongitude:
Gui, Add, Edit, yp x140 w150 vFocusPointLongitude,
Gui, Add, Text, x10, FocusPointAltitude:
Gui, Add, Edit, yp x140 w150 vFocusPointAltitude,
Gui, Add, Text, x10, FocusPointAltitudeMode:
Gui, Add, Edit, yp x140 w150 vFocusPointAltitudeMode,
Gui, Add, Text, x10, Range:
Gui, Add, Edit, yp x140 w150 vRange,
Gui, Add, Text, x10, Tilt:
Gui, Add, Edit, yp x140 w150 vTilt,
Gui, Add, Text, x10, Azimuth:
Gui, Add, Edit, yp x140 w150 vAzimuth,
Gui, Add, Button, x10 w70, GetPos
Gui, Add, Checkbox, yp x85 vAutoLoad Checked,(auto)
Gui, Add, Button, yp x140 w70 default, FlyTo
Gui, Add, Text, yp x227, speed:
Gui, Add, Edit, yp x263 w27 vSpeed,
;Gui, Add, Text, x10, CSV:
Gui, Add, Button, x10 w120 ,Copy_LatLong
Gui, Add, Button, yp x140 w120 ,Copy_LookAt
;Gui, Add, Text, x10, KML:
Gui, Add, Button, x10 w120 ,Copy_LatLong_KML
Gui, Add, Button, yp x140 w120 ,Copy_LookAt_KML
Gui, Show,, Google Earth Position %version%
Gui +LastFound
WinSet AlwaysOnTop
Speed := 1.0
Gosub ButtonGetPos

Loop {
  Gui, Submit, NoHide
  If (AutoLoad = "1")
	Gosub ButtonGetPos
  If (AutoLoad != PrevAutoLoad)  {
	  If (AutoLoad = "1") 
	  {
		  GuiControl, +ReadOnly, FocusPointLatitude,
		  GuiControl, +ReadOnly, FocusPointLongitude,
		  GuiControl, +ReadOnly, FocusPointAltitude,
		  GuiControl, +ReadOnly, FocusPointAltitudeMode,
		  GuiControl, +ReadOnly, Range,
		  GuiControl, +ReadOnly, Tilt,
		  GuiControl, +ReadOnly, Azimuth,
		  GuiControl, +ReadOnly, Speed,
	  } else {
		  GuiControl, -ReadOnly, FocusPointLatitude,
		  GuiControl, -ReadOnly, FocusPointLongitude,
		  GuiControl, -ReadOnly, FocusPointAltitude,
		  GuiControl, -ReadOnly, FocusPointAltitudeMode,
		  GuiControl, -ReadOnly, Range,
		  GuiControl, -ReadOnly, Tilt,
		  GuiControl, -ReadOnly, Azimuth,
		  GuiControl, -ReadOnly, Speed,
	  }
  }
  PrevAutoLoad := AutoLoad
  Sleep 100
}

ButtonGetPos:
  If not IsGErunning()
	return
  GetGEpos(FocusPointLatitude,FocusPointLongitude,FocusPointAltitude,FocusPointAltitudeMode,Range,Tilt,Azimuth)
  GuiControl,, FocusPointLatitude, %FocusPointLatitude%
  GuiControl,, FocusPointLongitude, %FocusPointLongitude%
  GuiControl,, FocusPointAltitude, %FocusPointAltitude%
  GuiControl,, FocusPointAltitudeMode, %FocusPointAltitudeMode%
  GuiControl,, Range, %Range%
  GuiControl,, Tilt, %Tilt%
  GuiControl,, Azimuth, %Azimuth%
  GuiControl,, Speed, %Speed%
return

ButtonFlyTo:
  SetGEpos(FocusPointLatitude,FocusPointLongitude,FocusPointAltitude,FocusPointAltitudeMode,Range,Tilt,Azimuth,Speed)
return

ButtonCopy_LatLong:
  clipboard = %FocusPointLatitude%`t%FocusPointLongitude%
return

ButtonCopy_LookAt:
  clipboard = %FocusPointLatitude%`t%FocusPointLongitude%`t%FocusPointAltitude%`t%Range%`t%Tilt%`t%Azimuth%
return

ButtonCopy_LatLong_KML:
  clipboard = <coordinates>%FocusPointLongitude%,%FocusPointLatitude%,0</coordinates>
return

ButtonCopy_LookAt_KML:
  clipboard = <LookAt>`n`t<longitude>%FocusPointLongitude%</longitude>`n`t<latitude>%FocusPointLatitude%</latitude>`n`t<altitude>%FocusPointAltitude%</altitude>`n`t<range>%Range%</range>`n`t<tilt>%Tilt%</tilt>`n`t<heading>%Azimuth%</heading>`n</LookAt>
return

ButtonCopy_LatLongIni:
  clipboard = lat = %FocusPointLatitude%`nlong = %FocusPointLongitude%
return

OnTop:
  ;Menu, tray, ToggleCheck, %A_ThisMenuItem%
  Menu, contex, ToggleCheck, %A_ThisMenuItem%
  Winset, AlwaysOnTop, Toggle, A
return

GuiContextMenu:
  Menu, contex, Show
return

GuiClose:
  WS_Uninitialize()
ExitApp

About:
  Gui 2:Destroy
  Gui 2:+Owner
  Gui 1:+Disabled
  Gui 2:Font,Bold
  Gui 2:Add,Text,x+0 yp+10, Google Earth Position %version%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, A tiny program for reading coordinates from the Google Earth client
  Gui 2:Add,Text,xm yp+15, (or edit coordinates to make Google Earth fly to a new location).
  Gui 2:Add,Text,xm yp+18, License: GPL
  Gui 2:Add,Text,xm yp+36, The copy functions might be useful when editing KML with
  Gui 2:Add,Text,xm yp+15, Google's SpreadSheet Mapper:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gMapperlink yp+15, http://earth.google.com/outreach/tutorial_mapper.html
  Gui 2:Font
  Gui 2:Add,Text,xm yp+36, Check for updates here:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gWeblink yp+15, http://david.tryse.net/googleearth/
  Gui 2:Font
  Gui 2:Add,Text,xm yp+20, For bug reports or suggestions email:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gEmaillink yp+15, davidtryse@gmail.com
  Gui 2:Font
  Gui 2:Add,Button,gAboutOk Default w80 h80 yp-50 x230,&OK
  Gui 2:Show,,About: Google Earth Position
  Gui 2:+LastFound
  WinSet AlwaysOnTop
Return

AboutOk:
  Gui 1:-Disabled
  Gui 2:Destroy
return

Weblink:
Run, http://david.tryse.net/googleearth/,,UseErrorLevel
Return

Mapperlink:
Run, http://earth.google.com/outreach/tutorial_mapper.html,,UseErrorLevel
Return

Emaillink:
Run, mailto:davidtryse@gmail.com,,UseErrorLevel
Return

2GuiClose:
Gui 1:-Disabled
Gui 2:Destroy
return
