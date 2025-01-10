if {[catch {
    package require starkit
    if {[starkit::startup] eq "sourced"} { return } }]} {

    namespace eval ::starkit {
	if {[set this [info script]] eq ""} {
	    set this [info nameofexecutable]
	}
	variable topdir [file normalize [file dirname $this]]
    }
}

namespace eval ASED {
    set ::ASED::argc $argc
    set ::ASED::argv $argv
    set ::ASED::argv0 $argv0
}

set auto_path [linsert $auto_path 0 [file join $::starkit::topdir "lib"]]

encoding system utf-8

package require Tk

source [file join $starkit::topdir ased.tcl]
