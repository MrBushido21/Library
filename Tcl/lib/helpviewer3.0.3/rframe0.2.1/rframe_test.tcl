set dir [file dirname [info script]]
lappend auto_path [file join $dir "."]

package require Tk
package require tile
package require rframe


# -------------------------------------------------------------------------
# test
# -------------------------------------------------------------------------

proc main {} {
	
	# -- only required for the demo code
	proc ::rframe::GetTTKOption {optName} {
		set optVal ""
		foreach {opt val} [::ttk::style configure .] {
			if {$opt eq $optName } {
				set optVal $val
				break
			}
		}
		return $optVal
	}
	
	
	wm withdraw .
	set t [toplevel .test]
	wm geometry $t "200x300"
	
	set f [ttk::frame $t.status]
	pack $f -side bottom -fill x
	
	ttk::label $f.l -text "RoundedFrame test..."
	pack $f.l -side bottom -fill x
	
	set f [ttk::frame $t.main]
	pack $f -side top -fill both -expand true
	
	set rf [::rframe::rframe $f.rf]
	pack $rf -fill both -expand true
	
	text $rf.t \
			-relief flat -bd 0 \
			-highlightthickness 0 \
			-bg "white"
			
	# -bg #DFECFF" ;# [::rframe::GetTTKOption "-background"]
	
	pack $rf.t -fill both -expand true
	
	
	bind $rf.t <FocusIn>  "$f.rf state focus"
	bind $rf.t <FocusOut> "$f.rf state !focus"
}


main


# -- unused right now
# save base64 encoded gif's to file
# proc ::rframe::SaveImage {imgName fileName} {
#    variable wLocals
#    $imgName write -format "gif" [file join $wLocals(imgDir) $fileName]
# }
