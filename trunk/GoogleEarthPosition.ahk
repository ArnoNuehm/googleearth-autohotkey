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
; 1.17   -   better status bar messages, alt-1-6 hotkeys, click-window-to-drag
; 1.16   -   no code changes, fix icon, remove need for MSVCR71.dll
; 1.15   -   add copy <gx:FlyTo> option, copy DMS coord option
; 1.14   -   add new-version-check
; 1.13   -   Couple fixes for GE 5.1 (GetCamera returns FocusPointAltitudeMode = 5 which SetCameraParams doesn't take, crosshair path), Copy-LookAt shift to copy as php code
; 1.12   -   Feet/Meters option for Altitude/Range (default picked from GE), "/start" parameter to start the Google Earth application (thanks Alan Stewart for both), more tooltips
; 1.11   -   remember always-on-top
; 1.10   -   remember window position
; 1.09   -   use new _libGoogleEarth.ahk library 1.18 (fix for Google Earth Pro)
; 1.08   -   hold down shift to copy comma separated
; 1.07   -   smaller crosshair in GE 4.3
; 1.06   -   add crosshair KML option to menu (thanks http://freegeographytools.com/2008/easy-ways-to-get-latitudelongitude-for-a-screen-point-in-google-earth)
; 1.05   -   use new _libGoogleEarth.ahk library 1.15 (fix for localized OS)
; 1.04   -   * add option to disable reading altitude (sometimes slows down the Google Earth client) *
; 1.03   -   * add six mini-bookmarks * add tooltips *
; 1.02   -   * read Terrain Altitude * add drop-down list for AltitudeMode * DMS coord in statusbar * keyboard shortcuts * fix edit-box text-select in auto-mode * round values option (right-click menu) *

#NoEnv
#SingleInstance off
#NoTrayIcon 
#Include %A_ScriptDir%
#include _libGoogleEarthCOM.ahk
version = 1.17

IfEqual, 1, /start
{
	If not IsGErunning() {
		IsGEinit() ; start Google Earth application by calling any COM API function
	}
}

RegRead OnTop, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition, OnTop
IfEqual, OnTop,
	OnTop := 1
Speed := 1.0
RoundVal := 1
ReadAlt := 0

; -------- create right-click menu -------------
Menu, unit, add, Feet, UnitFeet
Menu, unit, add, Meters, UnitMeter
Menu, context, add, Always On Top, OnTop
Menu, context, add, Round values, RoundVal
Menu, context, add, Read Altitude, ReadAlt
Menu, context, add, Alt/Range Unit, :unit
Menu, context, add,
Menu, context, add, Show Crosshair, Crosshair
Menu, context, add,
Menu, context, add, Check for updates, webHome
Menu, context, add, About, About
If OnTop
	Menu, context, Check, Always On Top
If RoundVal
	Menu, context, Check, Round values
If ReadAlt
	Menu, context, Check, Read Altitude

RegRead UnitIsFeet, HKEY_CURRENT_USER, Software\Google\Google Earth Plus\Render, FeetMiles
IfEqual, UnitIsFeet, true
	Gosub UnitFeet
Else
	Gosub UnitMeter

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
Gui, Add, Text, x10, Heading:
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
; Gui Add, Button, yp x0 hidden greload, reloa&d

Gui, Add, Button, yp+35 x10 w40 h20 gSavePos vSavedPos1, &1
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos2, &2
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos3, &3
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos4, &4
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos5, &5
Gui, Add, Button, yp xp+48 w40 h20 gSavePos vSavedPos6, &6
SavedPos1_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
SavedPos2_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
SavedPos3_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
SavedPos4_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
SavedPos5_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
SavedPos6_TT := "Click to load a previously saved position.`nPress Shift and click to save the current position.`nPress Ctrl and click to load a saved position without flying to it."
Copy_LatLong_TT := "Copy Latitude and Longitude to the clipboard (separated by a tab) `n(hold down Shift to copy separated by a comma)"
Copy_LatLong_KML_TT := "Copy Latitude and Longitude to the clipboard in KML format "
Copy_LookAt_TT := "Copy LookAt parameters (current viewpoint) to the clipboard (tab separated) `n(hold down Shift to copy comma separated)"
Copy_LookAt_KML_TT := "Copy LookAt parameters (current viewpoint) to the clipboard in KML format `n(hold down Shift to copy as a <gx:FlyTo> tag, for tours)"
;Altitude_TT := "The terrain altitude of the current focus point, in meters/feet (change unit in right-click menu).`nEnabling the option to Read Altitude (in the right-click menu) may slow down Google Earth."
Azimuth_TT := "Rotation of the current view, in degrees (between -180 and 180)"
Tilt_TT := "Tilt of the current view, in degrees (between 0 and 90)"
;Range_TT := "Viewpoint distance from focus point, in meters/feet (change unit in right-click menu)"
FocusPointAltitudeMode_TT := "Reference origin for the focus point altitude."
;FocusPointAltitude_TT := "Altitude of the focus point, in meters/feet (always 0 when querying current position from Google Earth)"
FocusPointLatitude_TT := "Coordinated of the current focus point (screen center)"
FocusPointLongitude_TT := "Coordinated of the current focus point (screen center)"
GetPos_TT := "Read current coordinates and viewpoint information from Google Earth (check Auto to update constantly)"
FlyTo_TT := "Fly Google Earth to the coordinates and viewpoint entered above"
Speed_TT := "How fast Google Earth should fly to a new position"

Gui Add, StatusBar, vStatusBar gStatusBar
SB_SetText("  Google Earth is not running ")
StatusBar_TT := ""

WinPos := GetSavedWinPos("GoogleEarthPosition")
Gui, Show, %WinPos%, Google Earth Position %version%
Gui +LastFound
If OnTop
	WinSet AlwaysOnTop
OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x201, "WM_LBUTTONDOWN")

WM_LBUTTONDOWN(wParam, lParam) {
	PostMessage, 0xA1, 2		; move window
    ; X := lParam & 0xFFFF
    ; Y := lParam >> 16
	; SB_SetText(A_GuiControl " " X " " Y)
    ; if !A_GuiControl
		; SB_SetText("xxx" A_GuiControl " " X " " Y)
}

Loop {
  Gui, Submit, NoHide
  FocusPointAltitudeM := FocusPointAltitude / UnitFactor
  RangeM := Range / UnitFactor
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
  {
	if (StatusBar_TT)
		SB_SetText("  Google Earth is not running ")
	StatusBar_TT := ""
	return
  }
  oldFocusPointLatitude := FocusPointLatitude
  oldFocusPointLongitude := FocusPointLongitude
  oldFocusPointAltitude := FocusPointAltitude
  oldFocusPointAltitudeMode := FocusPointAltitudeMode
  oldRange := Range
  oldTilt := Tilt
  oldAzimuth := Azimuth
  oldPointAltitude := PointAltitude
  oldDMSCoord := DMSCoord
  GetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitudeM, FocusPointAltitudeMode, RangeM, Tilt, Azimuth)
  If (FocusPointAltitudeMode != 2)	; ... GetCamera seems to have started returning 5 in newer builds...but SetCameraParams doesn't seem to take this value..workaround by settings everything to 1 or 2
	FocusPointAltitudeMode := 1
  FocusPointAltitude := FocusPointAltitudeM * UnitFactor
  Range := RangeM * UnitFactor
  If (ReadAlt) {
	GetGEpoint(PointLatitude, PointLongitude, PointAltitudeM)
	PointAltitude := PointAltitudeM * UnitFactor
  }
  else
	PointAltitude :=
  If (RoundVal) {
	FocusPointLatitude := Round(FocusPointLatitude,6)
	FocusPointLongitude := Round(FocusPointLongitude,6)
	;FocusPointAltitude := Round(FocusPointAltitude,2)
	Range := Round(Range,2)
	RangeM := Round(RangeM,2)
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
  If (DMSCoord != oldDMSCoord and !freezeSB) {
	SB_SetText("   DMS Coordinates:   " DMSCoord)
	StatusBar_TT := "Double-click to copy the DMS coordinates"
  }
  GuiControl,, Speed, %Speed%
return

FlyTo:
  SetGEpos(FocusPointLatitude,FocusPointLongitude,FocusPointAltitudeM,FocusPointAltitudeMode,RangeM,Tilt,Azimuth,Speed)
return

Copy_LatLong:
  GetKeyState, shiftstate, Shift
  If (shiftstate = "D") {
	clipboard = %FocusPointLatitude%, %FocusPointLongitude%
	SB_SetTextTime("  Coordinates copied (csv). ")
  } else {
  	clipboard = %FocusPointLatitude%`t%FocusPointLongitude%
	SB_SetTextTime("  Coordinates copied (tab). ")
  }
return

Copy_LookAt:
  GetKeyState, shiftstate, Shift
  If (shiftstate = "D") {
	clipboard = %FocusPointLatitude%, %FocusPointLongitude%, %FocusPointAltitudeM%, %RangeM%, %Tilt%, %Azimuth%
	SB_SetTextTime("  LookAt parameters copied (csv). ")
  } else {
	clipboard = %FocusPointLatitude%`t%FocusPointLongitude%`t%FocusPointAltitudeM%`t%RangeM%`t%Tilt%`t%Azimuth%
	SB_SetTextTime("  LookAt parameters copied (tab). ")
  }
return

Copy_LatLong_KML:
	clipboard = <coordinates>%FocusPointLongitude%,%FocusPointLatitude%,0</coordinates>
	SB_SetTextTime("  KML coordinates copied. ")
return

Copy_LookAt_KML:
  GetKeyState, altstate, Alt
  GetKeyState, shiftstate, Shift
  If (altstate = "D") {
	clipboard = flyTo(%FocusPointLatitude%, %FocusPointLongitude%, %RangeM%, %Tilt%, %Azimuth%, "bounce", 2);`n
	SB_SetTextTime("  flyTo() code copied. ")
  } Else If (shiftstate = "D") {
	clipboard := "`t<gx:FlyTo>`n`t`t<gx:duration>5</gx:duration>`n`t`t<gx:flyToMode>bounce</gx:flyToMode>`n`t`t<LookAt>`n`t`t`t<longitude>" . FocusPointLongitude . "</longitude>`n`t`t`t<latitude>" . FocusPointLatitude . "</latitude>`n`t`t`t<altitude>" . FocusPointAltitudeM . "</altitude>`n`t`t`t<range>" . RangeM . "</range>`n`t`t`t<tilt>" . Tilt . "</tilt>`n`t`t`t<heading>" . Azimuth . "</heading>`n`t`t</LookAt>`n`t</gx:FlyTo>`n"
	; clipboard = $kml .= flyTo(%FocusPointLatitude%, %FocusPointLongitude%, %RangeM%, %Tilt%, %Azimuth%, "bounce", 2);`n
	SB_SetTextTime("  KML gx:FlyTo code copied. ")
  } Else {
	clipboard := "`t<LookAt>`n`t`t<longitude>" . FocusPointLongitude . "</longitude>`n`t`t<latitude>" . FocusPointLatitude . "</latitude>`n`t`t<altitude>" . FocusPointAltitudeM . "</altitude>`n`t`t<range>" . RangeM . "</range>`n`t`t<tilt>" . Tilt . "</tilt>`n`t`t<heading>" . Azimuth . "</heading>`n`t</LookAt>`n"
	SB_SetTextTime("  KML LookAt code copied. ")
  }
return

SavePos:
  GetKeyState, shiftstate, Shift
  GetKeyState, ctrlstate, Ctrl
  If (shiftstate = "D" and ctrlstate = "U") {
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLatitude, %FocusPointLatitude%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLongitude, %FocusPointLongitude%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitude, %FocusPointAltitudeM%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitudeMode, %FocusPointAltitudeMode%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Range, %RangeM%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Tilt, %Tilt%
	RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Azimuth, %Azimuth%
	SB_SetTextTime("  Saved coordinates. ")
  } else if (shiftstate = "U") {
	RegRead, FocusPointLatitude, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLatitude
	IfEqual,FocusPointLatitude
	{
		SB_SetTextTime(" No previously saved coordinates. Use Shift and click to save. ")
		return
	}
	RegRead, FocusPointLongitude, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointLongitude
	RegRead, FocusPointAltitudeM, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitude
	RegRead, FocusPointAltitudeMode, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, FocusPointAltitudeMode
	If (FocusPointAltitudeMode > 2)	
		FocusPointAltitudeMode := 1		; SetCameraParams won't take higher values
	RegRead, RangeM, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Range
	RegRead, Tilt, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Tilt
	RegRead, Azimuth, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition\%A_GuiControl%, Azimuth
	FocusPointAltitude := FocusPointAltitudeM * UnitFactor
	Range := RangeM * UnitFactor
	If (ctrlstate = "U") {
		SB_SetTextTime("  Coordinates loaded.")
		Gosub, FlyTo
	}
	If (ctrlstate = "D") {
		GuiControl,, AutoLoad, 0
		GuiControl,, FocusPointLatitude, %FocusPointLatitude%
		GuiControl,, FocusPointLongitude, %FocusPointLongitude%
		GuiControl,, FocusPointAltitude, %FocusPointAltitude%
		GuiControl, Choose, FocusPointAltitudeMode, %FocusPointAltitudeMode%
		GuiControl,, Range, %Range%
		GuiControl,, Tilt, %Tilt%
		GuiControl,, Azimuth, %Azimuth%
		GuiControl,, Altitude, %PointAltitude%
		DMSCoord := Dec2Deg(FocusPointLatitude "," FocusPointLongitude)
		SB_SetText("   DMS Coordinates:   " DMSCoord)
	}
  }
return

StatusBar:
	If (A_GuiEvent = "DoubleClick") {
		clipboard := DMSCoord
		SB_SetTextTime("  DMS coordinates copied. ")
	}
return

SB_SetTextTime(newtext, time=3000) {
	global freezeSB
	SB_SetText(newtext)
	freezeSB = 1
	SetTimer, ResetSB, %time%
	return
}

ResetSB:
	SB_SetText("   DMS Coordinates:   " DMSCoord)
	freezeSB = 0
	SetTimer, ResetSB, Off
return

WM_MOUSEMOVE() {
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
  OnTop := (OnTop - 1)**2	; toggle value 1/0
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPosition, OnTop, %OnTop%
return

Crosshair:
  RegRead GoogleEarthPath, HKEY_LOCAL_MACHINE, SOFTWARE\Google\Google Earth Plus, InstallDir
  RegRead GoogleEarthPath5, HKEY_CURRENT_USER, SOFTWARE\Google\Google Earth Plus, InstallLocation
  IfExist, %GoogleEarthPath%\res\cursor_crosshair_thick.png
	CrosshairImage = %GoogleEarthPath%\res\cursor_crosshair_thick.png
  Else IfExist, %GoogleEarthPath%\res\shapes\cross-hairs_highlight.png
	CrosshairImage = %GoogleEarthPath%\res\shapes\cross-hairs_highlight.png
  Else IfExist, %GoogleEarthPath5%\client\res\cursor_crosshair_thick.png
	CrosshairImage = %GoogleEarthPath5%\client\res\cursor_crosshair_thick.png
  Else
	CrosshairImage = %A_ProgramFiles%\Google\Google Earth\res\shapes\cross-hairs_highlight.png
  CrosshairKml =
  (
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
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

UnitFeet:
Menu, unit, Check, Feet
Menu, unit, Uncheck, Meters
UnitFactor := 3.2808399
FocusPointAltitude_TT := "Altitude of the focus point, in feet (always 0 when querying current position from Google Earth)"
Range_TT := "Viewpoint distance from focus point, in feet (change unit in right-click menu)"
Altitude_TT := "The terrain altitude of the current focus point, in feet (change unit in right-click menu).`nEnabling the option to Read Altitude (in the right-click menu) may slow down Google Earth."
return

UnitMeter:
Menu, unit, Uncheck, Feet
Menu, unit, Check, Meters
UnitFactor := 1
FocusPointAltitude_TT := "Altitude of the focus point, in meters (always 0 when querying current position from Google Earth)"
Range_TT := "Viewpoint distance from focus point, in meters (change unit in right-click menu)"
Altitude_TT := "The terrain altitude of the current focus point, in meters (change unit in right-click menu).`nEnabling the option to Read Altitude (in the right-click menu) may slow down Google Earth."
return

GuiContextMenu:
  Menu, context, Show
return

GuiClose:
  SaveWinPos("GoogleEarthPosition")
  WS_Uninitialize()
ExitApp

GuiEscape:
	WinMinimize
return

SaveWinPos(HKCUswRegkey) {	; add SaveWinPos("my_program") in "GuiClose:" routine
  WinGetPos, X, Y, , , A  ; "A" to get the active window's pos.
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\%HKCUswRegkey%, WindowX, %X%
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\%HKCUswRegkey%, WindowY, %Y%
}

GetSavedWinPos(HKCURegkey) {	; add WinPos := GetSavedWinPos("my_program") before "Gui, Show, %WinPos%,.." command
  RegRead, WindowX, HKEY_CURRENT_USER, SOFTWARE\%HKCURegkey%, WindowX
  RegRead, WindowY, HKEY_CURRENT_USER, SOFTWARE\%HKCURegkey%, WindowY
  If ((WindowX+200) > A_ScreenWidth or (WindowY+200) > A_ScreenHeight or WindowX < 0 or WindowY < 0)
	return "Center"
  return "X" WindowX " Y" WindowY
}

About:
  Gui 2:Destroy
  Gui 2:+Owner
  Gui 1:+Disabled
  Gui 2:Font,Bold
  Gui 2:Add,Text,x+0 yp+10, Google Earth Position %version%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+16, by David Tryse
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
  Gui 2:Add,Text,xm gwebHome yp+15, http://earth.tryse.net
  Gui 2:Add,Text,xm gwebCode yp+15, http://googleearth-autohotkey.googlecode.com
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

webHome:
  Run, http://earth.tryse.net#programs,,UseErrorLevel
Return

webCode:
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
