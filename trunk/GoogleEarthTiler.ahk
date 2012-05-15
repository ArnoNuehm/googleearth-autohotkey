; GoogleEarthTiler.ahk
; by David Tryse   davidtryse@gmail.com
; http://david.tryse.net/googleearth/
; http://code.google.com/p/googleearth-autohotkey/
; License:  GPLv2+
; 
; Script for AutoHotkey   ( http://www.autohotkey.com/ )
; A small program for creating high-resolution image overlays for Google Earth.
; 
; Needs _libGoogleEarth.ahk library:  http://david.tryse.net/googleearth/
; Needs convert.exe and idenfity.exe from ImageMagick:  http://www.imagemagick.org/
; 
; Version history:
; 1.08   -   click-window-to-drag
; 1.07   -   fix open-in-google-earth button
; 1.06   -   no code changes, fix icon, remove need for MSVCR71.dll
; 1.05   -   add partial support for GeoTiff files using bundled listgeo.exe (only reads top-left and bottom-right corner coordinates to get north/south/east/west - not perfect for files with rotated/skewed fit)
; 1.04   -   read coordinates from KML file <GroundOverlay> tag, remember screen position/foder/coords, open folder button, open in GE button, new-version-check, fix "0" as coordinate bug
; 1.03   -   fix ImageMagick path issue, use cmdret.dll
; 1.02   -   add network-link kml hierarchy output, fix progress bar
; 1.01   -   fix ImageMagick download path

#NoEnv
#SingleInstance off
#NoTrayIcon 
#Include %A_ScriptDir%
#include _libGoogleEarth.ahk
version = 1.08
FileInstall cmdret.dll, %A_Temp%\cmdret.dll, 1	; bundle cmdret.dll in executable (avoids temp files when capturing cmdline output)
FileInstall listgeo.exe, %A_Temp%\listgeo.exe, 1	; to get corner coordinates from GeoTiff files
ListGeo := A_Temp "\listgeo.exe"

; ------------ find ImageMagick tools identify.exe / convert.exe -----------
RegRead, ImageMagickPath, HKEY_LOCAL_MACHINE, SOFTWARE\ImageMagick\Current, BinPath
If (!FileExist(ImageMagickPath "\identify.exe")) {
  ImageMagickPath :=
  EnvGet, EnvPath, Path
  EnvPath := A_ScriptDir ";" "c:\Program Files\ImageMagick" ";" EnvPath
  Loop, Parse, EnvPath, `;
  {
  	IfExist, %A_LoopField%\identify.exe
  		ImageMagickPath = %A_LoopField%
  }
  IfEqual ImageMagickPath
  {
	RegRead ImageMagickPath, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, ImageMagickPath
	IfEqual ImageMagickPath
	{
		FileSelectFile, IdentifyExePath, 3,, Provide path to ImageMagick identify.exe, identify.exe (identify.exe)
		SplitPath, IdentifyExePath,,ImageMagickPath
	}
	IfEqual ImageMagickPath
	{
		Msgbox,48, Cannot find ImageMagick identify.exe, Error: This tool needs the ImageMagick tools (identify.exe/convert.exe)`nThe tools can be downloaded for free from www.ImageMagick.org
		ExitApp
	} else {
		RegWrite REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, ImageMagickPath, %ImageMagickPath%
	}
  }
}

; ------------ static variables -----------
KMLhead =
(
<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" xmlns:gx="http://www.google.com/kml/ext/2.2" xmlns:kml="http://www.opengis.net/kml/2.2" xmlns:atom="http://www.w3.org/2005/Atom">
<Document>
)
KMLtail := "`r`n</Document>`r`n</kml>"

; ----------- restore last folder/coords ----------------
RegRead, OutFolder, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, OutFolder
RegRead, LongitudeNorth, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LongitudeNorth
RegRead, LongitudeSouth, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LongitudeSouth
RegRead, LatitudeWest, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LatitudeWest
RegRead, LatitudeEast, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LatitudeEast

; -------- create right-click menu -------------
Menu, context, add, Always On Top, OnTop
Menu, context, add,
Menu, context, add, Check for updates, webHome
Menu, context, add, About, About

; ----------- create GUI ----------------
Gui, Margin, 6, 6
Gui Add, Button, xm ym+5 gOpenFileDialog, &Open Image..
Gui Add, Edit, vImageFile ReadOnly yp xp+90 w230 r1 0x400,
ImageFile_TT := "Input image file to create <GroundOverlay> tiles from."

