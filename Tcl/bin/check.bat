::set dos {
@set PATH=C:\Tcl\bin;%PATH%
@tclsh86t.exe %0 %*
@exit
}

lappend auto_path {C:\Tcl\lib\checker1.4}

if {[string match -psn* [lindex $::argv 0]]} {
    # Strip Apple's option providing the Processor Serial Number to bundles.
    incr ::argc -1
    set  ::argv [lrange $::argv 1 end]
}

package require log
::log::lvSuppress debug

package require parser
package require cmdline
package require starkit

package require projectInfo
## Set some relatively FAKE the data the checker requires from
## projectInfo

set starkit::topdir {C:\Tcl\lib\checker1.4}

namespace eval ::projectInfo {
    variable baseTclVers [info tclversion]

    # The variable pcxPks is not required anymore, we directly glob
    # for the files (see configure.tcl, PcxSetup).

    variable pcxPdxDir      [file join [file dirname [file dirname $starkit::topdir]] lib]
    variable pcxPdxVar      TCLDEVKIT_LOCAL
    variable usersGuide     "the user manual"
    variable printCopyright 0
    variable productName    "TclDevKit Checker"
}
# empty procedure for now.
proc projectInfo::printCopyright {name {extra {}}} {}

###############################################################

package require pref::devkit ; # TDK preferences

pref::setGroupOrder [pref::devkit::init]

###############################################################
## Ask for the checker engine and initialize it.

package require checker
auto_load checker::check

###############################################################
# Register our information gathering procedure. This replaces
# the usual silent mode with a "print to stdout" procedure.

set ::message::displayProc ::message::displayTTY

###############################################################
# Process the commandline args.

set filesToCheck [checkerCmdline::init]

###############################################################
# load the pcx extension files

if {[configure::packageSetup] == 0} {
    exit 1
}

###############################################################
# Call the main routine that checks all the files.

analyzer::check $filesToCheck

# Dump the cross-reference database when x-ref mode was enabled.

if {$::configure::xref} {
    ::analyzer::dumpXref
    exit
} elseif {$::configure::packages} {
    ::analyzer::dumpPkg
}

# Return an error code if any of the messages generated were 
# error messages.

if {[::analyzer::getErrorCount] > 0} {
    exit 1
} else {
    exit
}

###############################################################
