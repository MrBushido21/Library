set script ""
if {![info exists ::env(TREECTRL_LIBRARY)]
    && [file exists [file join $dir treectrl.tcl]]} {
    append script "set ::treectrl_library \"$dir\"\n"
}
append script "load \"[file join $dir libtreectrl2.4.1[ info sharedlibextension]]\" treectrl"
package ifneeded treectrl 2.4.1 $script
