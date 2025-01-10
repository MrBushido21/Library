# -----------------------------------------------------------------------------
# html3widget_test.tcl ---
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


# font metrics
#    -forcefontmetrics "Force CSS Font Metrics" \
#    -fonttable        [list 8 9 10 11 13 15 17]

# set fonttable [list \
#		{7 8 9 10 12 14 16}    "Normal"            \
#		{8 9 10 11 13 15 17}   "Medium"            \
#		{9 10 11 12 14 16 18}  "Large"             \
#		{11 12 13 14 16 18 20} "Very Large"        \
#		{13 14 15 16 18 20 22} "Extra Large"       \
#		{15 16 17 18 20 22 24} "Recklessly Large"  \
#	]


# --------------------
# demo starts here ...
# --------------------
if {[set showconsole 1]} {
	catch {
		console show
		console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}
	}
}

set w [toplevel .test]
wm withdraw .
wm title    $w "Test"
wm geometry $w "800x600"
# wm minsize  $w 400 200
wm protocol $w WM_DELETE_WINDOW "exit 0"


set ft [ttk::frame $w.top]
pack $ft -padx 4 -pady 4 -side top -fill x

ttk::label $ft.lbl -text "Tkhtml-3.0 widget test!"
pack $ft.lbl -anchor center


set fb [ttk::labelframe $w.bottom -text "Browser:"]
pack $fb -padx 4 -pady 4 -side bottom -fill both -expand true

# -----------------------------------------------
set html3 [html3widget::html3widget $fb.html3]
pack $html3 -side bottom -fill both -expand true
# -----------------------------------------------


# set html_file [file join $dir "demo_doc/tkhtml.html"]
# set html_file [file join $dir "demo_doc/index.html"]
set html_file [file join $dir "demo_doc/tkhtml_doc.html"]

$html3 parsefile $html_file

$html3 showSearchWidget


# not tested so far ...

# bind $html3 <1> \
#	"focus $html3; $html3 hrefBinding %x %y"


bind all <Escape> {exit 0}


# --------
# bindings
# --------

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


bind all <Prior> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		if {[winfo class $w] == "html3widget"} {
			$w yview scroll -1000 units
			return
		}
		set w [winfo parent $w]
	}
}

bind all <Next> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		if {[winfo class $w] == "html3widget"} {
			$w yview scroll 1000 units
			return
		}
		set w [winfo parent $w]
	}
}


bind all <KeyPress-Up> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		if {[winfo class $w] == "html3widget"} {
			$w yview scroll -2 units
			return
		}
		set w [winfo parent $w]
	}
}

bind all <KeyPress-Down> {
	set w %W
	while { $w != [winfo toplevel $w] } {
		if {[winfo class $w] == "html3widget"} {
			$w yview scroll 2 units
			return
		}
		set w [winfo parent $w]
	}
}