Gui, Add, Text, yp+28 xm+20, Image Size:
Gui, Add, Edit, yp-4 xp+70 w100 vImageWidth ReadOnly,
Gui, Add, Text, yp+4 xp+112, x
Gui, Add, Edit, yp-4 xp+18 w100 vImageHeight ReadOnly,
ImageHeight_TT := "Height of the input image in pixels."
ImageWidth_TT := "Width of the input image in pixels."

Gui, Font, bold
Gui, Add, GroupBox, yp+30 xm w320 h90, Coordinates
Gui, Font, norm
Gui, Add, Text, yp+18 xm+6, &North:
Gui, Add, Text, yp+24 xm+6, West-East:
Gui, Add, Text, yp+24 xm+6, South:
Gui, Add, Edit, yp-52 xm+113 w120 vLongitudeNorth, %LongitudeNorth%
Gui, Add, Button, yp xm+251 w60 h21 gOpenKmlDialog, from KML
; Gui, Add, Edit, yp-52 xm+128 w120 vLongitudeNorth, %LongitudeNorth%
Gui, Add, Edit, yp+24 xm+66 w120 vLatitudeWest, %LatitudeWest%
Gui, Add, Edit, yp xp+124 w120 vLatitudeEast, %LatitudeEast%
Gui, Add, Edit, yp+24 xm+113 w120 vLongitudeSouth, %LongitudeSouth%
; Gui, Add, Edit, yp+24 xm+128 w120 vLongitudeSouth, %LongitudeSouth%
LongitudeNorth_TT := "A number between -90 and 90.`nCoordinate for the top (or northern) edge of the <GroundOverlay> image."
LongitudeSouth_TT := "A number between -90 and 90.`nCoordinate for the bottom (or southern) edge of the <GroundOverlay> image."
LatitudeWest_TT := "A number between -180 and 180.`nCoordinate for the left (or western) edge of the <GroundOverlay> image."
LatitudeEast_TT := "A number between -180 and 180.`nCoordinate for the right (or eastern) edge of the <GroundOverlay> image."

Gui, Add, Text, yp+40 xm, Tile Size:
Gui, Add, DropDownList, yp-4 xp+50 w80 Choose2 gPreCheck vTilesize, 128x128|256x256|512x512
Gui, Add, Text, yp+4 xp+92, KML:
Gui, Add, DropDownList, yp-4 xp+33 w90 Choose1 gPreCheck vKmltype, Single-file|Network-links
Tilesize_TT := "Size in pixels of the output image tiles.`nA bigger size (like 512x512) means fewer output files."
Kmltype_TT := "Output KML as a single file or as a hierarchy of small network link files?`nNetwork links are better for larger projects."
;Gui, Add, Text, yp+4 xp+90, Tile Grid:
;Gui, Add, DropDownList, yp-4 xp+50 w60 Choose1 gPreCheck vGrid, 2x2|3x3|4x4
;Grid_TT := "Tile arrangement: how many smaller images to show inside each image when zooming closer."

Gui, Add, Button, yp-1 xm+271 w50 h47 vAbout gAbout, &?

