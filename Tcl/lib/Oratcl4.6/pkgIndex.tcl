if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded Oratcl 4.6 [list load [file join $dir tcl9Oratcl46t.dll]] 
} else { 
package ifneeded Oratcl 4.6 [list load [file join $dir Oratcl46t.dll]] 
} 
