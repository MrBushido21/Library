if {[package vsatisfies [package provide Tcl] 9.0-]} { 
package ifneeded xbasetcl 2.1 [list load [file join $dir tcl9xbasetcl21t.dll]] 
} else { 
package ifneeded xbasetcl 2.1 [list load [file join $dir xbasetcl21t.dll]] 
} 
