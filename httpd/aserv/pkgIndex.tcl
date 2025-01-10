# Tcl package index file, version 1.0

if { [file readable [file join $dir aserv.tbc]] } {
    package ifneeded Aserv 1.2 [list source [file join $dir aserv.tbc]]
    package ifneeded aserv 1.2 [list source [file join $dir aserv.tbc]]
} else {
    package ifneeded Aserv 1.2 [list source [file join $dir aserv.tcl]]
    package ifneeded aserv 1.2 [list source [file join $dir aserv.tcl]]
}
