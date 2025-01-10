if {[catch {package require Tcl 8.5}]} return
set script "load \"[file join $dir shellicon23.dll]\" shellicon"
package ifneeded shellicon 2.3.2 $script
