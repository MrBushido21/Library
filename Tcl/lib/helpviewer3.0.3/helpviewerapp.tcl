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

namespace eval helpviewerapp {
	variable this
	variable hwidget

	# ---------------------------------
	# initializing default settings
	# ---------------------------------
	set ini_defaults {
		{"hviewer_geometry" "800x500+150+150"}
		{"hviewer_font_scale" 1.0}
		{"mostrecent_0" "-"}
		{"mostrecent_1" "-"}
		{"mostrecent_2" "-"}
		{"mostrecent_3" "-"}
		{"mostrecent_4" "-"}
		{"mostrecent_5" "-"}
		{"mostrecent_6" "-"}
		{"mostrecent_7" "-"}
		{"mostrecent_8" "-"}
		{"mostrecent_9" "-"}
	}
	
	::savedefault::savedefault \
		$app(CFG_FILE) \
		$ini_defaults

	::savedefault::readsettings this
	# ---------------------------------
}


proc helpviewerapp::GetSortedArrayNames { {pattern "mostrecent"} } {
	variable this

	set namelist {}
	set idx [expr {[string length $pattern] -1}]

	foreach name [lsort -dictionary -increasing [array names this]] {
		if { [string range $name 0 $idx] == $pattern} {
			lappend namelist $name
		}
	}

	return $namelist
}


# note: make sure, the proc is error free
# as the procedure call is secured with catch, it would be otherwise
# hard to trace back the failure !

proc helpviewerapp::HelpViewerCloseCmd {} {
	#
	# optional command to be executed before the dialog gets closed
	# we use this declaration to read window geometry
	# and to set the associated checkbox variable
	#
	variable this
	
	set this(hviewer_geometry) [HelpViewer::getHelpViewerGeometry]
	set this(hviewer_font_scale) [HelpViewer::getHelpViewerScale]

	set ini_list {}

	lappend ini_list [list "hviewer_geometry" $this(hviewer_geometry)]
	lappend ini_list [list "hviewer_font_scale" $this(hviewer_font_scale)]


	# manage most recent file list...
	# -------------------------------

	# - create sorted list
	#   including all file/directory names
	set flist {}
	foreach name [GetSortedArrayNames] {
		lappend flist $this($name)
	}
	
	# - check if the current "most recent file" is different ...

	set mostrecentfile [HelpViewer::getMostRecentFile]
	set firstlistitem [lindex $flist 0]

	set idx [lsearch $flist $mostrecentfile]
	switch -- $idx {
		0 {
			# item is on the 1st position in the list:
			# - so, just keep the same list, as it was before...

			foreach name [GetSortedArrayNames] {
				lappend ini_list [list $name $this($name)]
			}
		}
		-1 {
			# add new item on top of the list:
			# - all remaining items follow,
			# - last item drop's off from the list!

			for {set cnt 0} {$cnt < [llength $flist] } {incr cnt} {

				set array_name "mostrecent_$cnt"
			
				if {$cnt == 0} {
					lappend ini_list [list $array_name $mostrecentfile]
				} else {
					set previous_name "mostrecent_[expr {$cnt -1}]"
					set previous_value $this($previous_name)
			
					lappend ini_list [list $array_name $previous_value]
				}
			}
		}
		default {

			# $idx > 0
			# item can be found in the list,
			# but is not the 1st element in the list:
			# - resort the list, so that the item is ontop of the list,
			# - rest of the content remains, but is re-arranged...
			set current_item [lindex $flist $idx]

			# add 1st item
			lappend ini_list [list "mostrecent_0" $current_item]

			set arr_idx 1
			for {set cnt 0} {$cnt <= [expr {[llength $flist] -1}] } {incr cnt} {

				set array_ini_name "mostrecent_${arr_idx}"
				set array_name "mostrecent_${cnt}"
				set array_value $this($array_name)
				
				# skipp item which is already inserted ontop of the list
				if {$cnt != $idx} {
					lappend ini_list [list $array_ini_name $array_value]
					incr arr_idx
				}
			}
		}
	}
	
	::savedefault::savesettings $ini_list
	::Cleanup_TEMP_for_win

	exit 0
}


proc helpviewerapp::get_mostrecentfiles {} {
	variable this

	set flist {}
	foreach name [GetSortedArrayNames] {
		set val $this($name)

		# only existing files or diretories are allowed...
		if { [file exists $val] && [file readable $val] } {
			lappend flist $val
		}
	}

	return $flist
}
	

proc helpviewerapp::helpviewerapp {} {
	variable this
	variable hwidget

	set most_recentfiles [get_mostrecentfiles]

	set fname \
		[getfileordirectory::getfileordirectory \
			-parent "" \
			-title  "Select File or Directory where to find your html documents:" \
			-mostrecentfiles $most_recentfiles]

	if {[file exists $fname] && [file readable $fname]} {

		set hwidget \
			[HelpViewer::HelpViewer $fname \
				-geometry $this(hviewer_geometry) \
				-title "$::app(TITLE) $::app(VERSION)" \
				-aboutcmd "[namespace current]::ShowAboutDlg" \
				-closecmd "[namespace current]::HelpViewerCloseCmd"]

		# restore previous font scale setting
		HelpViewer::setHelpViewerScale $this(hviewer_font_scale)

	} else {
		exit 0
	}

}