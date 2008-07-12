; _libGoogleEarth.ahk  version 1.15
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPLv2+
; 
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; This file contains functions for:
; * reading / setting coordinates for Google Earth
; * converting different format coordinates
; * reading/writing Exif GPS coordinates from JPEG files
; 
; Needs ws4ahk.ahk library:  http://www.autohotkey.net/~easycom/
; Functions for Exif GPS data needs exiv2.exe:  http://www.exiv2.org/
; Functions for Exif GPS data will optionally use cmdret.dll if present (to avoid temp files for command output):  http://www.autohotkey.com/forum/topic3687.html
; 
; The script uses the Google Earth COM API  ( http://earth.google.com/comapi/ )
;
; Version history:
; 1.15   -   Fix for localized OS with "," instead of "." as decimal separator (thanks Antti Rasi)
; 1.14   -   remake Deg2Dec() to understand when Lat and Long are different format - one is Deg Min and one Deg Min Sec etc.
; 1.13   -   make Deg2Dec() understand "Deg Min" and "Deg" formats in addition to Deg Min Sec
; 1.12   -   added ImageDim() function to get image width/height using imagemagick (or plain autohotkey if identify.exe can't be found - slow..)
; 1.11   -   added GetGEpoint() function to read Altitude from GE * added GetPhotoLatLongAlt()/SetPhotoLatLongAlt() functions to read/write JPEG Altitude Exif



#include ws4ahk.ahk
#NoEnv

WS_Initialize()

VBCode =
(
   Dim googleEarth
   Dim camPos
   Dim FocusPointLatitude
   Dim FocusPointLongitude
   Dim FocusPointAltitude
   Dim FocusPointAltitudeMode
   Dim Range
   Dim Tilt
   Dim Azimuth
   Dim Speed
   Dim pointPos
  
   Function testGe()
	Set googleEarth = CreateObject("GoogleEarth.ApplicationGE")
	testGe = googleEarth.IsInitialized()
   end Function

   Function gePos()
	Set googleEarth = CreateObject("GoogleEarth.ApplicationGE")
	Set camPos = googleEarth.GetCamera(1)
	gePos = camPos.FocusPointLatitude & ":" & camPos.FocusPointLongitude & ":" & camPos.FocusPointAltitude & ":" & camPos.FocusPointAltitudeMode & ":" & camPos.Range & ":" & camPos.Tilt & ":" & camPos.Azimuth & ":"
   end Function

   Function geSetPos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, Range, Tilt, Azimuth, Speed)
	Set googleEarth = CreateObject("GoogleEarth.ApplicationGE")
	Set geSetPos = googleEarth.SetCameraParams(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, Range, Tilt, Azimuth, Speed)
   end Function

   Function gePoint()
	Set googleEarth = CreateObject("GoogleEarth.ApplicationGE")
	Set pointPos = googleEarth.GetPointOnTerrainFromScreenCoords(0,0)
	gePoint = pointPos.Latitude & ":" & pointPos.Longitude & ":" & pointPos.Altitude & ":" & pointPos.ProjectedOntoGlobe & ":" & pointPos.ZeroElevationExaggeration & ":"
   end Function

)

WS_Exec(VBCode)

; ==============================================================================================================
;AltitudeModeGE { RelativeToGroundAltitudeGE = 1, AbsoluteAltitudeGE = 2 }
;
;Defines the altitude's reference origin for the focus point.
;    RelativeToGroundAltitudeGE 	Sets the altitude of the element relative to the actual ground elevation of a particular location. If the ground elevation of a location is exactly at sea level and the altitude for a point is set to 9 meters, then the placemark elevation is 9 meters with this mode. However, if the same placemark is set over a location where the ground elevation is 10 meters above sea level, then the elevation of the placemark is 19 meters.
;    AbsoluteAltitudeGE 		Sets the altitude of the element relative to sea level, regardless of the actual elevation of the terrain beneath the element. For example, if you set the altitude of a placemark to 10 meters with an absolute altitude mode, the placemark will appear to be at ground level if the terrain beneath is also 10 meters above sea level. If the terrain is 3 meters above sea level, the placemark will appear elevated above the terrain by 7 meters. A typical use of this mode is for aircraft placement.

; ==============================================================================================================



; ================================================================== COORDINATE CONVERSION ==================================================================

; call with latvar=Deg2Dec(coord,"lat") or longvar=Deg2Dec(coord,"long") - no 2nd param returns lat, long
; Input should be Degrees Minutes Seconds in any of these formats:
;    8 deg 32' 54.73" South	119 deg 29' 28.98" East
;    8°32'54.73"S, 119°29'28.98"E
;    8:32:54S,119:29:28E
; Output: -8.548333, 119.491383
Deg2Dec(DegCoord, mode = "both") {
	StringReplace DegCoord,DegCoord,deg,%A_Space%,All	; replace all possible separators with space before StringSplit
	StringReplace DegCoord,DegCoord,d,%A_Space%,All
	StringReplace DegCoord,DegCoord,°,%A_Space%,All
	StringReplace DegCoord,DegCoord,',%A_Space%,All
	StringReplace DegCoord,DegCoord,`",%A_Space%,All
	StringReplace DegCoord,DegCoord,`,,%A_Space%,All
	StringReplace DegCoord,DegCoord,:,%A_Space%,All
	StringReplace DegCoord,DegCoord,S,%A_Space%S		; add space before south/west/north/east to separate as a new word
	StringReplace DegCoord,DegCoord,N,%A_Space%N
	StringReplace DegCoord,DegCoord,E,%A_Space%E
	StringReplace DegCoord,DegCoord,W,%A_Space%W
	StringReplace DegCoord,DegCoord,Ea st,East		; fix when previous S/South and E/East replace break up west/east words...
	StringReplace DegCoord,DegCoord,W e st,West
	StringReplace DegCoord,DegCoord,W est,West
	StringReplace DegCoord,DegCoord,%A_Tab%,%A_Space%,All
	Loop {  		 	; loop to replace all double spaces (otherwise StringSplit wont work properly)
		StringReplace DegCoord,DegCoord,%A_Space%%A_Space%,%A_Space%,All UseErrorLevel
		if ErrorLevel = 0 	; No more replacements needed.
			break
	}
	DegCoord = %DegCoord% 		; remove start/end spaces
	Lat :=
	Loop, parse, DegCoord, %A_Space%,
	{
		if (A_Index = 1)
			LatD := A_LoopField
		else if (A_Index = 2) and (A_LoopField = "S" or A_LoopField = "South")	; format is Deg
			Lat := LatD * -1
		else if (A_Index = 2) and (A_LoopField = "N" or A_LoopField = "North")	; format is Deg
			Lat := LatD * 1
		else if (A_Index = 2)
			LatM := A_LoopField
		else if (A_Index = 3) and (A_LoopField = "S" or A_LoopField = "South")	; format is Deg Min
			Lat := (LatD + LatM/60) * -1
		else if (A_Index = 3) and (A_LoopField = "N" or A_LoopField = "North")	; format is Deg Min
			Lat := (LatD + LatM/60) * 1
		else if (A_Index = 3)
			LatS := A_LoopField
		else if (A_Index = 4) and (A_LoopField = "S" or A_LoopField = "South")	; format is Deg Min Sec
			Lat := (LatD + LatM/60 + LatS/60/60) * -1
		else if (A_Index = 4) and (A_LoopField = "N" or A_LoopField = "North")	; format is Deg Min Sec
			Lat := (LatD + LatM/60 + LatS/60/60) * 1
		if (A_Index = 4 and not Lat)
			return "error"
		if (Lat) {
			LatEnd := A_Index		; save where Latitude ends - for Longitude loop
			Break
		}
	}
	Long :=
	Loop, parse, DegCoord, %A_Space%,
	{
		if (A_Index = LatEnd+1)
			LongD := A_LoopField
		else if (A_Index = LatEnd+2) and (A_LoopField = "W" or A_LoopField = "West")	; format is Deg
			Long := LongD * -1
		else if (A_Index = LatEnd+2) and (A_LoopField = "E" or A_LoopField = "East")	; format is Deg
			Long := LongD * 1
		else if (A_Index = LatEnd+2)
			LongM := A_LoopField
		else if (A_Index = LatEnd+3) and (A_LoopField = "W" or A_LoopField = "West")	; format is Deg Min
			Long := (LongD + LongM/60) * -1
		else if (A_Index = LatEnd+3) and (A_LoopField = "E" or A_LoopField = "East")	; format is Deg Min
			Long := (LongD + LongM/60) * 1
		else if (A_Index = LatEnd+3)
			LongS := A_LoopField
		else if (A_Index = LatEnd+4) and (A_LoopField = "W" or A_LoopField = "West")	; format is Deg Min Sec
			Long := (LongD + LongM/60 + LongS/60/60) * -1
		else if (A_Index = LatEnd+4) and (A_LoopField = "E" or A_LoopField = "East")	; format is Deg Min Sec
			Long := (LongD + LongM/60 + LongS/60/60) * 1
		if (A_Index = LatEnd+4 and not Long)
			return "error"
		if (Long) {
			Break
		}
	}
	If mode = lat
		return Lat
	If mode = long
		return Long
	If mode = both
		return Lat ", " Long
}

; call with latvar=Deg2Dec(decimalcoord,"lat") or latlong=Dec2Deg("-10.4949666667,105.5996")
; Input: -10.4949666667  105.5996   or    -10.4949666667,105.5996
; Output: 10° 29' 41.88'' S, 105° 35' 58.56'' E
Dec2Deg(DecCoord, mode = "both") {
	StringReplace DecCoord,DecCoord,`",%A_Space%,All
	StringReplace DecCoord,DecCoord,`,,%A_Space%,All
	StringReplace DecCoord,DecCoord,:,%A_Space%,All
	StringReplace DecCoord,DecCoord,%A_Tab%,%A_Space%,All
	Loop {   ; loop to replace all double spaces (otherwise StringSplit wont work properly)
		StringReplace DecCoord,DecCoord,%A_Space%%A_Space%,%A_Space%,All UseErrorLevel
		if ErrorLevel = 0  ; No more replacements needed.
			break
	}
	DecCoord = %DecCoord%  ; remove start/end spaces
	StringSplit word, DecCoord, %A_Space%`,%A_Tab%
	LatDeg := Floor(word1**2**0.5)
	LatMin := Floor((word1**2**0.5 - LatDeg) * 60)
	LatSec := Round((word1**2**0.5 - LatDeg - LatMin/60) * 60 * 60,2)
	LatPol = N
	If (word1 < 0)
		LatPol = S
	Lat := LatDeg "° " LatMin "' " LatSec "'' " LatPol
	LongDeg := Floor(word2**2**0.5)
	LongMin := Floor((word2**2**0.5 - LongDeg) * 60)
	LongSec := Round((word2**2**0.5 - LongDeg - LongMin/60) * 60 * 60,2)
	LongPol = E
	If (word2 < 0)
		LongPol = W
	Long := LongDeg "° " LongMin "' " LongSec "'' " LongPol
	If mode = lat
		return Lat
	If mode = long
		return Long
	If mode = both
		return Lat ", " Long
}

; call with latvar=Deg2Rel(deccoord,"lat") or latlong=Dec2Deg(deccoord)
; Input: -0.932269, -78.605725
; Output: 0/1 55/1 5617/100, 78/1 36/1 2061/10       (useful for raw Exif GPS)
Dec2Rel(DecCoord, mode = "both") {
	StringReplace DecCoord,DecCoord,`",%A_Space%,All
	StringReplace DecCoord,DecCoord,`,,%A_Space%,All
	StringReplace DecCoord,DecCoord,:,%A_Space%,All
	StringReplace DecCoord,DecCoord,%A_Tab%,%A_Space%,All
	Loop {   ; loop to replace all double spaces (otherwise StringSplit wont work properly)
		StringReplace DecCoord,DecCoord,%A_Space%%A_Space%,%A_Space%,All UseErrorLevel
		if ErrorLevel = 0  ; No more replacements needed.
			break
	}
	DecCoord = %DecCoord%
	StringSplit word, DecCoord, %A_Space%`,%A_Tab%
	LatDeg := Floor(word1**2**0.5)
	LatMin := Floor((word1**2**0.5 - LatDeg) * 60)
	LatSec := Round((word1**2**0.5 - LatDeg - LatMin/60) * 60 * 60 * 100,0)
	Lat := LatDeg "/1 " LatMin "/1 " LatSec "/100"
	LongDeg := Floor(word2**2**0.5)
	LongMin := Floor((word2**2**0.5 - LongDeg) * 60)
	LongSec := Round((word2**2**0.5 - LongDeg - LongMin/60) * 60 * 60 * 100,0)
	Long := LongDeg "/1 " LongMin "/1 " LongSec "/100"
	If mode = lat
		return Lat
	If mode = long
		return Long
	If mode = both
		return Lat ", " Long
}

; ================================================================== GOOGLE EARTH FUNCTIONS ==================================================================

; simple check if the Google Earth client is running or not
IsGErunning() {
	SetTitleMatchMode 3
	If WinExist("Google Earth") and WinExist("ahk_class QWidget")
	    return 1
	return 0
}

;call with GetGEpos(FocusPointLatitude,FocusPointLongitude,FocusPointAltitude,FocusPointAltitudeMode,Range,Tilt,Azimuth)
GetGEpos(byref FocusPointLatitude, byref FocusPointLongitude, byref FocusPointAltitude, byref FocusPointAltitudeMode, byref Range, byref Tilt, byref Azimuth) {
	If not IsGErunning()
		return 1
	WS_Eval(theValue, "gePos()")
	StringReplace theValue,theValue,`,,.,All		; fix for localized OS - thanks Antti Rasi
	StringSplit word_array,theValue,:,
	FocusPointLatitude	= %word_array1%
	FocusPointLongitude	= %word_array2%
	FocusPointAltitude	= %word_array3%
	FocusPointAltitudeMode	= %word_array4%
	Range			= %word_array5%
	Tilt			= %word_array6%
	Azimuth			= %word_array7%
	If Tilt contains E
		Tilt = 0
	If Azimuth contains E
		Azimuth = 0
	If FocusPointLatitude contains E
		FocusPointLatitude := SubStr(FocusPointLatitude, 1, InStr(FocusPointLatitude, "E")-1) * (0.1 ** SubStr(FocusPointLatitude, InStr(FocusPointLatitude, "E")+2))
	If FocusPointLongitude contains E
		FocusPointLongitude := SubStr(FocusPointLongitude, 1, InStr(FocusPointLongitude, "E")-1) * (0.1 ** SubStr(FocusPointLongitude, InStr(FocusPointLongitude, "E")+2))
}

;call with GetGEpoint(PointLatitude, PointLongitude, PointAltitude, PointProjectedOntoGlobe, pointZeroElevationExaggeration)
;GetGEpoint(byref PointLatitude, byref PointLongitude, byref PointAltitude, byref PointProjectedOntoGlobe, byref pointZeroElevationExaggeration) {
GetGEpoint(byref PointLatitude, byref PointLongitude, byref PointAltitude) {
	If not IsGErunning()
		return 1
	WS_Eval(theValue, "gePoint()")
	StringReplace theValue,theValue,`,,.,All		; fix for localized OS - thanks Antti Rasi
	StringSplit word_array,theValue,:,
	PointLatitude	= %word_array1%
	PointLongitude	= %word_array2%
	PointAltitude	= %word_array3%
	;PointProjectedOntoGlobe	= %word_array4%
	;pointZeroElevationExaggeration	= %word_array5%
	If PointAltitude contains E
		PointAltitude = 0
	If PointLatitude contains E
		PointLatitude := SubStr(PointLatitude, 1, InStr(PointLatitude, "E")-1) * (0.1 ** SubStr(PointLatitude, InStr(PointLatitude, "E")+2))
	If PointLongitude contains E
		PointLongitude := SubStr(PointLongitude, 1, InStr(PointLongitude, "E")-1) * (0.1 ** SubStr(PointLongitude, InStr(PointLongitude, "E")+2))
}

;call with SetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, Range, Tilt, Azimuth, Speed)
SetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode = 2, Range = 50000, Tilt = 0, Azimuth = 0, Speed = 1) {
	wsfunction = geSetPos(%FocusPointLatitude%, %FocusPointLongitude%, %FocusPointAltitude%, %FocusPointAltitudeMode%, %Range%, %Tilt%, %Azimuth%, %Speed%)
	WS_Eval(returnval, wsfunction)
	return returnval
}