Gui, Add, Text, yp+29 xm+0, Fade-in:
Gui, Add, DropDownList, yp-4 xp+50 w80 Choose1 vFadeIn, Smooth|Instant
Gui, Add, Text, yp+4 xp+84, ...and...
Gui, Add, DropDownList, yp-4 xp+41 w90 Choose1 vFadeDist, Near|Far
FadeIn_TT := """Smooth"" uses transparency to fade in new images when zooming closer.`n""Instant"" shows new images directly, for higher performance.`n (this option corresponds to the <minFadeExtent> setting in the KML output)"
FadeDist_TT := "How soon to show more detailed image tiles when zooming closer.`n""Near"" has higher performance, ""Far"" looks better.`n (this option corresponds to the <minLodPixels> setting in the KML output)"

Gui Add, Text, xm yp+34, Output &Folder:
Gui Add, Edit, vOutFolder yp-4 xp+85 w200 r1 0x400, %OutFolder%
Gui Add, Button, yp-1 xp+205 w31 h23 gFolderBrowse, &...
OutFolder_TT := "Destination folder for the image tile files and the output.kml file.`nIt is best to use an empty folder."

Gui, Add, Text, yp+29 xm+0, Output Format:
Gui, Add, DropDownList, yp-4 xp+85 w50 Choose2 vFormat, PNG|JPG
Gui, Add, Text, yp+4 xp+60, Quality:
Gui, Add, DropDownList, yp-4 xp+40 w50 Choose3 vQuality, 90|80|70|60|50|40|30|20|
Gui, Font, bold
Gui, Add, Button, yp-1 xp+66 w70 vGoButton gMake, &Go!
Gui, Font, norm
Format_TT := "JPG image output has the smallest size and highest performance.`nPNG output is useful for preserving transparency in the input image file."
Quality_TT := "JPG output quality or PNG compression level."

Gui, Add, Text, yp+35 xm+0, Result:
Gui Add, Button, yp-5 xm+65 w112 h23 gFolderOpen, Open Output Folder
Gui Add, Button, yp xp+119 w137 h23 gKMLOpen vKMLOpen disabled, Open in Google Earth
; Gui Add, Button, yp+29 xm+65 w112 h23 gFolderOpen, Open Output Folder
; Gui Add, Button, yp xp+119 w137 h23 gKMLOpen, Open in Google Earth

Gui, Add, Progress, xm w321 h14 vProgressBar -Smooth
Gui Add, StatusBar, vStatusBar

; Gui, Add, Button, ym xm greload hidden, reloa&d
; Gui, Add, Button, ym xm gdebug hidden, d&ebug
WinPos := GetSavedWinPos("GoogleEarthTiler")
Gui, Show, %WinPos%, Google Earth Tiler %version%
Gui +LastFound
OnMessage(0x200, "WM_MOUSEMOVE")
OnMessage(0x201, "WM_LBUTTONDOWN")
return

WM_LBUTTONDOWN(wParam, lParam) {
	PostMessage, 0xA1, 2		; move window
}

Make:
  Gui, Submit, NoHide
  If (!ImageFile) {
	Msgbox, 48, Error, Error: Please open an image file
	return
  }
  If (!OutFolder) {
	Msgbox, 48, Error, Error: Please select output directory
	return
  }
  If (LongitudeNorth == "" or LongitudeSouth == "" or LatitudeEast == "" or LatitudeWest == "") {
	Msgbox, 48, Problem with coordinates, Error: Please enter coordinates
	return
  }
  If (LongitudeNorth > 90 or LongitudeSouth < -90 or LatitudeEast > 180 or LatitudeWest < -180 or LongitudeNorth < LongitudeSouth or LatitudeEast < LatitudeWest) {
	If (LongitudeNorth > 90)
		Msgbox, 48, Problem with coordinates, Error: Coordinate North cannot be over 90 degrees
	If (LongitudeSouth < -90)
		Msgbox, 48, Problem with coordinates, Error: Coordinate South cannot be less than 90 degrees
	If (LatitudeEast > 180)
		Msgbox, 48, Problem with coordinates, Error: Coordinate East cannot be over 180 degrees
	If (LatitudeWest < -180)
		Msgbox, 48, Problem with coordinates, Error: Coordinate West cannot be less than -180 degrees
	If (LongitudeNorth < LongitudeSouth)
		Msgbox, 48, Problem with coordinates, Error: Coordinate North cannot be less than coordinate South
	If (LatitudeEast < LatitudeWest)
		Msgbox, 48, Problem with coordinates, Error: Coordinate East cannot be less than coordinate West
	return
  }
  makeimg = 1
  makekml = 1
  If (FileExist(OutFolder "\tile_?_????_????.???")) {
	MsgBox, 3, Image tiles already exist! Reuse them?, This folder already contains tile_*.* image files.`n Press YES to keep these files and only create new kml output.`n Press NO to recreate both image files and kml (slower). `n Press Cancel to abort and change settings.
	IfMsgBox Yes
		makeimg :=
	IfMsgBox Cancel
	{
		makeimg :=
		makekml :=
		return
	}
  }
  If not InStr(FileExist(OutFolder), "D") {
	FileCreateDir, %OutFolder%
	If not InStr(FileExist(OutFolder), "D") {
		Msgbox, 48, Error creating directory, Error: cannot create directory %OutFolder%
		makeimg :=
		makekml :=
		return
	}
  }
  GuiControl, Disable, GoButton
  GuiControl, Disable, KMLOpen
  GuiControl,,ProgressBar, 7
PreCheck:
  Gui, Submit, NoHide
  LongitudeFull := LongitudeNorth - LongitudeSouth
  LatitudeFull := LatitudeEast - LatitudeWest
  imgx := ImageWidth
  imgy := ImageHeight
  bigdim := (imgx > imgy) ? imgx : imgy
  bigside := (imgx > imgy) ? "x" : "y"
  StringSplit, Tilesize, Tilesize, x
  tilesize := Tilesize1
  IfEqual, Grid
	Grid := "2x2"
  StringSplit, Grid, Grid, x
  minfade := (FadeIn == "Smooth") ? 128 : 0
  minlod := (FadeDist == "Near") ? tilesize : Round(tilesize * 0.7)
  step := Grid1
  gridlevel := 0
  totfiles := 0
  finalround := 0
  KMLOutput :=
  GridListDebugInfo := "Level	Full size	Images	Whole tiles	nr#	Part.tiles	nr#"
  Loop {		; loop to make tiles for each zoom level
	If (tilesize * step ** (gridlevel+0.5) < bigdim) {
		newsize := tilesize * step ** gridlevel	; size of image at this grid-level before tile-split
		sizex := round(newsize * imgx / bigdim) ; width of image at this grid-level before tile-split
		sizey := round(newsize * imgy / bigdim) ; height of image at this grid-level before tile-split
		fulltilesx := round((step ** gridlevel * (imgx / bigdim))//1) ; number of full tiles X at this grid-level
		fulltilesy := round((step ** gridlevel * (imgy / bigdim))//1) ; number of full tiles Y at this grid-level
		ptsizex := (bigside == "x") ? tilesize : sizex - fulltilesx * tilesize	 ; width of partial tiles at this grid-level
		ptsizey := (bigside == "y") ? tilesize : sizey - fulltilesy * tilesize	 ; height of partial tiles at this grid-level
		parttilesx := (ptsizex == tilesize) ? 0 : 1	 ; have partial tiles X(right) at this grid-level?
		parttilesx := (ptsizex == 0) ? 0 : parttilesx	 ; have partial tiles X(right) at this grid-level?
		parttilesy := (ptsizey == tilesize) ? 0 : 1	 ; have partial tiles Y(bottom) at this grid-level?
		parttilesy := (ptsizey == 0) ? 0 : parttilesy	 ; have partial tiles Y(bottom) at this grid-level?
		CMDlineResize := " -size " newsize "x" newsize " -resize " newsize "x" newsize
	} else {	; final round - no resizing of the source image before cutting tiles
		finalround := 1
		sizex := imgx
		sizey := imgy
		fulltilesx := round((imgx / tilesize)//1) ; number of full tiles X at this grid-level
		fulltilesy := round((imgy / tilesize)//1) ; number of full tiles Y at this grid-level
		ptsizex := imgx - fulltilesx * tilesize		; width of partial tiles at this grid-level
		ptsizey := imgy - fulltilesy * tilesize	; height of partial tiles at this grid-level
		parttilesx := (ptsizex == 0) ? 0 : 1	 ; have partial tiles X(right) at this grid-level?
		parttilesy := (ptsizey == 0) ? 0 : 1	 ; have partial tiles Y(bottom) at this grid-level?
		CMDlineResize := ""
	}
	files := (fulltilesx + parttilesx) * (fulltilesy + parttilesy)
	level%gridlevel%files := files
	level%gridlevel%x := (fulltilesx + parttilesx)
	level%gridlevel%y := (fulltilesy + parttilesy)
	totfiles := files + totfiles
	GridListDebugInfo =  %GridListDebugInfo% `n %gridlevel%	%sizex%x%sizey%	%files%	%tilesize%x%tilesize%	%fulltilesx%x%fulltilesy%	%ptsizex%x%ptsizey%	%parttilesx%x%parttilesy%
	If (makeimg) {
		CMDline := """" ImageMagickPath "\convert.exe"" " """" ImageFile """" CMDlineResize " -strip -crop " tilesize "x" tilesize " -quality " Quality " """ OutFolder "\lev_" gridlevel "_%d." Format """"
		RunWait, %CMDline%,,Hide
	}
	If (makekml) {
		KMLOutput := KMLOutput "`r`n<Folder>`r`n<name>" gridlevel "</name>"
		Loop %files% {
			oldname := OutFolder "\lev_" gridlevel "_" (A_index-1) "." Format			; name as output by ImageMagick convert.exe
			xplace := SubStr("000" ((A_index-1) // (fulltilesx + parttilesx)),-3)		; location on grid X
			yplace := SubStr("000" (mod((A_index-1), (fulltilesx + parttilesx))),-3)	; location on grid Y
			newname := "tile_" gridlevel "_" xplace "_" yplace "." Format
			noextname := "tile_" gridlevel "_" xplace "_" yplace
			If (makeimg)
				FileMove, %oldname%, %OutFolder%\%newname%, 1
			tilewidth := (parttilesx and yplace == (fulltilesx + parttilesx - 1)) ? ptsizex : tilesize		; width is partial width if last column
			tileheight := (parttilesy and xplace == (fulltilesy + parttilesy - 1)) ? ptsizey : tilesize		; height is partial height if last row
			If (gridlevel == 0) {
				TileLatNorth := LongitudeNorth
				TileLatSouth := LongitudeSouth
				TileLongWest := LatitudeWest
				TileLongEast := LatitudeEast
			} Else {
				TileLatNorth := LongitudeNorth - LongitudeFull * (xplace * tilesize) / sizey
				TileLatSouth := LongitudeNorth - LongitudeFull * (xplace * tilesize + tileheight) / sizey
				TileLongWest := LatitudeWest + LatitudeFull * (yplace * tilesize) / sizex
				TileLongEast := LatitudeWest + LatitudeFull * (yplace * tilesize + tilewidth) / sizex
			}
			thisKML := OverlayKML(noextname, newname, TileLatNorth, TileLatSouth, TileLongEast, TileLongWest, gridlevel, minlod, minfade)
			KMLOutput := KMLOutput "`r`n`t" thisKML
			if (Kmltype == "Network-links") {
				if (!finalround) {
					NWKMLfile := OutFolder "\nw" noextname ".kml"
					FileDelete, %NWKMLfile%
					FileAppend, %KMLhead%`r`n`t%thisKML%, %NWKMLfile%
					if (gridlevel) {
						NWKMLparent := OutFolder "\nwtile_" gridlevel-1 "_" SubStr("000" Floor(xplace/2),-3) "_" SubStr("000" Floor(yplace/2),-3) ".kml"	; find the parent in the network-link hierarchy
						thisNW := NWlink(noextname, TileLatNorth, TileLatSouth, TileLongEast, TileLongWest, "nw" noextname ".kml", minlod)
						IfnotExist, %NWKMLparent%
							FileAppend, %KMLhead%, %NWKMLparent%
						FileAppend, %thisNW%, %NWKMLparent%
					}
				} else {
					if (gridlevel) {
						lastlevel := gridlevel-1
						NWKMLparent := OutFolder "\nwtile_" gridlevel-1 "_" SubStr("000" Floor( xplace*tilesize / sizex * (level%lastlevel%x)),-3) "_" SubStr("000" Floor( yplace*tilesize / sizey * (level%lastlevel%y)),-3) ".kml"		; final level might not fit grid perfectly - just drop under closest parent
						IfnotExist, %NWKMLparent%
							FileAppend, %KMLhead%, %NWKMLparent%
						FileAppend, `r`n`t%thisKML%, %NWKMLparent%
					}
				}
			}
		}
		KMLOutput := KMLOutput "`r`n</Folder>"
		GuiControl,,ProgressBar, % ((gridlevel + 1) / (GridLevels) * 100)//1
	}
	gridlevel := gridlevel + 1
	If (finalround)
		Break
  }
  GridListDebugInfo =  %GridListDebugInfo% `n`nTotal image tiles: %totfiles%
  gridlevels := gridlevel
  ; KMLsize := Round((StrLen(KMLOutput) + StrLen(KMLhead) + StrLen(KMLtail)) / 1024)
  If (totfiles > 1)
	SB_SetText("  Output: " totfiles " image tile files in " gridlevel " zoom levels.")
  If (makekml) {
    if (Kmltype == "Network-links") {
		Loop, %OutFolder%\nwtile_?_????_????.kml
		{
			FileAppend, %KMLtail%, %A_LoopFileFullPath%
		}
		KMLfile := OutFolder "\output_nw.kml"
		FileMove %OutFolder%\nwtile_0_0000_0000.kml, %KMLfile%,1
	} else {
		KMLfile := OutFolder "\output.kml"
		IfExist, %KMLfile%
			FileMove, %KMLfile%, %OutFolder%\output-old.kml, 1
		FileDelete, %KMLfile%
		FileAppend, %KMLhead%%KMLOutput%%KMLtail%, %KMLfile%
	}
	KMLOutput :=
	makekml :=
	GuiControl, Enable, GoButton
	GuiControl, Enable, KMLOpen
  }
  If (makeimg) {
	makeimg :=
	GuiControl, Enable, GoButton
	GuiControl, Enable, KMLOpen
  }
