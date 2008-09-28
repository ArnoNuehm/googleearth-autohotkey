; GoogleEarthPosition.ahk
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPLv2+
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
; 
; Version history:
; 1.06   -   add crosshair KML option to menu (thanks http://freegeographytools.com/2008/easy-ways-to-get-latitudelongitude-for-a-screen-point-in-google-earth)
; 1.05   -   use new _libGoogleEarth.ahk library 1.15 (fix for localized OS)
; 1.04   -   * add option to disable reading altitude (sometimes slows down the Google Earth client) *
; 1.03   -   * add six mini-bookmarks * add tooltips *
; 1.02   -   * read Terrain Altitude * add drop-down list for AltitudeMode * DMS coord in statusbar * keyboard shortcuts * fix edit-box text-select in auto-mode * round values option (right-click menu) *

#NoEnv
#SingleInstance off
#NoTrayIcon 
#include _libGoogleEarth.ahk
version = 1.06

Speed := 1.0
OnTop := 1
RoundVal := 1
ReadAlt := 0

; -------- create right-click menu -------------
Menu, context, add, Always On Top, OnTop
Menu, context, add, Round values, RoundVal
Menu, context, add, Read Altitude, ReadAlt
Menu, context, add,
Menu, context, add, Show Crosshair, Crosshair
Menu, context, add,
Menu, context, add, About, About
If OnTop
	Menu, context, Check, Always On Top
If RoundVal
	Menu, context, Check, Round values
If ReadAlt
	Menu, context, Check, Read Altitude

; ----------- create GUI ----------------
Gui, Add, Text, x10, FocusPointLatitude:
Gui, Add, Edit, yp x140 w150 vFocusPointLatitude,
Gui, Add, Text, x10, FocusPointLongitude:
Gui, Add, Edit, yp x140 w150 vFocusPointLongitude,
Gui, Add, Text, x10, FocusPointAltitude:
Gui, Add, Edit, yp x140 w150 vFocusPointAltitude,
Gui, Add, Text, x10, FocusPointAltitudeMode:
Gui, Add, DropDownList, yp x140 w150 AltSubmit Choose1 vFocusPointAltitudeMode, Relative To Ground|Absolute
Gui, Add, Text, x10, Range:
Gui, Add, Edit, yp x140 w150 vRange,
Gui, Add, Text, x10, Tilt:
Gui, Add, Edit, yp x140 w150 vTilt,
Gui, Add, Text, x10, Azimuth:
Gui, Add, Edit, yp x140 w150 vAzimuth,
Gui, Add, Text, x10, Terrain Altitude:
Gui, Add, Edit, yp x140 w150 vAltitude ReadOnly,

Gui, Add, Button, x10 w70 gGetPos vGetPos, &GetPos
Gui, Add, Checkbox, yp h24 x85 vAutoLoad Checked, Au&to
AutoLoad_TT := "Uncheck this box to edit coordinates and fly Google Earth to a new location."
Gui, Add, Button, yp x140 w70 default gFlyTo vFlyTo, &FlyTo
Gui, Add, Text, yp+3 x227, speed:
Gui, Add, Edit, yp-3 x263 w27 vSpeed, %Speed%
Gui, Add, Button, x10 w120 gCopy_LatLong vCopy_LatLong, &Copy LatLong
Gui, Add, Button, yp x140 w120 gCopy_LookAt vCopy_LookAt, Copy Look&At
Gui, Add, Button, x10 w120 gCopy_LatLong_KML vCopy_LatLong_KML, Copy LatLong K&ML
Gui, Add, Button, yp x140 w120 gCopy_LookAt_KML vCopy_LookAt_KML, Copy LookAt KM&L
Gui Add, Button, yp x0 hidden greload, reloa&d

Gui, Add, Button, yp+35 x10 w40 h20 gSavePos vSavedPos1, 1
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos2, 2
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos3, 3
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos4, 4
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos5, 5
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos6, 6
SavedPos1_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."
SavedPos2_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."
SavedPos3_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."
SavedPos4_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."
SavedPos5_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."
SavedPos6_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Alt and click to load a saved position without flying to it."

;Gui, Add, Text, x10, DMS Coordinates:
;Gui, Add, Edit, x10 w100 ReadOnly, %A_Space%DMS Coordinates:
;Gui, Add, Edit, yp x110 w180 vDMSCoord ReadOnly,

Gui Add, StatusBar, vStatusBar
SB_SetText("  Google Earth is not running ")


Gui, Show,, Google Earth Position %version%
Gui +LastFound
WinSet AlwaysOnTop
OnMessage(0x200, "WM_MOUSEMOVE")

Loop {
  Gui, Submit, NoHide
  If (AutoLoad = "1")
	Gosub GetPos
  If (AutoLoad != PrevAutoLoad)  {
	  If (AutoLoad = "1") 
	  {
		  GuiControl, +ReadOnly, FocusPointLatitude,
		  GuiControl, +ReadOnly, FocusPointLongitude,
		  GuiControl, +ReadOnly, FocusPointAltitude,
		  GuiControl, +Disabled, FocusPointAltitudeMode,
		  GuiControl, +ReadOnly, Range,
		  GuiControl, +ReadOnly, Tilt,
		  GuiControl, +ReadOnly, Azimuth,
		  GuiControl, +ReadOnly, Speed,
		  If ReadAlt
			GuiControl, -Disabled, Altitude,
		  Else
			GuiControl, +Disabled, Altitude,
		  GuiControl, +Disabled, FlyTo,
		  GuiControl, +Disabled, GetPos,
	  } else {
		  GuiControl, -ReadOnly, FocusPointLatitude,
		  GuiControl, -ReadOnly, FocusPointLongitude,
		  GuiControl, -ReadOnly, FocusPointAltitude,
		  GuiControl, -Disabled, FocusPointAltitudeMode,
		  GuiControl, -ReadOnly, Range,
		  GuiControl, -ReadOnly, Tilt,
		  GuiControl, -ReadOnly, Azimuth,
		  GuiControl, -ReadOnly, Speed,
		  GuiControl, +Disabled, Altitude,
		  GuiControl, -Disabled, FlyTo,
		  GuiControl, -Disabled, GetPos,
	  }
  }
  PrevAutoLoad := AutoLoad
  Sleep 200
}

GetPos:
  If not IsGErunning()
	return
  oldFocusPointLatitude := FocusPointLatitude
  oldFocusPointLongitude := FocusPointLongitude
  oldFocusPointAltitude := FocusPointAltitude
  oldFocusPointAltitudeMode := FocusPointAltitudeMode
  oldRange := Range
  oldTilt := Tilt
  oldAzimuth := Azimuth
  oldPointAltitude := PointAltitude
  oldDMSCoord := DMSCoord
  GetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, Range, Tilt, Azimuth)
  If (ReadAlt)
	GetGEpoint(PointLatitude, PointLongitude, PointAltitude)
  else
	PointAltitude :=
  If (RoundVal) {
	FocusPointLatitude := Round(FocusPointLatitude,6)
	FocusPointLongitude := Round(FocusPointLongitude,6)
	;FocusPointAltitude := Round(FocusPointAltitude,2)
	Range := Round(Range,2)
	Tilt := Round(Tilt,2)
	Azimuth := Round(Azimuth,2)
	PointAltitude := Round(PointAltitude,2)
  }
  DMSCoord := Dec2Deg(FocusPointLatitude "," FocusPointLongitude)
  If (FocusPointLatitude != oldFocusPointLatitude)
	GuiControl,, FocusPointLatitude, %FocusPointLatitude%
  If (FocusPointLongitude != oldFocusPointLongitude)
	GuiControl,, FocusPointLongitude, %FocusPointLongitude%
  If (FocusPointAltitude != oldFocusPointAltitude)
	GuiControl,, FocusPointAltitude, %FocusPointAltitude%
  If (FocusPointAltitudeMode != oldFocusPointAltitudeMode)
	GuiControl, Choose, FocusPointAltitudeMode, %FocusPointAltitudeMode%
  If (Range != oldRange)
	GuiControl,, Range, %Range%
  If (Tilt != oldTilt)
	GuiControl,, Tilt, %Tilt%
  If (Azimuth != oldAzimuth)
	GuiControl,, Azimuth, %Azimuth%
  If (PointAltitude != oldPointAltitude)
	GuiControl,, Altitude, %PointAltitude%
  If (DMSCoord != oldDMSCoord)
	SB_SetText("   DMS Coordinates:   " DMSCoord)
	;GuiControl,, DMSCoord, %DMSCoord%
  GuiControl,, Speed, %Speed%
