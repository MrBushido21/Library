#!/bin/sh
#\
exec wish "$0" ${1+"$@"}

##############################################################################
# ased.tcl -
#
# This is the startfile for
#
# ASED Tcl/Tk IDE Version 3.0
#
# Copyright (C) 1999-2004  Andreas Sievers andreas.sievers@t-online.de
#
# This program is free software, you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation, either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY, without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
##############################################################################

package require Tk

global ASEDsRootDir
global libDir
global installDir
global search_var_string search_option_icase search_option_area search_option_match search_option_blink
global EditorData
global clock_var
global textChanged
global conWindow
global langArray
global images

if {[namespace exists ::starkit]} {
	set ASEDsRootDir $::starkit::topdir
	eval [list set ASEDsRootDir [file normalize $ASEDsRootDir]]
	set installDir [file dirname $ASEDsRootDir]
	if {$tcl_platform(platform) eq "windows"} {
		append env(PATH) ";[file dirname $ASEDsRootDir]"
	} else {
		append env(PATH) ":[file dirname $ASEDsRootDir]"
	}
} else {
	if {[file type $argv0] eq "link"} {
		set ASEDsRootDir [file dirname [file readlink $argv0]]
	} else {
		set ASEDsRootDir [file dirname $argv0]
	}
	eval [list set ASEDsRootDir [file normalize $ASEDsRootDir]]
	set installDir $ASEDsRootDir
	if {$tcl_platform(platform) eq "windows"} {
		append env(PATH) ";$ASEDsRootDir;[file join $ASEDsRootDir tools binaries windows]"
	} else {
		append env(PATH) ":$ASEDsRootDir:[file join $ASEDsRootDir tools binaries linux]"
	}
}

if { [namespace exists ::starkit] } {
	set argc $::ASED::argc
	set argv $::ASED::argv
	set argv0 $::ASED::argv0
	if {([lindex $argv 0] eq "-x") || ([lindex $argv 0] eq "-x evalServer.tcl")} {
		set xmode 1
		switch -- [lindex $argv 0] {
			"-x evalServer.tcl" {
				source [file join $::starkit::topdir evalServer.tcl]
				if {$argc == 2} {
					set EditorData(options,serverPort) [lindex $argv 1]
				} else {
					set EditorData(options,serverPort) "9001"
					catch {source [file join ~ ased.cfg]}
				}
				initServer $EditorData(options,serverPort) 1
				update
				catch {wm iconify .}
				catch {wm protocol . WM_DELETE_WINDOW {exit}}
				vwait forever
				exit
			}
			"-x" {
				#execute mode
				set argv0 [lindex $argv 1]
				if {$argc > 2} {
					set argv [lrange $argv 2 end]
					incr argc -2
				} else {
					set argv ""
					set argc 0
				}
				source $argv0
			}
			default {
				# ignore
			}
		}
	} else {
		# normal execution of ASED
		set xmode 0
		set EditorData(starkit) 1
	}
} else {
	# no starkit
	set xmode 0
	set EditorData(starkit) 0
}


