# ------------------------------------------------------------------------
# getfileordirectory_test.tcl ---
# ------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# ------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# ------------------------------------------------------------------------
# Purpose:
#  This file belongs to the getfileordirectory.tcl widget
# ------------------------------------------------------------------------

set dir [file dirname [info script]]

set auto_path [linsert $auto_path 0 [file join $dir "."]]
set auto_path [linsert $auto_path 0 [file join $dir ".."]]
set auto_path [linsert $auto_path 0 [file join $dir "../../00-lib3"]]
set auto_path [linsert $auto_path 0 [file join $dir "../../00-libbin"]]


# test-run ...

package require Tk
package require tile

# D&D support is optional
# note: for Androwish/undroidwish tkdnd is not supported!

catch { package require tkdnd }

package require rframe
package require getfileordirectory 0.1


# question:
# how to determine Androidwish / undroidwish ?
# set dnd_available 0
#
# if { [tk windowingsystem] == "x11" && $tcl_platform(platform) == "windows" } {
#	# most likely, we are on "undroidwish"
#	# where there is no tkdnd available ...
# } else {
#	 if {[catch {package require tkdnd}] == 0 } {
#		set dnd_available 1
#	 }
# }


wm withdraw .

if { $::tcl_platform(platform) == "windows"} {
	console show
	console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}
}

set initialdir $dir

set filetypes {
	{{Html Files} {.html .htm}}
	{{All Files} *}
}

set most_recentfiles_test {
	"R:/Projekte_SoftwareEntwicklung/03_HelpViewer_HTMLDocu"
	"C:/CodeByHans/Docu"
	"C:/CodeByHans/Docu/tkhtml3.0/tkhtml (n).html"
	"C:/CodeByHans/Docu/tablelist5.15/index.html"
	"C:/CodeByHans/Docu/BWidget1.9.10"
}


# use cases:
# in fact, when D&D is available the file and directory modes
# change by themselves based on what type is D&D'ed onto the dialog,
# just give it a try, then the explanation 'll be clear...

# ... this also means, setting the mode is only required,
# if there is no D&D available ...
set mode 0


switch -- $mode {
	0 {
		set rval [getfileordirectory::getfileordirectory \
			-parent      "" \
			-title       "Select File:" \
			-initialdir $initialdir \
			-filetypes   $filetypes \
			-selectmode "file" \
			-mostrecentfiles $most_recentfiles_test \
		]
	}
	1 - default {
		# default -selectmode is: "directory"

		set rval [getfileordirectory::getfileordirectory \
			-parent "" \
			-title  "Select File or Directory:" \
			-initialdir $initialdir \
			-mostrecentfiles $most_recentfiles_test \
		]
	}
}


puts "Selection return value is: \"$rval\""
