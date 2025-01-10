# Tcl package index file, version 1.1
# This file invokes the
# "package ifneeded" command to set up package-related
# information so that packages will be loaded automatically
# in response to "package require" commands.  When this
# script is sourced, the variable $dir must contain the
# full path name of this file's directory.

package ifneeded html3widget 0.2.1 [list source [file join $dir html3widget.tcl]]