if {$xmode == 0} {

	# normal start of ASED
	set libDir [file join $ASEDsRootDir lib]
	set auto_path [linsert $auto_path 0 $libDir]

	package require BWidget
	Widget::theme 1

	# carry over options from ttk
	foreach {option value} [::ttk::style configure .] {
		switch -- $option {
			"-foreground"       {option add *NoteBook*foreground $value widgetDefault}
			"-background"       {option add *NoteBook*background $value widgetDefault}
			"-selectforeground" {option add *NoteBook*activeforeground $value widgetDefault}
			"-selectbackground" {option add *NoteBook*activebackground $value widgetDefault}
		}
	}
	# ---------------------------------------
	# ---------------------------------------

	Bitmap::get cut
	# this used for loading Bitmap namespace into the interpreter
	namespace eval Bitmap {
		lappend path [file join $ASEDsRootDir images]
	}

	foreach imgfile [glob -dir [file join [file dirname [info script]] images] *.png] {
		set images([file tail [file root $imgfile]]) [image create photo -file $imgfile]
	}

	# set EditorData(keywords) [info commands]
	package require -exact CText 3.0

	namespace eval Editor {
		variable initDone 0
		variable _wfont
		variable notebook
		variable list_notebook
		variable con_notebook
		variable pw1
		variable pw2
		variable procWindow
		variable markWindow
		variable mainframe
		variable status
		variable prgtext
		variable prgindic
		variable font
		variable font_name
		variable Font_var
		variable FontSize_var
		variable toolbar1  1
		variable toolbar2  1
		variable showConsoleWindow 1
		variable sortProcs 1
		variable showProc 1
		variable checkNestedProc 1
		variable showProcWindow 1
		variable search_var
		variable search_combo
		variable current
		variable last
		variable text_win
		variable index_counter 0
		variable index
		variable slaves
		variable startTime [clock seconds]
		variable options
		variable lineNo
		variable lineEntryCombo
		variable toolbarButtons
		variable searchResults
		variable procMarks
		variable treeMenu
		variable textMenu
		variable serverUp 0
		variable newFileCount 1
	}

	source [file join $ASEDsRootDir i18n.tcl]
	source [file join $ASEDsRootDir create.tcl]
	source [file join $ASEDsRootDir asedmain.tcl]
	source [file join $ASEDsRootDir editor.tcl]
	source [file join $ASEDsRootDir find.tcl]
	source [file join $ASEDsRootDir repl.tcl]
	source [file join $ASEDsRootDir asedcon.tcl]
	source [file join $ASEDsRootDir manager.tcl]
	source [file join $ASEDsRootDir tclparser.tcl]
	source [file join $ASEDsRootDir fifDialog.tcl]

	proc initASED {argc argv} {
		global tcl_platform
		global auto_path
		global EditorData
		global ASEDsRootDir

		lappend auto_path ..

		option add *TitleFrame.font {helvetica 11 bold italic}

		wm withdraw .
		wm title . "ASED Tcl/Tk-IDE"

		Editor::create

		after idle {
			wm deiconify .
			raise .
			focus .
			set Editor::initDone 1
		}
		if {$argc >= 1} {
			set cursor [. cget -cursor]
			. configure -cursor watch
			update
			foreach filename $argv {
				set file $filename
				eval [list set file [file normalize $filename]]
				if {[file exists $file]} {
					Editor::openFile $file
				} elseif {[file exists [file join $EditorData(options,workingDir) $file]]} {
					Editor::openFile [file join $EditorData(options,workingDir) $file]
				}
			}
			. configure -cursor $cursor
			update
		} else {
			if {$EditorData(options,restoreSession)} {
				set cursor [. cget -cursor]
				foreach filename $EditorData(options,sessionList) {
					. configure -cursor watch
					update
					if {[file exists $filename]} {
						Editor::openFile $filename
					} elseif {[file exists [file join $EditorData(options,workingDir) $filename]]} {
						Editor::openFile [file join $EditorData(options,workingDir) $filename]
					}
				}
				update
				catch {
					NoteBook::raise $Editor::notebook $EditorData(options,recentPage)
					$Editor::current(text) mark set insert $EditorData(options,recentPos)
					$Editor::current(text) see insert
					Editor::selectObject 0
				} info
				. configure -cursor $cursor
				update
			}
		}
	}
	eval [list initASED $argc $argv]

	# scrolling BWidget's tree with middle mouse button
	# -------------------------------------------------
	bind $Editor::treeWindow.c <2> {
		set Priv(x) %x
		set Priv(y) %y
		$Editor::treeWindow configure -cursor "fleur"; update
	}

	bind $Editor::treeWindow.c <B2-ButtonRelease> {
		$Editor::treeWindow configure -cursor ""; update
	}

	bind $Editor::treeWindow.c <B2-Motion> {
		set scrollspeed 2
		set ydir 1
		catch {
			if { %y > $Priv(y) } {set ydir -1}
			%W yview scroll [expr {$ydir * $scrollspeed}] units
		}
	}
	# -------------------------------------------------
}
