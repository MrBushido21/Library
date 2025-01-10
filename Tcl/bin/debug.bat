::set dos {
@set PATH=C:\Tcl\bin;%PATH%
@wish86t.exe %0 %*
@exit
}

if {[catch {
    package require debugger
    debugger::init $argv {}
} err]} {
    set f [toplevel .init_error]
    set l [label $f.label -text "Startup Error"]
    set t [text $f.text -width 50 -height 30]
    $t insert end $errorInfo
    pack $f.text

    if {$::tcl_platform(platform) == "windows"} {
	console show
    }
}
