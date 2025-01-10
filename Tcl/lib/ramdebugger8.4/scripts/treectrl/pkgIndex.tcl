# Tcl package index file, version 1.0

global tcl_platform

if { $tcl_platform(platform) == "windows"} {
    source [ file join $dir pkgIndex_windows.tcl]
} else {
    source [ file join $dir pkgIndex_linux.tcl]
}