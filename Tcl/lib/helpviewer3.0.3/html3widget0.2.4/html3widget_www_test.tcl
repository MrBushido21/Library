# -----------------------------------------------------------------------------
# html3widget_test1.tcl ---
# -----------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------
# Purpose:
#  A TclOO class template to extend tablelist functionality.
#  Might be usefull as a starting point.
# -----------------------------------------------------------------------------

# for development: try to find autoscroll, etc ...
set dir [file normalize [file dirname [info script]]]

# where to find required packages...
set auto_path [linsert $auto_path 0 [file join $dir "."]]
set auto_path [linsert $auto_path 0 [file join $dir ".."]]
set auto_path [linsert $auto_path 0 [file join $dir "../../00-lib"]]

package require Tk
package require TclOO
package require -exact Tkhtml 3.0

# html3widget dependencies:
# replace http package with native Tkhtml functionality:
catch {package require http}

package require scrolledwidget
package require html3widget


# --------------------
# demo starts here ...
# --------------------
# catch {console show}

set w [toplevel .test]
wm withdraw .
wm title    $w "Test"
wm geometry $w "800x600"
wm minsize  $w 400 200
wm protocol $w WM_DELETE_WINDOW "exit 0"


set ft [ttk::frame $w.top]
pack $ft -padx 4 -pady 4 -side top -fill x

ttk::label $ft.lbl -text "Tkhtml-3.0 widget test!"
pack $ft.lbl -anchor center


set fb [ttk::labelframe $w.bottom -text "Browser window:"]
pack $fb -padx 4 -pady 4 -side bottom -fill both -expand true


# -----------------------------------------------
set html3 [html3widget::html3widget $fb.html3]
pack $html3 -side bottom -fill both -expand true
# -----------------------------------------------

# $html3 parseurl "http://localhost:1313/"
# $html3 parseurl "http://johann-oberdorfer.eu/"
# $html3 parseurl "http://wiki.tcl.tk/48198"
# $html3 parseurl "http://wiki.tcl.tk/48497"

$html3 parseurl "http://wiki.tcl.tk/48458"

# not tested so far ...

# bind $html3 <1> \
#	"focus $html3; $html3 hrefBinding %x %y"


bind all <Escape> {exit 0}


bind all <MouseWheel> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		catch {
			set ycomm [$w cget -yscrollcommand]
			if { $ycomm != "" } {
				$w yview scroll [expr int(-1*%D/36)] units
				break
			}
		}
		set w [winfo parent $w]
	}
}

