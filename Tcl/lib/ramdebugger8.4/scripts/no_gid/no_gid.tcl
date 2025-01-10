package provide no_gid 1.0

#provide for other packages and alternative implementation of procs that are needed in case of gid

if { [info commands _] == "" && [info procs _] == "" } {
    package require msgcat
    proc _ { args } {
        set ret [uplevel 1 ::msgcat::mc $args]
        regexp {(.*)#C#(.*)} $ret {} ret
        return $ret
    }
}

if { ![info exists ::acceleratorKey] } {
    if { [ tk windowingsystem] eq "aqua"} {
        set ::acceleratorKey Command
        set ::acceleratorText Command
    } else {
        set ::acceleratorKey Control
        set ::acceleratorText Ctrl
    }
}

if { [info procs InitWindow] == "" } {
    proc InitWindow { w title geomname {InitComm ""} { class ""} { OnlyPos 0 } {ontop 1} {nodestroy 0} } {
        package require Tk
        if { [winfo exists $w] } {
            destroy $w
        }
        toplevel $w
        wm title $w $title
        if { $::tcl_platform(platform) == "windows" } {
            wm attributes $w -toolwindow 1
        }
        bind $w <${::acceleratorKey}-w> [list destroy $w]
        if { $::tcl_platform(platform) == "windows" } {
            bind $w <${::acceleratorKey}-F4> [list destroy $w]
        }
        bind $w <Escape> [list destroy $w]
        return $w
    }
}
