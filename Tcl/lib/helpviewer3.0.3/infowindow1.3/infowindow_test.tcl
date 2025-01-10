# -------------------------------------------------------------------------
# (c) 2017, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------

set dir [file dirname [info script]]

# where to find contributed library packages
lappend auto_path [file join $dir "."]
lappend auto_path [file join $dir "../../00-lib"]
lappend auto_path [file join $dir "../../00-lib3"]
lappend auto_path [file join $dir "../../00-libbin"]

package require Tk
package require -exact Tkhtml 3.0

package require infowindow 1.1
package require Markdown
package require fileutil
package require html3widget


# here we go:

set w [toplevel .infowin_test]

wm withdraw .
wm geometry $w "200x300"
wm protocol $w WM_DELETE_WINDOW {exit 0}

# message can be written in markdown syntax and 'll be
# converted at runtime to valid html code,
# which is finally passed over to the html3widget ...

set msg ""

append msg "\n<center>"

append msg \
"
# Application XXX: <span class=\"label label-success\">Ver X.XX </span>

Author: J.Oberdorfer
<br>Homepage: <http://johann-oberdorfer.eu>

This program is made with love and distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

<strong>Tcl/Tk Version:</strong> $::tk_version

The following packages are currently in used:

"

# <span class=\"label label-success\"> </span>

set cnt 0
foreach pname [lsort -dictionary [package names]] {
	
	if {[catch {package present $pname} ver] == 0} {
		# puts "$pname : $ver"
	
		if {$cnt > 0} {append msg " / "}
		append msg "${pname} : `${ver}`"
		incr cnt
	}
}


append msg "\n<center>"

set num 2

switch -- $num {
	1 {
		::infowindow::infowindow $w  \
			"Welcome to my App" \
			-infostring "my_logo.gif \"Johann Oberdorfer\"" \
			-default no
	}
	2 {
		::infowindow::infowindow $w \
			$msg \
			-default yes
	}
}
