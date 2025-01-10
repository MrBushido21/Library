# hvimages.tcl --
#
#   Copyright (C) 2009 Johann Oberdorfer <johann.oberdorfer@gmail.com>
#   This file is distributed under the BSD licence.
# ------------------------------------------------------------------------------

namespace eval ::hvimages:: {
	global hv_images
	
	variable version 0.1
	
	set thisDir  [file dirname [info script]]
	set imageDir [file join $thisDir "images"]
	set imageLib [file join $thisDir "ImageLib.tcl"] \
			
	# try to load image library file...
	if { [file exists $imageLib] } {
		
		source $imageLib
		array set ::hv_images [array get images]
		
	} else {
		
		proc LoadImages {imgdir {patterns {*.gif}}} {
			foreach p $patterns {
				foreach file [glob -directory $imgdir $p] {
					
					set img [file tail [file rootname $file]]
					if {![info exists images($img)]} {
						set images($img) [image create photo -file $file]
					}
				}
			}
			return [array get images]
		}
		
		array set ::hv_images [LoadImages $imageDir {"*.gif" "*.png"}]
	}
}

package provide hvimages $::hvimages::version
