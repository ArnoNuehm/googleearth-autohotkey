; _libGoogleEarth.ahk  version 1.10
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPL 2+
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
	StringReplace DegCoord,DegCoord,deg,%A_Space%,All
	StringReplace DegCoord,DegCoord,d,%A_Space%,All
	StringReplace DegCoord,DegCoord,°,%A_Space%,All
	StringReplace DegCoord,DegCoord,',%A_Space%,All
	StringReplace DegCoord,DegCoord,`",%A_Space%,All
	StringReplace DegCoord,DegCoord,`,,%A_Space%,All
	StringReplace DegCoord,DegCoord,:,%A_Space%,All
	StringReplace DegCoord,DegCoord,S,%A_Space%S
	StringReplace DegCoord,DegCoord,N,%A_Space%N
	StringReplace DegCoord,DegCoord,E,%A_Space%E
	StringReplace DegCoord,DegCoord,W,%A_Space%W
	StringReplace DegCoord,DegCoord,%A_Tab%,%A_Space%,All
	Loop {   ; loop to replace all double spaces (otherwise StringSplit wont work properly)
		StringReplace DegCoord,DegCoord,%A_Space%%A_Space%,%A_Space%,All UseErrorLevel
		if ErrorLevel = 0  ; No more replacements needed.
			break
	}
	DegCoord = %DegCoord%  ; remove start/end spaces
	StringSplit word, DegCoord, %A_Space%
	Lat := word1 + word2/60 + word3/60/60
	If (word4 = "S") or (word4 = "South")
		Lat := Lat * -1
	Long := word5 + word6/60 + word7/60/60
	If (word8 = "W") or (word8 = "West")
		Long := Long * -1
	If mode = lat
		return Lat
	If mode = long
		return Long
	If mode = both
		return Lat ", " Long
}

; call with latvar=Deg2Dec(decimalcoord,"lat") or latlong=Dec2Deg(decimalcoord)
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
			If (SubStr(A_LoopField, 1, 28) = "Exif.GPSInfo.GPSLatitudeRef ")
				LatRef := SubStr(A_LoopField, 30)
				LatRef = %LatRef%
			If SubStr(A_LoopField, 1, 25) = "Exif.GPSInfo.GPSLatitude "
				Lat := SubStr(A_LoopField, 30)
				Lat = %Lat%
			If SubStr(A_LoopField, 1, 29) = "Exif.GPSInfo.GPSLongitudeRef "
				LongRef = % SubStr(A_LoopField, 30)
				LongRef = %LongRef%
			If SubStr(A_LoopField, 1, 26) = "Exif.GPSInfo.GPSLongitude "
				Long = % SubStr(A_LoopField, 30)
				Long = %Long%
		}
		FocusPointLatitude	:= Deg2Dec(Lat " " LatRef ", " Long " " LongRef, "lat")
		FocusPointLongitude	:= Deg2Dec(Lat " " LatRef ", " Long " " LongRef, "long")
	}
}

;call with SetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude)
;EXIV2 commandline like:   exiv2 -M"set Exif.GPSInfo.GPSLatitude 4/1 15/1 33/1" -M"set Exif.GPSInfo.GPSLatitudeRef N" image.jpg
SetPhotoLatLong(fullfilename, FocusPointLatitude, FocusPointLongitude, toolpath = "exiv2.exe") {
	IfNotExist %fullfilename%
		return 2
	SplitPath fullfilename, filename, dir
	LatRef = N
	If (FocusPointLatitude < 0)
		LatRef = S
	LongRef = E
	If (FocusPointLongitude < 0)
		LongRef = W
	LatRel := Dec2Rel(FocusPointLatitude ", " FocusPointLongitude, "lat")
	LongRel := Dec2Rel(FocusPointLatitude ", " FocusPointLongitude, "long")
	CMD := COMSPEC " /C " toolpath " -M""set Exif.GPSInfo.GPSVersionID 2 2 0 0"" -M""set Exif.GPSInfo.GPSLatitude " LatRel """ -M""set Exif.GPSInfo.GPSLatitudeRef " LatRef """ -M""set Exif.GPSInfo.GPSLongitude " LongRel """ -M""set Exif.GPSInfo.GPSLongitudeRef " LongRef """ """ fullfilename """"
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


; ================================================================== INTERNAL FUNCTIONS ==================================================================

; function is used internally - run command and return output - call with captureOutput(commandline, outputvar)
captureOutput(CMD, byref StrOut) {
	cmdretDllPath := findCmdretDll()
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
findCmdretDll() {
	EnvGet, EnvPath, Path
	EnvPath := A_ScriptDir ";" A_Temp ";" A_AhkPath ";" EnvPath
	Loop, Parse, EnvPath, `;
	{
		IfExist, %A_LoopField%\cmdret.dll
			return A_LoopField "\cmdret.dll"
	}
}
