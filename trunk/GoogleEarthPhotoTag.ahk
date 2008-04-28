; GoogleEarthPhotoTag.ahk  version 1.11
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPLv2+
; 
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; Creates a GUI for viewing Exif GPS data in JPEG files
; * can read coordinates from the Google Earth client and write to JPEG files
; * can be used from command line / when right-clicking on JPEG files (view About: window to register)
; * can show/delete Exif GPS tag from files
; * "Auto-Mode" : jpeg files drag-and-dropped to the window will automatically be tagged with the current Google Earth coordinates
; 
; Needs _libGoogleEarth.ahk library:  http://david.tryse.net/googleearth/
; Needs ws4ahk.ahk library:  http://www.autohotkey.net/~easycom/
; Needs exiv2.exe to read/write Exif GPS data:  http://www.exiv2.org/
; Will optionally use cmdret.dll if present (to avoid temp files for command output):  http://www.autohotkey.com/forum/topic3687.html

; TODO
; multi-select (del and save)
; open all - KML?

; Version history:
; 1.11   -   add photo preview and Exif info tabs
; 1.10   -   read and write Altitude * fix list column sizing
; 1.01   -   better view-Exif-info popup

#NoEnv
#SingleInstance off
#NoTrayIcon 
#Include _libGoogleEarth.ahk
version = 1.11

; ------------ find exiv2.exe -----------
EnvGet, EnvPath, Path
EnvPath := A_ScriptDir ";" A_ScriptDir "\exiv2;" EnvPath
Loop, Parse, EnvPath, `;
{
	IfExist, %A_LoopField%\exiv2.exe
		exiv2path = %A_LoopField%\exiv2.exe
}
IfEqual exiv2path
{
	RegRead exiv2path, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPhotoTag, exiv2path
	IfEqual exiv2path
		FileSelectFile, exiv2path, 3,, Provide path to exiv2.exe, Exiv2.exe (exiv2.exe)
	IfEqual exiv2path
	{
		Msgbox,48, Cannot find exiv2.exe, Error: This tool needs exiv2.exe`nIt can be downloaded for free from www.exiv2.org
		ExitApp
	} else {
		RegWrite REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthPhotoTag, exiv2path, %exiv2path%
	}
}

