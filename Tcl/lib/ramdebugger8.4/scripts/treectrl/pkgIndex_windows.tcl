if {[catch {package require Tcl 8.5}]} return
set script "set ::treectrl_library \"$dir\"\n"

if { "$::tcl_platform(machine)" == "amd64"} {
    append script "load \"[file join $dir treectrl241_64.dll]\" treectrl"
    package ifneeded treectrl 2.4.1 $script
} else {   
    append script "load \"[file join $dir treectrl241_32.dll]\" treectrl"
    package ifneeded treectrl 2.4.1 $script
}
package ifneeded treectrl 2.4.1 $script

