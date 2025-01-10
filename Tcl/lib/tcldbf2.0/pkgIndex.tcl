# -*- tcl -*-
# Tcl package index file, version 1.1
#
if {[package vsatisfies [package provide Tcl] 9.0-]} {
    package ifneeded tcldbf 2.0 \
	    [list load [file join $dir tcl9tcldbf20.dll] [string totitle tcldbf]]
} else {
    package ifneeded tcldbf 2.0 \
	    [list load [file join $dir tcldbf20t.dll] [string totitle tcldbf]]
}
if {[package vsatisfies [package provide Tcl] 9.0-]} {
    package ifneeded dbf 1.3.9 \
	    [list load [file join $dir tcl9tcldbf20.dll] [string totitle dbf]]
} else {
    package ifneeded dbf 1.3.9 \
	    [list load [file join $dir tcldbf20t.dll] [string totitle dbf]]
}

