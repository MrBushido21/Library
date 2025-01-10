if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded tdjson 0.1 [list load [file join $dir tcl9tdjson01t.dll]] 
} else { 
package ifneeded tdjson 0.1 [list load [file join $dir tdjson01t.dll]] 
} 
