# Tcl package index file, version 1.1
# This file is sourced either when an application starts up
# or by a "package unknown" script.  It invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.


package ifneeded helpviewer 3.0 \
" [list source [file join $dir helpviewer.tcl]]; \
  [list source [file join $dir helpviewer_search.tcl]]; \
  [list source [file join $dir helpviewer_history.tcl]]; \
  [list source [file join $dir helpviewer_cmd.tcl]]; \
  [list source [file join $dir helpviewer_bindings.tcl]]; \
"
