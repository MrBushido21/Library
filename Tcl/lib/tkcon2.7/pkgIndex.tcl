# pkgIndex.tcl to use tkcon as a package via 'package require tkcon'
#
# 'tkcon show' will do all that is necessary to display tkcon
#
# Defaults to:
#  * the main interp as the "slave"
#  * hiding tkcon when you click in the titlebar [X]
#  * using '.tkcon' as the root toplevel
#  * not displaying itself at 'package require' time
#
# When you'd like to have tkcon embedded into your running wish, do
#
#  namespace eval ::tkcon {
#    set OPT(exec) {}
#    set OPT(root) .tkcon
#    set OPT(protocol) {tkcon hide}
#  }
#  package require tkcon
#  tkcon show
#  bind all <F9> {tkcon show}
#
package ifneeded tkcon 2.7 [list source [file join $dir tkcon.tcl]]