return

OverlayKML(name, filename, north, south, east, west, draworder = "1", minlod = "128", minfade = "128") {
  ;StringReplace, filename, filename,\,/
  KMLOutput = 
	(
	<GroundOverlay>
		<name>%name%</name>
		<drawOrder>%draworder%</drawOrder>
		<Icon>
			<href>%filename%</href>
		</Icon>
		<LatLonBox>
			<north>%north%</north>
			<south>%south%</south>
			<east>%east%</east>
			<west>%west%</west>
		</LatLonBox>
	)
  If (draworder) {	; don't add Region for first level
	KMLOutput = %KMLOutput%`n
	(
		<Region>
			<LatLonAltBox>
				<north>%north%</north>
				<south>%south%</south>
				<east>%east%</east>
				<west>%west%</west>
			</LatLonAltBox>
			<Lod>
				<minLodPixels>%minlod%</minLodPixels>
				<maxLodPixels>-1</maxLodPixels>
				<minFadeExtent>%minfade%</minFadeExtent>
				<maxFadeExtent>0</maxFadeExtent>
			</Lod>
		</Region>
	)
  }
  KMLOutput := KMLOutput "`n`t</GroundOverlay>"
  return KMLOutput
}

NWlink(nwname, north, south, east, west, link, minlod="128") {
  KMLOutput = %KMLOutput%`n
  (
	<NetworkLink>
		<name>%nwname%</name>
		<Region>
			<LatLonAltBox>
				<north>%north%</north>
				<south>%south%</south>
				<east>%east%</east>
				<west>%west%</west>
			</LatLonAltBox>
			<Lod>
				<minLodPixels>%minlod%</minLodPixels>
				<maxLodPixels>-1</maxLodPixels>
			</Lod>
		</Region>
		<Link>
			<href>%link%</href>
			<viewRefreshMode>onRegion</viewRefreshMode>
		</Link>
	</NetworkLink>
  )
  return KMLOutput 
}

OpenKmlDialog:
  FileSelectFile, SelectedFile, 3, , Open a KML file with a <GroundOverlay> tag..., KML files (*.kml)
  IfEqual SelectedFile,, return
  CoordFromKML(SelectedFile)
return

OpenFileDialog:
  FileSelectFile, SelectedFile, 3, , Open an image file..., Image files (*.*)
OpenFile:
  IfEqual SelectedFile,, return
  SplitPath, SelectedFile,,, Ext,
  If (Ext == "kml") {
	CoordFromKML(SelectedFile)
	return
  }
  If (Ext == "tif") {
	CoordFromTif(SelectedFile, ListGeo)
  }
  GuiControl,, ImageFile,
  GuiControl,, ImageWidth,...
  GuiControl,, ImageHeight,...
  SB_SetText("")
  Sleep 10
  ImageXYret := ImageDim(SelectedFile, ImageWidth, ImageHeight, ImageMagickPath "\identify.exe", skipifnoIM = "1")
  If (ImageXYret or ImageWidth = "" or ImageHeight = "") {
	Msgbox, 48, Error reading image file, Error getting dimensions for file: %SelectedFile%
  } else {
	GuiControl,, ImageFile, %SelectedFile%
	GuiControl,, ImageWidth, %ImageWidth%
	GuiControl,, ImageHeight, %ImageHeight%
	GoSub PreCheck
	SplitPath, SelectedFile,, Dir,, Name
	If (FileExist(Dir "\" Name ".kml")) {
		MsgBox, 4, Load coordinates from KML file?, A .kml file with the same name as the image exists in the folder.`nWould you like to try loading <GroundOverlay> coordinates from it?
		IfMsgBox Yes
			CoordFromKML(Dir "\" Name ".kml")
	}
  }
return

CoordFromKML(kmlcoordfile) {
	FileRead kmlcode, %kmlcoordfile%
	RegExMatch(kmlcode, "s).*<GroundOverlay.*<LatLonBox>.*<north>([0-9\.-]*)</north>.*</LatLonBox>.*</GroundOverlay>.*", kmlnorth)
	RegExMatch(kmlcode, "s).*<GroundOverlay.*<LatLonBox>.*<south>([0-9\.-]*)</south>.*</LatLonBox>.*</GroundOverlay>.*", kmlsouth)
	RegExMatch(kmlcode, "s).*<GroundOverlay.*<LatLonBox>.*<west>([0-9\.-]*)</west>.*</LatLonBox>.*</GroundOverlay>.*", kmlwest)
	RegExMatch(kmlcode, "s).*<GroundOverlay.*<LatLonBox>.*<east>([0-9\.-]*)</east>.*</LatLonBox>.*</GroundOverlay>.*", kmleast)
	If (kmlnorth1 != "" and kmlsouth1 != "" and kmlwest1 != "" and kmleast1 != "") {
		GuiControl,, LongitudeNorth, %kmlnorth1%
		GuiControl,, LongitudeSouth, %kmlsouth1%
		GuiControl,, LatitudeWest, %kmlwest1%
		GuiControl,, LatitudeEast, %kmleast1%
	} else {
		Msgbox,48, No GroundOverlay coordinates found!, Error: Cannot find GroundOverlay LatLonBox coordinates in %kmlcoordfile%.
	}
}

CoordFromTif(imagefile, ListGeo) {
	CMD := """" ListGeo """ """ imagefile """"
	StrOut := captureOutput(CMD)
	RegExMatch(StrOut, "Upper\s*Left\s*\([-0-9\s\,\.]*\)\s*\((.*),(.*)\)", geotifTL)
	RegExMatch(StrOut, "Lower\s*Right\s*\([-0-9\s\,\.]*\)\s*\((.*),(.*)\)", geotifLR)
	RegExMatch(StrOut, "Lower\s*Left\s*\([-0-9\s\,\.]*\)\s*\((.*),(.*)\)", geotifLL)
	RegExMatch(StrOut, "Upper\s*Right\s*\([-0-9\s\,\.]*\)\s*\((.*),(.*)\)", geotifTR)
	tifnorth1 := Deg2Dec(geotifTL2 "," geotifTL1, "lat")
	tifwest1  := Deg2Dec(geotifTL2 "," geotifTL1, "long")
	tifsouth1 := Deg2Dec(geotifLR2 "," geotifLR1, "lat")
	tifeast1  := Deg2Dec(geotifLR2 "," geotifLR1, "long")
	; tifnorth2 := Deg2Dec(geotifTR2 "," geotifTR1, "lat")
	; tifwest2  := Deg2Dec(geotifLL2 "," geotifLL1, "long")
	; tifsouth2 := Deg2Dec(geotifLL2 "," geotifLL1, "lat")
	; tifeast2  := Deg2Dec(geotifTR2 "," geotifTR1, "long")
	; msgbox % StrOut
	If (tifnorth1 != "" and tifsouth1 != "" and tifwest1 != "" and tifeast1 != "") {
		MsgBox, 4, Load coordinates from GeoTiff file?, GoogleEarthTiler can read the north/south/east/west coordinates from the top-left and bottom-right corner coordinates stored inside this GeoTiff file.`n(top-right and bottom-left coordinates are ignored and files with a rotated or skewed fit may not line up 100`% correctly)`n`nLoad coordinates from this GeoTiff file?
		; msgbox % tifnorth1 " = " tifnorth2 "`n" tifsouth1 " = " tifsouth2 "`n" tifwest1 " = " tifwest2 "`n" tifeast1 " = " tifeast2
		; If (tifnorth1 == tifnorth2 and tifsouth1 == tifsouth2 and tifwest1 == tifwest2 and tifeast1 == tifeast2)	; perfect match
			; MsgBox, 4, Load coordinates from GeoTiff file?, GoogleEarthTiler can read the north/south/east/west coordinates from the coordinates stored inside this GeoTiff file.`n`nLoad coordinates from this GeoTiff file?
		; Else
			; MsgBox, 4, Load coordinates from GeoTiff file?, GoogleEarthTiler can read the north/south/east/west coordinates from the top-left and bottom-right corner coordinates stored inside this GeoTiff file.`n`nWarning: The top-right and bottom-left coordinates will be ignored.`n(this file appears to be rotated and may not line up 100`% correctly)`n`nLoad coordinates from this GeoTiff file?
		IfMsgBox Yes
		{
			GuiControl,, LongitudeNorth, %tifnorth1%
			GuiControl,, LongitudeSouth, %tifsouth1%
			GuiControl,, LatitudeWest, %tifwest1%
			GuiControl,, LatitudeEast, %tifeast1%
		}
	}
}

FolderBrowse:
  Gui +OwnDialogs
  GuiControlGet OutFolder, , OutFolder
  FileSelectFolder folder , *%OutFolder%, Options, Select folder to output images and kml files to:
  If InStr(FileExist(folder), "D") {
	OutFolder = %folder%
	GuiControl ,, OutFolder, %OutFolder%
  }
return

FolderOpen:
	Gui, Submit, NoHide
	IfNotExist, %OutFolder%
		FileCreateDir, %OutFolder%
	IfExist, %OutFolder%
		Run, %OutFolder%
return

KMLOpen:
	IfExist, %KMLfile%
		Run %KMLFile%
return

GuiDropFiles:
  Loop, parse, A_GuiEvent, `n
  {
	SelectedFile := A_LoopField
	Gosub OpenFile
	Break
  }
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
    SetTimer, RemoveToolTip, 8000
    return

    RemoveToolTip:
    SetTimer, RemoveToolTip, Off
    ToolTip
    return
}

reload:
  Reload
return

Debug:
  Gui 3:Destroy
  Gui 3:+Owner
  Gui 1:+Disabled
  Gui 3: Add, Button, gDebugOk Default w300 h20 ym+150 xm+150, OK
  Gui 3: Font,s8, Lucida Console
  Gui 3: Add, Edit, t42 vDebugEditfield +ReadOnly -Wrap -WantReturn W600 R12 xm ym
  Gui 3: Font
  GuiControl 3:, DebugEditfield, %GridListDebugInfo%  ; Put the text into the control.
  Gui 3: Show,, Debug Info
return

DebugOk:
3GuiClose:
3GuiEscape:
  Gui 1:-Disabled
  Gui 3:Destroy
return

OnTop:
  Menu, context, ToggleCheck, %A_ThisMenuItem%
  Winset, AlwaysOnTop, Toggle, A
return

GuiContextMenu:
  Menu, context, Show
return

GuiClose:
  SaveWinPos("GoogleEarthTiler")
  Gui, Submit, NoHide
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, OutFolder, %OutFolder%
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LongitudeNorth, %LongitudeNorth%
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LongitudeSouth, %LongitudeSouth%
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LatitudeWest, %LatitudeWest%
  RegWrite, REG_SZ, HKEY_CURRENT_USER, SOFTWARE\GoogleEarthTiler, LatitudeEast, %LatitudeEast%
ExitApp

About:
  Gui 2:Destroy
  Gui 2:+Owner
  Gui 1:+Disabled
  Gui 2:Font,Bold
  Gui 2:Add,Text,x+0 yp+10, Google Earth Tiler %version%
  Gui 2:Font
  Gui 2:Add,Text,xm yp+16, by David Tryse
  Gui 2:Add,Text,xm yp+22, A small program for creating high-resolution image overlays for Google Earth.
  Gui 2:Add,Text,xm yp+22, Input is a large image file and coordinates for where it should be located on the ground.
  Gui 2:Add,Text,xm yp+16, Output is a hierarchy of small image tiles of increasing resolution, and a KML file to load
  Gui 2:Add,Text,xm yp+16, only the images required based on the current Google Earth viewpoint.
  Gui 2:Add,Text,xm yp+16, This results in higher performance and lower bandwidth usage since only a small part of
  Gui 2:Add,Text,xm yp+16, the ground overlay image has to be downloaded and displayed at any time.
  Gui 2:Font,Underline
  Gui 2:Add,Text,xm yp+22, Options:
  Gui 2:Font,Norm Bold
  Gui 2:Add,Text,xm+5 yp+16, Tile Size:
;  Gui 2:Add,Text,xm+5 yp+16, Tile Grid:
  Gui 2:Add,Text,xm+5 yp+16, KML:
  Gui 2:Add,Text,xm+5 yp+16, Fade-in:
  Gui 2:Add,Text,xm+5 yp+64, Output Format:
  Gui 2:Font
  Gui 2:Add,Text,xp+55 yp-96, The size in pixels of each image output tile (bigger means fewer files).
;  Gui 2:Add,Text,xp yp+16, How many new images should be inside each image when zooming closer.
  Gui 2:Add,Text,xp-24 yp+16, Output KML as a single large file or as a hierarchy of small network-link files?
  Gui 2:Add,Text,xm+10 yp+32, Smooth/Instant - smooth uses transparency to fade in new images when zooming closer.
  Gui 2:Add,Text,xm+10 yp+16, Near/Far - How close you need to zoom in to see more detailed images.
  Gui 2:Add,Text,xm+10 yp+16, (Instant+Near has the best performance, while Smooth+Far looks better.)
  Gui 2:Add,Text,xm+92 yp+16, Use JPG (for smallest size) unless the input image has transparency.
  Gui 2:Font
  Gui 2:Add,Text,xm yp+22, License: GPLv2+
  Gui 2:Add,Text,xm yp+26, This program requires ImageMagick convert.exe/identify.exe:
  Gui 2:Font,CBlue Underline
  Gui 2:Add,Text,xm gwebIM yp+15, http://www.imagemagick.org
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
  Gui 2:Add,Button,gAboutOk Default w110 h80 yp-60 x330,&OK
  Gui 2:Show,,About: Google Earth Tiler
  Gui 2:+LastFound
  WinSet AlwaysOnTop
Return

webHome:
  Run, http://earth.tryse.net#programs,,UseErrorLevel
Return

webCode:
  Run, http://googleearth-autohotkey.googlecode.com,,UseErrorLevel
Return

webIM:
  Run, http://www.imagemagick.org/script/binary-releases.php#windows,,UseErrorLevel
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