return

FlyTo:
  SetGEpos(FocusPointLatitude,FocusPointLongitude,FocusPointAltitude,FocusPointAltitudeMode,Range,Tilt,Azimuth,Speed)
return

Copy_LatLong:
  clipboard = %FocusPointLatitude%`t%FocusPointLongitude%
return

Copy_LookAt:
  clipboard = %FocusPointLatitude%`t%FocusPointLongitude%`t%FocusPointAltitude%`t%Range%`t%Tilt%`t%Azimuth%
return

Copy_LatLong_KML:
  clipboard = <coordinates>%FocusPointLongitude%,%FocusPointLatitude%,0</coordinates>
return

Copy_LookAt_KML:
  clipboard = <LookAt>`n`t<longitude>%FocusPointLongitude%</longitude>`n`t<latitude>%FocusPointLatitude%</latitude>`n`t<altitude>%FocusPointAltitude%</altitude>`n`t<range>%Range%</range>`n`t<tilt>%Tilt%</tilt>`n`t<heading>%Azimuth%</heading>`n</LookAt>
return

SavePos:
  GetKeyState, shiftstate, Shift
  GetKeyState, altstate, Alt
  If (shiftstate = "D" and altstate = "U") {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLatitude, %FocusPointLatitude%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLongitude, %FocusPointLongitude%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitude, %FocusPointAltitude%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitudeMode, %FocusPointAltitudeMode%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Range, %Range%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Tilt, %Tilt%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Azimuth, %Azimuth%
	SB_SetText("  Saved coordinates. ")
  } else if (shiftstate = "U") {
	RegRead, FocusPointLatitude, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLatitude
	If !(FocusPointLatitude) {
		SB_SetText(" No previously saved coordinates. Use Shift and click to save. ")
		return
	}	
	RegRead, FocusPointLongitude, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLongitude
	RegRead, FocusPointAltitude, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitude
	RegRead, FocusPointAltitudeMode, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitudeMode
	RegRead, Range, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Range
	RegRead, Tilt, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Tilt
	RegRead, Azimuth, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Azimuth
	If (altstate = "U")
		Gosub, FlyTo
	If (altstate = "D") {
		GuiControl,, AutoLoad, 0
		GuiControl,, FocusPointLatitude, %FocusPointLatitude%
		GuiControl,, FocusPointLongitude, %FocusPointLongitude%
		GuiControl,, FocusPointAltitude, %FocusPointAltitude%
		GuiControl, Choose, FocusPointAltitudeMode, %FocusPointAltitudeMode%
		GuiControl,, Range, %Range%
		GuiControl,, Tilt, %Tilt%
		GuiControl,, Azimuth, %Azimuth%
		GuiControl,, Altitude, %PointAltitude%
		SB_SetText("   DMS Coordinates:   " DMSCoord)
	}
  }
return


WM_MOUSEMOVE()
{
    static CurrControl, PrevControl, _TT  ; _TT is kept blank for use by the ToolTip command below.
    CurrControl := A_GuiControl
    If (CurrControl <> PrevControl and not InStr(CurrControl, " "))
    {
        ToolTip  ; Turn off any previous tooltip.
        SetTimer, DisplayToolTip, 1000
        PrevControl := CurrControl
    }
    return

    DisplayToolTip:
    SetTimer, DisplayToolTip, Off
    If !(RegExReplace(CurrControl,"[a-zA-Z0-9_]"))	; check to only do next line if CurrControl is a well formed variable name, to avoid errors.
	ToolTip % %CurrControl%_TT  ; The leading percent sign tell it to use an expression.
    SetTimer, RemoveToolTip, 5000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

reload:
  Reload
return

OnTop:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  Winset, AlwaysOnTop, Toggle, A
return

Crosshair:
  RegRead GoogleEarthPath, HKEY_LOCAL_MACHINE, SOFTWARE\Google\Google Earth Plus, InstallDir
  IfExist, %GoogleEarthPath%\res\shapes\cross-hairs_highlight.png
	CrosshairImage = %GoogleEarthPath%\res\shapes\cross-hairs_highlight.png
  Else
	CrosshairImage = %A_ProgramFiles%\Google\Google Earth\res\shapes\cross-hairs_highlight.png
  CrosshairKml =
  (
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://earth.google.com/kml/2.2">
<ScreenOverlay>
	<name>crosshair</name>
	<Icon>
		<href>%CrosshairImage%</href>
	</Icon>
	<overlayXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
	<screenXY x="0.5" y="0.5" xunits="fraction" yunits="fraction"/>
	<size x="32" y="32" xunits="pixels" yunits="pixels"/>
</ScreenOverlay>
</kml>
  )
  FileDelete, %A_Temp%\crosshair.kml
  FileAppend, %CrosshairKml%, %A_Temp%\crosshair.kml
  Run, %A_Temp%\crosshair.kml
return

RoundVal:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  RoundVal := (RoundVal - 1)**2	; toggle value 1/0
return

ReadAlt:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  ReadAlt := (ReadAlt - 1)**2	; toggle value 1/0
  If ReadAlt
	GuiControl, -Disabled, Altitude,
  Else
	GuiControl, +Disabled, Altitude,
return

GuiContextMenu:
  Menu, context, Show
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
  Gui 2:Add,Text,xm yp+18, License: GPLv2+
  Gui 2:Add,Text,xm yp+36, The copy functions are intended to be useful when editing KML
  Gui 2:Add,Text,xm yp+15, using Google's SpreadSheet Mapper:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gMapperlink yp+15, http://earth.google.com/outreach/tutorial_mapper.html
  Gui 2:Font
  Gui 2:Add,Text,xm yp+32, Check for updates here:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gWeblink yp+15, http://david.tryse.net/googleearth/
  Gui 2:Add,Text,xm gWeblink2 yp+15, http://googleearth-autohotkey.googlecode.com
  Gui 2:Font
  Gui 2:Add,Text,xm yp+24, For bug reports or suggestions email:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gEmaillink yp+15, davidtryse@gmail.com
  Gui 2:Font
  Gui 2:Add,Button,gAboutOk Default w80 h80 yp-60 x245,&OK
  Gui 2:Show,,About: Google Earth Position
  Gui 2:+LastFound
  WinSet AlwaysOnTop
Return

Weblink:
  Run, http://david.tryse.net/googleearth/,,UseErrorLevel
Return

Weblink2:
  Run, http://googleearth-autohotkey.googlecode.com,,UseErrorLevel
Return

Mapperlink:
  Run, http://earth.google.com/outreach/tutorial_mapper.html,,UseErrorLevel
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