;call with FlyToPhoto(jpegfilename) or FlyToPhoto(jpegfilename, Range, Tilt, Azimuth)
FlyToPhoto(fullfilename, range = 50000, tilt = 0, azimuth = 0) {
	IfNotExist %fullfilename%
		return 1
	GetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, xRange, xTilt, xAzimuth)
	GetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude)
	SetGEpos(FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, FocusPointAltitudeMode, Range, Tilt, Azimuth, Speed)
}

; ================================================================== JPEG EXIF GPS FUNCTIONS ==================================================================

;call with GetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude) or GetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude, "c:\prog\exiv2\exiv2.exe")
GetPhotoLatLong(fullfilename, byref FocusPointLatitude, byref FocusPointLongitude, toolpath = "exiv2.exe") {
	GetPhotoLatLongAlt(fullfilename, FocusPointLatitude, FocusPointLongitude, PointAltitude, toolpath)
	PointAltitude :=
}

;call with GetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude, PointAltitude) or GetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude, PointAltitude, "c:\prog\exiv2\exiv2.exe")
GetPhotoLatLongAlt(fullfilename, byref FocusPointLatitude, byref FocusPointLongitude, byref PointAltitude, toolpath = "exiv2.exe") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	If (toolpath = "gpsini") {
		IniRead Pos, %dir%\gps.ini, %filename%, GPS Position
		FocusPointLatitude	:= Deg2Dec(Pos,"lat")
		FocusPointLongitude	:= Deg2Dec(Pos,"long")
	} else {
		CMD := COMSPEC " /C " toolpath " -Pkt """ fullfilename """"
		captureOutput(CMD, StrOut)
		Loop, parse, StrOut, `n`r
		{
			If (SubStr(A_LoopField, 1, 28) = "Exif.GPSInfo.GPSLatitudeRef ") {
				LatRef := SubStr(A_LoopField, 30)
				LatRef = %LatRef%
			}
			If (SubStr(A_LoopField, 1, 25) = "Exif.GPSInfo.GPSLatitude ") {
				Lat := SubStr(A_LoopField, 30)
				Lat = %Lat%
			}
			If (SubStr(A_LoopField, 1, 29) = "Exif.GPSInfo.GPSLongitudeRef ") {
				LongRef := SubStr(A_LoopField, 30)
				LongRef = %LongRef%
			}
			If (SubStr(A_LoopField, 1, 26) = "Exif.GPSInfo.GPSLongitude ") {
				Long := SubStr(A_LoopField, 30)
				Long = %Long%
			}
			If (SubStr(A_LoopField, 1, 28) = "Exif.GPSInfo.GPSAltitudeRef ") {
				AltRef := SubStr(A_LoopField, 30)
				AltRef = %AltRef%
			}
			If (SubStr(A_LoopField, 1, 25) = "Exif.GPSInfo.GPSAltitude ") {
				Alt := SubStr(A_LoopField, 30)
				StringReplace Alt,Alt, m,
				Alt = %Alt%
			}
		}
		FocusPointLatitude	:= Deg2Dec(Lat " " LatRef ", " Long " " LongRef, "lat")
		FocusPointLongitude	:= Deg2Dec(Lat " " LatRef ", " Long " " LongRef, "long")
		If (AltRef = "Below sea level")
			Alt := Round(-Alt,1)
		PointAltitude		:= Alt
	}
}

;call with SetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude)
SetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude, toolpath = "exiv2.exe") {
	SetPhotoLatLongAlt(fullfilename, FocusPointLatitude, FocusPointLongitude,"",toolpath)
}

;call with SetPhotoLatLongAlt(fullfilename, FocusPointLatitude, FocusPointLongitude, FocusPointAltitude)
;EXIV2 commandline like:   exiv2.exe -M"set Exif.GPSInfo.GPSVersionID 2 2 0 0" -M"set Exif.GPSInfo.GPSLatitude 13/1 28/1 3208/100" -M"set Exif.GPSInfo.GPSLatitudeRef N" -M"set Exif.GPSInfo.GPSLongitude 103/1 29/1 3490/100" -M"set Exif.GPSInfo.GPSLongitudeRef E" -M"set Exif.GPSInfo.GPSAltitude 1810/100" -M"set Exif.GPSInfo.GPSAltitudeRef 0" "image.jpg"
SetPhotoLatLongAlt(fullfilename, FocusPointLatitude, FocusPointLongitude, FocusPointAltitude, toolpath = "exiv2.exe") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	If (FocusPointLatitude < 0)
		LatRef = S
	Else
		LatRef = N
	If (FocusPointLongitude < 0)
		LongRef = W
	Else
		LongRef = E
	LatRel := Dec2Rel(FocusPointLatitude ", " FocusPointLongitude, "lat")
	LongRel := Dec2Rel(FocusPointLatitude ", " FocusPointLongitude, "long")
	AltRel := Round(FocusPointAltitude * 100,0) "/100"
	IfEqual FocusPointAltitude
		CMD := COMSPEC " /C " toolpath " -M""set Exif.GPSInfo.GPSVersionID 2 2 0 0"" -M""set Exif.GPSInfo.GPSLatitude " LatRel """ -M""set Exif.GPSInfo.GPSLatitudeRef " LatRef """ -M""set Exif.GPSInfo.GPSLongitude " LongRel """ -M""set Exif.GPSInfo.GPSLongitudeRef " LongRef """ -M""del Exif.GPSInfo.GPSAltitudeRef"" -M""del Exif.GPSInfo.GPSAltitude"" """ fullfilename """"
	Else
		CMD := COMSPEC " /C " toolpath " -M""set Exif.GPSInfo.GPSVersionID 2 2 0 0"" -M""set Exif.GPSInfo.GPSLatitude " LatRel """ -M""set Exif.GPSInfo.GPSLatitudeRef " LatRef """ -M""set Exif.GPSInfo.GPSLongitude " LongRel """ -M""set Exif.GPSInfo.GPSLongitudeRef " LongRef """ -M""set Exif.GPSInfo.GPSAltitude " AltRel """ -M""set Exif.GPSInfo.GPSAltitudeRef 0"" """ fullfilename """"
	If captureOutput(CMD, StrOut) != 1
		Msgbox, 48, Error, %StrOut%`n`nCommand line:`n`n%CMD%
}

