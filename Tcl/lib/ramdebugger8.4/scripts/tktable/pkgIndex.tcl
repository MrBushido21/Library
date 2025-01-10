proc load_library_tktable  { dir basename version } {
    if { $::tcl_platform(os) == "Darwin"} {
	set library lib${basename}${version}[info sharedlibextension]
    } else {
	if { $::tcl_platform(pointerSize) == 8} {
	    set bits 64
	} else {
	    set bits 32
	}
	set library ${basename}_${bits}[info sharedlibextension]
    }
    load [file join $dir $library] $basename
}

if {[catch {package require Tcl 8.2}]} return

package ifneeded Tktable 2.10 [list load_library_tktable $dir Tktable 2.10]
