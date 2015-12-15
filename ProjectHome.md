This is a collection of tools for working with Google Earth, reading/modifying coordinates, converting between different coordinate formats, create ScreenOverlays and GroundOverlay image tiles, and geotag photos using Google Earth.

# Programs #

## Google Earth ScreenOverlay ##

A small program for adding screen overlay images to Google Earth.

> ![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthScreenOverlay1.02.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthScreenOverlay1.02.png)

> This is handy for adding legends and other images to Google Earth KML files, images that stay on a fixed spot on the screen as long as the KML is loaded. Once you click the "Show in Google Earth" button in the tool any new changes you make will automatically update the overlay in Google Earth, making it easy to preview changes. The pre-set positions in the tool are tuned to avoid adding images on top of the built-in Google Earth controls (time slider, tour control, navigation/compass).

Latest version: 1.03

**Download:** [GoogleEarthScreenOverlay.exe](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthScreenOverlay1.03.exe)


---


## Google Earth Tiler ##

A small program for creating high-resolution image overlays for Google Earth.

> ![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthTiler1.07.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthTiler1.07.png)

> Input is a large image file and coordinates for where it should be located on the ground.
> Output is a hierarchy of small image tiles of increasing resolution, and a KML file to load only the images required based on the current Google Earth viewpoint.
> This results in higher performance and lower bandwidth usage since only a small part of the ground overlay image has to be downloaded and displayed at any time.

Latest version: 1.08

**Download:** [GoogleEarthTiler.exe](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthTiler1.08.exe)