;call with ErasePhotoLatLong(fullfilename)
ErasePhotoLatLong(fullfilename, toolpath = "exiv2.exe") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	CMD := COMSPEC " /C " toolpath " -M""del Exif.GPSInfo.GPSVersionID"" -M""del Exif.GPSInfo.GPSLatitude"" -M""del Exif.GPSInfo.GPSLatitudeRef"" -M""del Exif.GPSInfo.GPSLongitude"" -M""del Exif.GPSInfo.GPSLongitudeRef"" -M""del Exif.GPSInfo.GPSAltitudeRef"" -M""del Exif.GPSInfo.GPSAltitude"" -M""del Exif.GPSInfo.GPSTrack"" """ fullfilename """"
	If captureOutput(CMD, StrOut) != 1
		Msgbox, 48, Error, %StrOut%`n`nCommand line:`n`n%CMD%
}

;call with GetExif(fullfilename, ExifDataOutputVar), then use msgbox %ExifDataOutputVar% etc..
GetExif(fullfilename, byref StrOut, toolpath = "exiv2.exe") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	CMD := COMSPEC " /C " toolpath " -Pkt """ fullfilename """"
	captureOutput(CMD, StrOut)
}

ImageDim(fullfilename, ImageMagickTool = "", skipifnoIM = "0") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	If not (ImageMagickTool)
		ImageMagickTool := findFile("identify.exe")
	If (ImageMagickTool) {
		CMD := COMSPEC " /C " ImageMagickTool " -ping -format ""%w x %h"" """ fullfilename """"
		captureOutput(CMD, StrOut)
		return StrOut
	} else if not (skipifnoIM) {
		DHW:=A_DetectHiddenWindows
		DetectHiddenWindows, ON
		Gui, 99:-Caption
		Gui, 99:Margin, 0, 0
		Gui, 99:Show,Hide w2592 h2592, ImageWxH.Temporary.GUI
		Gui, 99:Add, Picture, x0 y0 , %fullfilename%
		Gui, 99:Show,AutoSize Hide, ImageWxH.Temporary.GUI
		WinGetPos, , ,w,h, ImageWxH.Temporary.GUI
		Gui, 99:Destroy
		DetectHiddenWindows, %DHW%
		Return w " x " h
	}
}


; ================================================================== INTERNAL FUNCTIONS ==================================================================

; function is used internally - run command and return output - call with captureOutput(commandline, outputvar)
captureOutput(CMD, byref StrOut) {
	cmdretDllPath := findFile("cmdret.dll")
	IfEqual cmdretDllPath
	{
		Random, rand, 11111111, 99999999
		RunWait, %CMD% > %A_Temp%\_libGE_%rand%.tmp,, Hide
		FileRead, StrOut, %A_Temp%\_libGE_%rand%.tmp
		FileGetSize, ret, %A_Temp%\_libGE_%rand%.tmp
		FileDelete, %A_Temp%\_libGE_%rand%.tmp
		return ret
	} else {
		VarSetCapacity(StrOut, 32000)
		return DllCall(cmdretDllPath "\RunReturn", "str", CMD, "str", StrOut)
	}
}

; find cmdret.dll - function is used internally for deciding if to use cmdret.dll or "Run,,,hide" to get exiv2.exe command output
; %temp% is included in the search path to be able to use "FileInstall cmdret.dll, %A_Temp%\cmdret.dll" in compiled scripts
findFile(filetofind) {
	EnvGet, SearchFolders, Path
	SearchFolders := A_ScriptDir ";" A_Temp ";" A_AhkPath ";" SearchFolders
	Loop, Parse, SearchFolders, `;
	{
		IfExist, %A_LoopField%\%filetofind%
			return A_LoopField "\" filetofind
	}
}
