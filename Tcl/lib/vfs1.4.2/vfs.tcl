# -*- tcl -*-

# Activate the binary and Tcl parts of the package, in the proper
# order.

# The location of the Tcl parts can be redirected via the environment
# variable VFS_LIBRARY. This is for use by testing of tclvfs without
# having to actually install the package. In that case the location of
# the binary part is redirected through the environment variable
# TCLLIBPATH (indirect modification of the auto_path). Not used here
# however, but by Tcl's package management code itself when searching
# for the package.

namespace eval ::vfs {
    variable self    [file dirname [info script]]
    variable redir   [info exists ::env(VFS_LIBRARY)]
    variable corezip [package vsatisfies [package provide Tcl] 8.6-]
}

if {[lsearch -exact $::auto_path $::vfs::self] < 0} {
    lappend ::auto_path $::vfs::self
}

if {[package vsatisfies [package provide Tcl] 9.0-]} {
    load [file join $::vfs::self tcl9vfs142t.dll]
} else {
    load [file join $::vfs::self vfs142t.dll]
}

if {$::vfs::redir} {
    set ::vfs::self $::env(VFS_LIBRARY)
}

source [file join $::vfs::self vfsUtils.tcl]

if {$::vfs::corezip} {
    source [file join $::vfs::self vfslib.tcl]
}

unset ::vfs::self ::vfs::redir ::vfs::corezip
