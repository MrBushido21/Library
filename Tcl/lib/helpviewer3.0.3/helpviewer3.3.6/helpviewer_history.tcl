
# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------


namespace eval History {
	variable list ""
	variable pos
	variable menu
	
	proc Add { name } {
		variable list
		variable pos
		variable menu
		
		lappend list $name
		set pos [expr [llength $list]-1]
		if { $pos == 0 } {
			if { [info exists menu] && [winfo exists $menu] } {
				$menu entryconf Backward -state disabled
			}
		} else {
			if { [info exists menu] && [winfo exists $menu] } {
				$menu entryconf Backward -state normal
			}
		}
		if { [info exists menu] && [winfo exists $menu] } {
			$menu entryconf Forward -state disabled
		}
	}

	proc GoHome { hwidget } {
		variable menu
		
		if { [info exists menu] && [winfo exists $menu] } {
			$menu entryconf Backward -state disabled
		}
		if { [info exists menu] && [winfo exists $menu] } {
			$menu entryconf Forward -state normal
		}
		
		# HelpViewer::LoadRef $hwidget [file join $HelpViewer::HelpBaseDir "index.html"] 0
	
		set files [glob -nocomplain -dir [$hwidget cget -html_basedir] *]
		set ipos [lsearch -regexp $files {(?i)(index|contents|_toc)\.(htm|html)}]

		if { $ipos != -1 } {
			set name [lindex $files $ipos]
		} else {
			HelpViewer::ShowInfoMessage ">>> No index.html or content.html file available."
			return
		}
		
		HelpViewer::LoadRef $hwidget $name 0
	}

	proc GoBackward { w } {
		variable list
		variable pos
		variable menu
		
		incr pos -1
		if { $pos == 0 } {
			if { [info exists menu] && [winfo exists $menu] } {
				$menu entryconf Backward -state disabled
			}
		}
		if { [info exists menu] && [winfo exists $menu] } {
			$menu entryconf Forward -state normal
		}
		HelpViewer::LoadRef $w [lindex $list $pos] 0
	}

	proc GoForward { w } {
		variable list
		variable pos
		variable menu
		
		incr pos 1
		if { $pos == [expr [llength $list]-1] } {
			if { [info exists menu] && [winfo exists $menu] } {
				$menu entryconf Forward -state disabled
			}
		}
		if { [info exists menu] && [winfo exists $menu] } {
			$menu entryconf Backward -state normal
		}
		HelpViewer::LoadRef $w [lindex $list $pos] 0
	}
}