The program requires convert.exe and identify.exe from ImageMagick which can be downloaded (for free) from [http://www.imagemagick.org](http://www.imagemagick.org/script/binary-releases.php#windows)


---


## Google Earth Position ##

A tiny program for reading coordinates from the Google Earth client (or editing coordinates to make Google Earth fly to a new location).

> ![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPosition1.16.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPosition1.16.png)

> The Copy buttons are intended to be useful for pasting coordinates and LookAt parameters into a spreadsheet, for example when generating KML using [Google's Spreadsheet Mapper 2.0](http://earth.google.com/outreach/tutorial_mapper.html)

Latest version: 1.17

**Download:** [GoogleEarthPosition.exe](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPosition1.17.exe)

> ![http://googleearth-autohotkey.googlecode.com/files/view_info.png](http://googleearth-autohotkey.googlecode.com/files/view_info.png)

> The above Google Earth Position tool only runs on Windows, and [may not work](http://googlegeodevelopers.blogspot.com/2010/08/sunset-for-google-earth-com-api.html) in future Google Earth versions.
> This is a replacement KML file that should work with all OS.

**Download:** [view\_info.kml](http://googleearth-autohotkey.googlecode.com/files/view_info.kml)



---


## Google Earth PhotoTag ##

A small program for adding Exif GPS data to JPEG files and reading coordinates from the Google Earth client.

![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTag1.26.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTag1.26.png)

> With the Auto-Mode enabled any new file drag-and-dropped onto the PhotoTag window will automatically be tagged with the current coordinates from the Google Earth client.

Latest version: 1.27

**Download:** [GoogleEarthPhotoTag.exe](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTag1.27.exe)

The program requires the Exiv2.exe command line tool by Andreas Huggel which can be downloaded (for free) from http://www.exiv2.org/

> The options to read/write Exif GPS data can be added to the windows right-click menu for JPEG files (click on the button in the About: dialog to add these options into the registry).

> ![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTagMenu.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTagMenu.png)

> The program can write KML output for showing a collection of photos inside Google Earth, like in this screenshot:

> ![![](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthPhotoTagKML_s.jpg)](http://www.tryse.net/david/googleearth/GoogleEarthPhotoTagKML_b.jpg)

> To edit the style of the popup balloon edit the `*.PlacemarkStyle` files in the same directory as the executable. Any files with a `.PlacemarkStyle` extension will automatically show up on the **Placemark style** dropdown list in the PhotoTag program window.

> The program will include photo comments from descript.ion files or JPEG embedded comments in the placemark balloons. JPEG Comments or descriptions can also be edited in the PhotoTag GUI (configure which type to edit using the right-click menu; JPEG comments are stored inside the file itself so will stay with the file when you move/copy it, descript.ion comments are kept in a separate file and are faster to read/store, but not understood by all programs).


---


## Google Earth Hotkeys ##

A small program for configuring hotkeys to show and hide different layers within the Google Earth application.

> ![http://googleearth-autohotkey.googlecode.com/files/GoogleEarthHotkeys1.02.png](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthHotkeys1.02.png)

> For example, use F6 to show Borders, Roads and 3D Buildings, F8 to show all your favourite layers, and F7 to hide all layers. The program adds an icon to the Windows systray, click the icon (or press F12 inside Google Earth) to configure the hotkeys. It also adds a global hotkey (which works no matter which application is active) to launch or activate Google Earth; press the Win key + Shift + G.

> When configuring hotkeys, start a layer name with a minus sign to hide it. Separate multiple layers to show or hide with the pipe | character. Start the layer list with an equal sign = to toggle between hiding and showing each layer on the list.

Latest version: 1.03

**Download:** [GoogleEarthHotkeys.exe](http://googleearth-autohotkey.googlecode.com/files/GoogleEarthHotkeys1.03.exe)

(this program only works in GE 6.1 and earlier)


---


## LatLong Conversion ##

A tiny program for converting coordinates between Degree Minute Second and Decimal formats.

> ![http://googleearth-autohotkey.googlecode.com/files/LatLongConversion1.11.png](http://googleearth-autohotkey.googlecode.com/files/LatLongConversion1.11.png)

> The tool can handle the following DMS formats:
    * 8 deg 32' 54.73" South	119 deg 29' 28.98" East
    * 8°32'54.73"S, 119°29'28.98"E
    * 8:32:54S,119:29:28E
> Decimal coordinates are in the format:
    * -8.548333, 119.491383

Latest version: 1.12

**Download:** [LatLongConversion.exe](http://googleearth-autohotkey.googlecode.com/files/LatLongConversion1.12.exe)


---


# Source #

These programs are written in the AutoHotkey language (http://www.autohotkey.com)

The source code for the programs can be downloaded from the Google Code source tab. There is also a library file libGoogleEarth.ahk which includes the following functions:
  * **Converting Coordinates**
    * Deg2Dec() - convert from 8°32'54.73"S, 119°29'28.98"E into -8.548333, 119.491383
    * Dec2Deg() - vice versa
    * Dec2Rel() - convert into 0/1 55/1 5617/100, 78/1 36/1 2061/10 format (useful for raw Exif GPS data)
  * **Google Earth functions**
    * IsGErunning() - simple check to see if the Google Earth client is running
    * GetGEpos() - get the current Google Earth coordinates and LookAt camera info using the COM API
    * GetGEpoint() - get the current Google Earth coordinates and altitude using the COM API
    * SetGEpos() - fly the Google Earth client to a specific coordinate
    * FlyToPhoto() - fly the Google Earth client to the coordinate stored in a JPG file
    * GEtimePlay() - start playing timeslider animation (useful when recording movies as GE Pro hides time control)
    * GEtimePause() - stop playing timeslider animation
    * GEfeature() - show or hide layers within Google Earth
  * **JPEG Exif, Exif GPS, XMP tag and JPEG Comment functions**
    * GetPhotoLatLong() - read the Exif GPS Latitude/Longitude stored in a JPG file
    * GetPhotoLatLongAlt() - read the Exif GPS Latitude/Longitude/Altitude stored in a JPG file
    * SetPhotoLatLong() - write Exif GPS Latitude/Longitude data to a JPG file
    * SetPhotoLatLongAlt() - write Exif GPS Latitude/Longitude/Altitude data to a JPG file
    * ErasePhotoLatLong() - delete the Exif GPS Latitude/Longitude/Altitude data from a JPG file
    * GetExif() - read full Exif data from a JPG file
    * GetJPEGComment() - read JPEG embedded comment
    * SetJPEGComment() - write JPEG embedded comment
    * SetXmpTag() - read JPEG file XMP tags
    * GetXmpTag() - write JPEG file XMP tags
  * **Other**
    * ImageDim() - return image dimensions (uses ImageMagick identify.exe)
    * FileDescription() - read file description from descript.ion file
    * WriteFileDescription() - write file description to descript.ion file
    * captureOutput() - capture output from console command line (uses cmdret.dll if available)

The JPEG Exif functions require the Exiv2.exe command line tool by Andreas Huggel. It can be downloaded at http://www.exiv2.org/ (GPL 2+ license)

The Google Earth COM API functions requires the Embedded Windows Scripting and COM for Autohotkey library (ws4ahk.ahk) from http://www.autohotkey.net/~easycom/

Further information about the Google Earth COM API can be found here: http://earth.google.com/comapi/


---


_These programs are distributed without any warranty. The functions for writing to JPEG files can probably be considered safe as they rely the Exiv2 command line tool for file write access (and all writes in the PhotoTag program are verified by a read operation afterwards). However, do make sure there is a backup of all files before using these programs._