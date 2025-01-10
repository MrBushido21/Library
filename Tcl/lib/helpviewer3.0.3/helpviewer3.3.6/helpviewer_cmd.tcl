# -------------------------------------------------------------------------
# helpviewer_cmd.tcl
# -------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] googlemail.com
#     www.johann-oberdorfer.eu
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# 
# -------------------------------------------------------------------------
# Revision history:
# 17-01-21: Hans, Initial release
# -------------------------------------------------------------------------
# Purpose:
#   Implements required callback commands for the tkhtml 3.0 widget
# -------------------------------------------------------------------------

package require http

# to do:
# support for:
#   + hyperlinks within the same page ?
#   + search highligt (see tkhtml PDF documentation)
#   + frame frameset support


namespace eval HelpViewer {}


# This procedure is called when the user clicks on a hyperlink.
# See the "bind $base.h.h.x" below for the binding that invokes this
# procedure
#
proc HelpViewer::HrefBinding {hwidget x y} {
	variable HelpBaseDir
	
	set node_data [$hwidget node -index $x $y]

	if { [llength $node_data] >= 2 } {
		set node [lindex $node_data 0]
	} else {
		set node $node_data
	}
	
	# parent node is an <A> tag (maybe?)
	if { [catch {set node [$node parent]} ] == 0 } {
	
		if {[$node tag] == "a"} {
			set href [string trim [$node attr -default "" href]]

			# -unused- SetStatusMessage $href
			
			# follow link inside the page...
			# @@@ todo: doesn't work right now
			# if {$href == "#"} {
			#	LoadRef $hwidget $node 0
			# }
			
			if {$href ne "" && $href ne "#"} {
			
				# using $HelpBaseDir instead of  [$hwidget cget -html_basedir]
				# might cause the problem that links are *not* followed up,
				# if the files are organized within a hierarchical dir-tree (!) 
				
				set fname [file join [$hwidget cget -html_basedir] $href]

				if { [file exists $fname] } {
					# follow the link, if the file exists
					LoadFile $hwidget $fname

				} else {
					# ? -disabled for the moment- does not work...
					# LoadRef $hwidget $node 0
				}
			}
		}
	}
}

