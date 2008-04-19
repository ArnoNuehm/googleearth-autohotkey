; LatLongConversion.ahk  version 1.01
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; License:  GPL 2+
; 
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; Creates a GUI for converting between Degree Minute Second and Decimal format coordinates
;    Decimal format:
;	-8.548333, 119.491383
;    DMS formats:
;	8:32:54S,119:29:28E
;	8 deg 32' 54.73" South	119 deg 29' 28.98" East
;	8°32'54.73"S, 119°29'28.98"E
; 
; Needs _libGoogleEarth.ahk library:  http://david.tryse.net/googleearth/

#NoEnv
#SingleInstance off
#NoTrayIcon 
#include _libGoogleEarth.ahk
version = 1.01

Menu, contex, add, About, About

Gui, Font, bold
Gui, Add, Text, y5 x5, Degrees
Gui, Add, Text, y5 x250, Decimal
Gui, Font, norm
Gui, Add, Text, y25 x5, 10° 29' 41.88'' S, 105° 35' 58.57'' E
Gui, Add, Text, y25 x250, -10.494967, 105.599603
Gui Add, Button, yp-16 xp+160 h32 w40 vAbout gAbout, ?
Gui, Add, Edit, y50 x5 vDegrees -Wrap W200 R20 -ReadOnly
Gui, Add, Edit, y50 x250 vDecimal -Wrap W200 R20 -ReadOnly

Gui, Add, Button, y90 x210 w35 h50, >>
Gui, Add, Button, y150 x210 w35 h50, <<

Gui, Add, Button, y325 x10 w100 , Copy_Degrees
Gui, Add, Button, y325 x255 w100 , Copy_Decimal

Gui, Show,, LatLong Conversion %version%
Gui +LastFound
return

Button>>:
  Gui, Submit, NoHide
  Decimal :=
  Loop, parse, Degrees, `n, `r
  {
    If (A_Index != 1)
	Decimal := Decimal "`n" 
    If (A_LoopField == "")
	Continue
    Decimal := Decimal Deg2Dec(A_LoopField)
  }
  GuiControl,, Decimal, %Decimal%  ; Put the text into the control.
return

Button<<:
  Gui, Submit, NoHide
  Degrees :=
  Loop, parse, Decimal, `n, `r
  {
    If (A_Index != 1)
	Degrees := Degrees "`n" 
    If (A_LoopField == "")
	Continue
    Degrees := Degrees Dec2Deg(A_LoopField)
  }
  GuiControl,, Degrees, %Degrees%  ; Put the text into the control.
return

ButtonCopy_Degrees:
  Gui, Submit, NoHide
  clipboard := Degrees
return

ButtonCopy_Decimal:
  Gui, Submit, NoHide
  clipboard := Decimal
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
  Gui 2:Add,Text,x+0 yp+10, LatLong Conversion %version%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, A tiny program for converting coordinates between
  Gui 2:Add,Text,xm yp+15, Degree Minute Second and Decimal formats.
  Gui 2:Add,Text,xm+10 yp+20, Decimal format:
  Gui 2:Font,CGray
  Gui 2:Add,Text,xm+20 yp+15, -8.548333, 119.491383
  Gui 2:Font
  Gui 2:Add,Text,xm+10 yp+15, DMS formats:
  Gui 2:Font,CGray
  Gui 2:Add,Text,xm+20 yp+15, 8:32:54S,119:29:28E
  Gui 2:Add,Text,xm+20 yp+15, 8 deg 32' 54.73" South	119 deg 29' 28.98" East
  Gui 2:Add,Text,xm+20 yp+15, 8°32'54.73"S, 119°29'28.98"E
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, License: GPL
  Gui 2:Add,Text,xm yp+36, Check for updates here:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gWeblink yp+15, http://david.tryse.net/googleearth/
  Gui 2:Font
  Gui 2:Add,Text,xm yp+20, For bug reports or suggestions email:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gEmaillink yp+15, davidtryse@gmail.com
  Gui 2:Font
  Gui 2:Add,Button,gAboutOk Default w80 h80 yp-50 x200,&OK
  Gui 2:Show,,About: LatLong Conversion
Return

AboutOk:
  Gui 1:-Disabled
  Gui 2:Destroy
return

Weblink:
Run, http://david.tryse.net/googleearth/,,UseErrorLevel
Return

Emaillink:
Run, mailto:davidtryse@gmail.com,,UseErrorLevel
Return

2GuiClose:
Gui 1:-Disabled
Gui 2:Destroy
return
