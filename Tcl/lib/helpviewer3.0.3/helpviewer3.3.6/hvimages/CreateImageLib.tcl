# CreateImageLib.tcl ---
# -------------------------------------------------------------------------
# Purpose:
#   A utility script to create base64 multimedia encoded gif's
#   from a given image directory.
#
# Copyright(c) 2009,  Johann Oberdorfer
#                     mail-to: johann.oberdorfer [at] gmail.com
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
# -------------------------------------------------------------------------


lappend auto_path [file join [file dirname [info script]] ".."]
package require base64


namespace eval ::CreateImageLib:: {
  variable defaults
  
  # by default, take this sub-directory and image library file:
  set thisDir [file dirname [info script]]

  array set defaults [list \
    pattern  [list "*.gif" "*.png"] \
    imageDir [file join $thisDir "images"] \
    imageLib [file join $thisDir "ImageLib.tcl"] \
    imageArrayName "images" \
  ]
}


proc ::CreateImageLib::ConvertFile { fileName } {

  set fp [open $fileName "r"]
  fconfigure $fp -translation binary

  set data [read $fp [file size $fileName]]
  close $fp

  return [base64::encode $data]
}


proc ::CreateImageLib::CreateImageLib {} {
	variable defaults

	set fp [open $defaults(imageLib) "w"]
	puts $fp "# [file tail $defaults(imageLib)] ---"
	puts $fp "# Automatically created by: [file tail [info script]]\n"
  
	foreach p $defaults(pattern) {
		foreach fname [glob -nocomplain \
						[file join $defaults(imageDir) $p]] {

		if { [file isfile $fname] } {

			# assemble array name:
			set imageName $defaults(imageArrayName)
			append imageName "("
			append imageName [file rootname [file tail $fname]]
			append imageName ")"

			set imageData [ConvertFile $fname]

			puts $fp "set $imageName \[image create photo -data \{"
			puts $fp "$imageData\n\}\]"
		}
	}}

	close $fp
}


# here we go ...
::CreateImageLib::CreateImageLib
exit 0