; ---------------- handle command line parameters ("photo-filename" = fly to, "/SavePos photo-filename" = write coordinates) -------------------
If 0 > 0
{
	If 1 = /SavePos		; use GoogleEarthPhotoTag.exe /SavePos "c:\photos\DSC02083.JPG" to save the current Google Earth coordinates to this photo
	{
		If IsGErunning() {
			filename = %2%
			If FileExist(filename) {
				SplitPath filename, File, Folder, Ext
				GetGEpoint(PointLatitude, PointLongitude, PointAltitude)
				PointLatitude := Round(PointLatitude, 6)
				PointLongitude := Round(PointLongitude, 6)
				If (PointAltitude = 0)
					PointAltitude :=
				Else
					PointAltitude := Round(PointAltitude, 1)
				If (PointLongitude = "") or (PointLatitude = "") {
					Msgbox,48, Write Coordinates, Error: Failed to get coordinates from Google Earth.
				} else {
					SetPhotoLatLongAlt(Folder "\" File, PointLatitude, PointLongitude, PointAltitude, exiv2path)
					GetPhotoLatLongAlt(Folder "\" File, FileLatitude, FileLongitude, FileAltitude, exiv2path)	; read Exif back from photo to make sure write operation succeded
					If (Dec2Deg(FileLatitude) = Dec2Deg(PointLatitude)) and (Dec2Deg(FileLongitude) = Dec2Deg(PointLongitude) and (PointAltitude = FileAltitude or PointAltitude = "")) {    ; cannot compare directly without Dec2Deg() as 41.357892/41.357893 both equal 41° 21' 28.41'' N etc..
						IfEqual PointAltitude
							Msgbox,, Write Coordinates, Coordinates %PointLatitude%`,%PointLongitude% successfully written to %File%
						Else
							Msgbox,, Write Coordinates, Coordinates %PointLatitude%`,%PointLongitude% (%PointAltitude%m) successfully written to %File%
					} else {
						IfEqual PointAltitude
							Msgbox,48, Write Coordinates, Error: Failed to write coordinates %PointLatitude%`,%PointLongitude% to %File%
						Else
							Msgbox,48, Write Coordinates, Error: Failed to write coordinates %PointLatitude%`,%PointLongitude% (%PointAltitude%m) to %File%
					}
				}
			} else {
				Msgbox,48, Write Coordinates, Error: File does not exist: %filename%
			}
		} else {
			Msgbox,48, Write Coordinates, Error: Google Earth is not running - cannot read coordinates.
		}
	} else {		; use GoogleEarthPhotoTag.exe "c:\photos\DSC02083.JPG" to fly in Google Earth to the coordinates stored in this photo
		filename = %1%
		If FileExist(filename) {
			SplitPath filename, File, Folder, Ext
			GetPhotoLatLongAlt(Folder "\" File, FileLatitude, FileLongitude, FileAltitude, exiv2path)
			If (FileLatitude = "") or (FileLongitude = "") {
				Msgbox,48, Read Coordinates, Error: No Exif GPS data in file: %filename% %FileLatitude%, %FileLongitude%
			} else {
				If IsGErunning() {
					SetGEpos(FileLatitude, FileLongitude, 0, 2, 10000, 0, 0)
					Msgbox,, Read Coordinates, Locating coordinates %FileLatitude%`,%FileLongitude% in Google Earth..., 2
				} else {
					Msgbox,48, Read Coordinates, Error: Google Earth is not running - cannot fly to coordinates %FileLatitude%`,%FileLongitude%.
				}
			}
		}else{
			Msgbox,48, Read Coordinates, Error: File does not exist: %filename%
		}
	}
	ExitApp
}

FileInstall cmdret.dll, %A_Temp%\cmdret.dll, 1	; bundle cmdret.dll in executable (avoids temp files when capturing cmdline output) - if opening in GUI mode extract to %temp% and use

; -------- create right-click menu -------------
Menu, context, add, Always On Top, OnTop
Menu, context, add,
Menu, context, add, About, About

; ----------- create GUI ----------------
Gui, Add, Button, ym xm vAddFiles gAddFiles w74, &Add Files...
Gui, Add, Text, yp+3 xp+77 , (also drag-and-drop)
Gui, Add, Button, yp-3 xp+108 vClear gClear, &Clear List
Gui, Add, Button, yp xp+59 vReread gReread, &Reread Exif
Gui, Add, Text, ym+2 xm+324 , Google Earth coordinates:
Gui, Add, Edit, yp-2 xp+128 w73 +ReadOnly vPointLatitude,
Gui, Add, Edit, yp-0 xp+74  w73 +ReadOnly vPointLongitude,
Gui, Add, Edit, yp-0 xp+74  w50 +ReadOnly vPointAltitudeM,

Gui, Add, ListView, r11 -Multi xm+0 yp+30 w650 AltSubmit vListView gListView, File|Latitude|Longitude|Altitude|Log|Folder
LV_ModifyCol(2, "Integer")  ; For sorting purposes, indicate that column is an integer.
LV_ModifyCol(3, "Integer")
LV_ModifyCol(4, "Integer")

Gui, Add, Button, ym+210 xm+0 vOpenPhoto gOpenPhoto default, &Open photo
Gui, Add, Button, yp xp+76 vShowExif gShowExif, Show &Exif
Gui, Add, Button, yp xp+62 vDeleteExif gDeleteExif, Delete ExifGPS
Gui, Add, Button, yp xp+124 vFlyTo gFlyTo, &Fly to this photo in Google Earth
Gui, Add, Button, yp xp+167 vSavePos gSavePos, &Save Google Earth coordinates to this photo
Gui, Add, Button, yp x0 hidden vreload greload, reloa&d

Gui, Font, bold
Gui, Add, Checkbox, yp+30 xm+6 vAutoMode, %A_Space%Auto-Mode 
Gui, font, norm
Gui, Add, text, yp xp+89, (any new files added will automatically be tagged with the current Google Earth coordinates)
Gui, Add, Button, yp-2 xp+470 h18 w40 vAbout gAbout, &?
Gui, Add, Button, yp xp+45 h18 w40 vExpandGui gExpandGui, &>>

Gui, Add, Tab2,w340 h256 xm+658 ym, Show Photo|Show Exif
;Gui, Add, Picture, w340 h227 xm+658 ym+29 vPhotoView,
Gui, Add, Picture, w327 h218 xm+664 ym+29 vPhotoView,
Gui, Tab, 2
Gui, Add, Edit, t64 vExifEditfield +ReadOnly -Wrap -WantReturn w327 h218 xm+664 ym+29 
Gui, Tab

Gui, Add, StatusBar
SB_SetText(" This tool requires exiv2.exe from http://www.exiv2.org/")  ; update statusbar
LV_ModifyCol(1, 143)  ; Size columns
LV_ModifyCol(2, 80)
LV_ModifyCol(3, 80)
LV_ModifyCol(4, 60)
LV_ModifyCol(5, 90)
LV_ModifyCol(6, 193)
;Gui, Show, w1018, Google Earth PhotoTag %version%
Gui Show, w668, Google Earth PhotoTag %version%
GuiExpanded = 0

; ------------- continous loop to track Google Earth coordinates -------------
Loop {
	If IsGErunning() {
		oldPointLatitude := PointLatitude	; save old values to only update GUI when there are changes (avoid problem selecting text with the mouse)
		oldPointLongitude := PointLongitude
		oldPointAltitude := PointAltitude
		GetGEpoint(PointLatitude, PointLongitude, PointAltitude)
		PointLatitude := Round(PointLatitude, 6)
		PointLongitude := Round(PointLongitude, 6)
		If (PointAltitude = 0) {
			PointAltitude :=
			GuiControl,,PointAltitudeM,
		} Else {
			PointAltitude := Round(PointAltitude, 1)
			If (oldPointAltitude != PointAltitude)
				GuiControl,,PointAltitudeM, %PointAltitude%m
		}
		If (oldPointLatitude != PointLatitude)
			GuiControl,,PointLatitude, %PointLatitude%
		If (oldPointLongitude != PointLongitude)
			GuiControl,,PointLongitude, %PointLongitude%
	} else {
		GuiControl,,PointLatitude, not running
		GuiControl,,PointLongitude,
		GuiControl,,PointAltitudeM,
		SB_SetText(" Google Earth is not running.")	; update statusbar
	}
	FocusedRowNumber := LV_GetNext(0, "F")
	If (FocusedRowNumber != OldFocusedRowNumber) {
		ExtGuiNeedUpdate = 1
		if (not ExtGuiHasBeenOpened and FocusedRowNumber) {
			If (not GuiExpanded)
				Gosub ExpandGui				; open the view-photo tab if first time a file has been selected
		}
	} else if (ExtGuiNeedUpdate = 1) and (GuiExpanded = 1) {
		Gosub FindFocused
		Gosub UpdatePhotoView
		Gosub UpdateExifView
		ExtGuiNeedUpdate = 0
	}
	OldFocusedRowNumber := FocusedRowNumber
	Sleep 300
}


; ----------- find currently selected jpeg file in the list view ------------
FindFocused:
  File =
  ListLatitude =
  ListLongitude =
  ListAltitude =
  Folder =
  FocusedRowNumber := LV_GetNext(0, "F")  ; Find the focused row.
  If not FocusedRowNumber   ; No row is focused.
	return
  LV_GetText(File, FocusedRowNumber, 1)
  LV_GetText(ListLatitude, FocusedRowNumber, 2)
  LV_GetText(ListLongitude, FocusedRowNumber, 3)
  LV_GetText(ListAltitude, FocusedRowNumber, 4)
  LV_GetText(Folder, FocusedRowNumber, 6)
return

; --------------- add new file to listview (+write GE coordinates if auto-mode checked) ----------
AddFileToList:
  Gui, Submit, NoHide
  If (AutoMode) and IsGErunning() {
	Gosub WriteExif
  } else {
	Gosub ReadExif
  }
  LV_Add("", File, FileLatitude, FileLongitude, FileAltitude, logmsg, Folder)
return

; ------------ read Exif GPS data from file ----------------
ReadExif:
  GetPhotoLatLongAlt(Folder "\" File, FileLatitude, FileLongitude, FileAltitude, exiv2path)
  logmsg := "read Exif failed"
  If (FileLatitude != "") and (FileLongitude != "") 
	logmsg := "read Exif ok"
return

; ----------- write Exif GPS data to file ---------------
WriteExif:
  If IsGErunning() {
	IfEqual PointAltitude
		SB_SetText("Writing coordinates " PointLatitude ", " PointLongitude " to file " File )  ; update statusbar
	Else
		SB_SetText("Writing coordinates " PointLatitude ", " PointLongitude " (" PointAltitude "m)" " to file " File )  ; update statusbar
	logmsg := "write Exif failed"
	SetPhotoLatLongAlt(Folder "\" File, PointLatitude, PointLongitude, PointAltitude, exiv2path)
	GetPhotoLatLongAlt(Folder "\" File, FileLatitude, FileLongitude, FileAltitude, exiv2path)	; read Exif back from photo to make sure write operation succeded
	If (Dec2Deg(FileLatitude) = Dec2Deg(PointLatitude)) and (Dec2Deg(FileLongitude) = Dec2Deg(PointLongitude) and (PointAltitude = FileAltitude or PointAltitude = ""))    ; cannot compare directly without Dec2Deg() as 41.357892/41.357893 both equal 41° 21' 28.41'' N etc..
		logmsg := "write Exif ok"
  }
return

; =================================================== functions for GUI buttons ============================================================

AddFiles:
  Gui +OwnDialogs
  FileSelectFile, SelectedFiles, M3,, Open JPEG files..., JPEG files (*.jpg; *.jpeg)
  If SelectedFiles =
	return
  Loop, parse, SelectedFiles, `n
  {
	If (A_Index = 1) {
		Folder := A_LoopField
		Continue
	}
	File := A_LoopField
	Gosub AddFileToList
	LV_ModifyCol(1)  ; Auto-size column to fit its contents.
	LV_ModifyCol(6)
	SB_SetText(A_Index " files added.")  ; update statusbar
  }
return

Clear:
  LV_Delete() ; delete all rows in listview
  SB_SetText("Clear...")  ; update statusbar
  If (GuiExpanded)
	Gosub ExpandGui
return

Reread:
  Loop % LV_GetCount()
  {
	LV_GetText(File, A_Index, 1)
	LV_GetText(ListLatitude, A_Index, 2)
	LV_GetText(ListLongitude, A_Index, 3)
	LV_GetText(ListAltitude, A_Index, 4)
	LV_GetText(Folder, A_Index, 6)
	Gosub ReadExif
	LV_Modify(A_Index, Col1, File, FileLatitude, FileLongitude, FileAltitude, logmsg, Folder)
	SB_SetText("Exif data re-read for " A_Index " files.")  ; update statusbar
  }
  LV_ModifyCol(1)  ; Auto-size column to fit its contents.
  LV_ModifyCol(6)
return

OpenPhoto:
  Gosub FindFocused
  IfNotEqual File
	Run %Folder%\%File%    ; open jpeg in default application
return

ShowExif:
  Gosub FindFocused
  IfEqual File
	return
  GetExif(Folder "\" File, ExifData, exiv2path)
  Gui 3:Destroy
  Gui 3:+Owner
  Gui 1:+Disabled
  Gui 3: Add, Button, gExifOk Default w300 h20 ym+350 xm+100, OK
  Gui 3: Font,, Lucida Console
  Gui 3: Add, Edit, t64 vExifEditfield +ReadOnly -Wrap -WantReturn W500 R30 xm ym
  Gui 3: Font
  GuiControl 3:, ExifEditfield, %ExifData%  ; Put the text into the control.
  Gui 3: Show,, Exif data for %File%
return

DeleteExif:
  Gosub FindFocused
  IfEqual File
	return
  SB_SetText("Deleting Exif GPS data from " File )  ; update statusbar
  ErasePhotoLatLong(Folder "\" File, exiv2path)
  Gosub ReadExif
  logmsg = delete failed
  If not FileLatitude and not FileLongitude and not FileAltitude
	logmsg = delete Exif ok
  LV_Modify(FocusedRowNumber, Col1, File, FileLatitude, FileLongitude, FileAltitude, logmsg, Folder)
return

FlyTo:
  If IsGErunning() {
	Gosub FindFocused
	IfNotEqual File
		SetGEpos(ListLatitude, ListLongitude, 0, 2, 10000, 0, 0)
  } else {
	SB_SetText(" Google Earth is not running.")  ; update statusbar
  }
return

SavePos:
  If IsGErunning() {
	  Gosub FindFocused
	  IfEqual File
		return
	  Gosub WriteExif
	  LV_Modify(FocusedRowNumber, Col1, File, FileLatitude, FileLongitude, FileAltitude, logmsg, Folder)
  } else {
	SB_SetText(" Google Earth is not running.")  ; update statusbar
  }
return

; ==========================================================================================================================

GuiDropFiles:
  Loop, parse, A_GuiEvent, `n
  {
	If InStr(FileExist(A_LoopField), "D") {   ; if dragged item is a directory loop to add all jpg files
		Loop %A_LoopField%\*.jpg,,1
		{
			SplitPath A_LoopFileFullPath, File, Folder, Ext
			Gosub AddFileToList
			LV_ModifyCol(1)  ; Auto-size column to fit its contents.
			LV_ModifyCol(6)
			SB_SetText(A_Index " files added.")  ; update statusbar
		}
		Loop %A_LoopField%\*.jpeg,,1
		{
			SplitPath A_LoopFileFullPath, File, Folder, Ext
			Gosub AddFileToList
			LV_ModifyCol(1)  ; Auto-size column to fit its contents.
			LV_ModifyCol(6)
			SB_SetText(A_Index " files added.")  ; update statusbar
		}
		Continue
	}
	SplitPath A_LoopField, File, Folder, Ext
	If (Ext = "jpg" or Ext = "jpeg") {
		Gosub AddFileToList
		LV_ModifyCol(1)  ; Auto-size column to fit its contents.
		LV_ModifyCol(6)
	}
	SB_SetText(A_Index " files added.")  ; update statusbar
  }
return

reload:
  Reload
return

OnTop:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  Winset, AlwaysOnTop, Toggle, A
return

ListView:
  ;SB_SetText(A_GuiEvent " : " Folder "\" File) ;; xxxxxx
  If (A_GuiEvent = "DoubleClick") {
	Gosub OpenPhoto
  } else If (A_GuiEvent = "Normal") {
	; single-click actions here...
  }
return

UpdatePhotoView:
  If(File) {
	GuiControl,, PhotoView, *w-1 *h218 %Folder%\%File%
  } else {
	GuiControl,, PhotoView,	; empty control
  }
return

UpdateExifView:
  If(File) {
	GetExif(Folder "\" File, ExifData, exiv2path)
	GuiControl,, ExifEditfield, Filename:  %File%  (%Folder%)`n==================================================`n%ExifData%  ; Put the text into the control.
  } else {
	GuiControl,, ExifEditfield,	; empty control
  }
return

ExpandGui:
  If (GuiExpanded) {
	Gui Show, w668, Google Earth PhotoTag %version%
	GuiControl, Text, ExpandGui, &>>
	GuiControl,, PhotoView,	; empty controls
	GuiControl,, ExifEditfield,
	GuiExpanded = 0
  } else  {
	Gui Show, w1018, Google Earth PhotoTag %version%
	GuiControl, Text, ExpandGui, &<<
	GuiExpanded = 1
	ExtGuiNeedUpdate = 1
  }
  ExtGuiHasBeenOpened = 1
return

GuiContextMenu:
  if A_GuiControl != ListView 		; don't show right-click menu it click was in listview
	Menu, context, Show
return

GuiClose:
  ;FileDelete %A_Temp%\cmdret.dll
ExitApp

ExifOk:
3GuiClose:
3GuiEscape:
  Gui 1:-Disabled
  Gui 3:Destroy
return

About:
  Gui 2:Destroy
  Gui 2:+Owner
  Gui 1:+Disabled
  Gui 2:Font,Bold
  Gui 2:Add,Text,x+0 yp+10, Google Earth PhotoTag %version%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, A small program for adding Exif GPS data to JPEG files
  Gui 2:Add,Text,xm yp+15, and reading coordinates from the Google Earth client.
  Gui 2:Add,Text,xm yp+18, License: GPLv2+
  Gui 2:Add,Button,gAssoc x40 yp+26 w200, &Add right-click options to JPEG files
  Gui 2:Add,Text,xm yp+36, Check for updates here:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gWeblink yp+15, http://david.tryse.net/googleearth/
  Gui 2:Font
  Gui 2:Add,Text,xm yp+20, For bug reports or ideas email:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gEmaillink yp+15, davidtryse@gmail.com
  Gui 2:Font
  Gui 2:Add,Text,xm yp+28, This program requires exiv2.exe:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gExiv2link yp+15, http://www.exiv2.org/
  Gui 2:Font
  Gui 2:Add,Button,gAboutOk Default w80 h80 yp-60 x180,&OK
  Gui 2:Show,,About: Google Earth PhotoTag
  Gui 2:+LastFound
  WinSet AlwaysOnTop
Return

Weblink:
  Run, http://david.tryse.net/googleearth/,,UseErrorLevel
Return

Emaillink:
  Run, mailto:davidtryse@gmail.com,,UseErrorLevel
Return

Exiv2link:
  Run, http://www.exiv2.org/,,UseErrorLevel
Return

AboutOk:
2GuiClose:
2GuiEscape:
  Gui 1:-Disabled
  Gui 2:Destroy
return

Assoc:
  Gui +OwnDialogs
  RegRead JpegReg, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\.jpg
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSRead\command , , "%A_ScriptFullPath%" "`%1"
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSRead , , Read Google Earth coordinates from file
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSWrite\command , , "%A_ScriptFullPath%" /SavePos "`%1"
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSWrite , , Write Google Earth coordinates to file
  RegRead JpegReg, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\.jpeg
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSRead\command , , "%A_ScriptFullPath%" "`%1"
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSRead , , Read Google Earth coordinates from file
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSWrite\command , , "%A_ScriptFullPath%" /SavePos "`%1"
  RegWrite REG_SZ, HKEY_LOCAL_MACHINE, SOFTWARE\Classes\%JpegReg%\shell\GPSWrite , , Write Google Earth coordinates to file
  MsgBox,, Registry Options, You can now right-click JPEG files to read/save GPS coordinates
return
