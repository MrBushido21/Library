# -----------------------------------------------------------------------------
# helpviewerapp_about.tcl ---
# -----------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] googlemail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------

namespace eval helpviewerapp {}


proc helpviewerapp::map_string {str} {
	return [string trim [string map {"_" "\\_"} $str]]
}


proc helpviewerapp::ShowAboutDlg {} {
	variable hwidget
	global app

	# introduction:
	# -------------
	
	set msg "
<center>
# $app(TITLE) <span class=\"label label-success\"> $app(VERSION) </span>

Author: J.Oberdorfer
<br>Homepage: <http://johann-oberdorfer.eu>

<span class=\"list-group-item\">
This program was made with love and distributed in the hope that it will be useful,
<br>but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY
or FITNESS FOR A PARTICULAR PURPOSE.
</span>

"
	# config settings (as a markdown table):
	# --------------------------------------

	# package info:
	append msg "\n\n## The application is driven by the following packages:"
	append msg "\n\n"

	# <span class=\"label label-success\"> </span>
	set cnt 0
	foreach pname [lsort -dictionary [package names]] {
	
		if {[catch {package present $pname} ver] == 0} {
			# puts "$pname : $ver"
	
			if {$cnt > 0} {append msg " / "}
			append msg "[map_string $pname] : `${ver}`"
			incr cnt
		}
	}

	# kbd short codes:
	# ----------------

	append msg "\n\n## Keyboard short codes:"
	append msg "\n\n"
	append msg "\n\n<kbd> Ctrl F </kbd> : Open helpviewer's search function."
	append msg "\n\n<kbd> Ctrl + </kbd> : Zoom (+) font size of helpviewerapp."
	append msg "\n\n<kbd> Ctrl - </kbd> : Zoom (-) font size of helpviewerapp."
	
	# final html tag
	append msg "\n</center>"

	::infowindow::infowindow $hwidget $msg -default yes

}
