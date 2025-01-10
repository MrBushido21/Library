if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded tbcload 1.7.0 [list load [file join $dir tcl9tbcload170.dll]] 
} else { 
package ifneeded tbcload 1.7.0 [list load [file join $dir tbcload170t.dll]] 
} 
