# -------------------------------------------------------------------------
# helpviewer.tcl
# -------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] googlemail.com
#     www.johann-oberdorfer.eu
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# 
# Credits:
#  This software related on the the helpviewer application originally
#  created by Ramon Ribó (RAMSAN) ramsan@cimne.upc.es.
#  (http://gid.cimne.upc.es/ramsan) for his version of the 
#  Thank you.
#
# -------------------------------------------------------------------------
# Revision history:
# 16-08-10: Hans, Initial release
# 16-08-11: Hans, copy "externals" down to the docu directory
#                 (as the template files creates some references
#                 in the html header / footer sections) ...
# -------------------------------------------------------------------------
# Note: chrome browser currently is hard coded
#       to-do: replace with internal tkhtml help browser
# -------------------------------------------------------------------------

package provide helpviewer 3.0


# lappend auto_path [file dirname [info script]]

set dir [file dirname [info script]]
lappend auto_path [file join $dir "hvimages"]

# requiring exactly 2.0 to avoid getting the one from Activestate
package require Tkhtml 3
#package require -exact Tkhtml 3.0

package require BWidget 1.9
#package require -exact BWidget 1.9.10
#package require BWidget_patch
	Widget::theme 1

package require fileutil
package require hvimages
package require html3widget


# packages are optional...
catch {	package require Pan }
catch {	package getfileordirectory }


if { [info command tkTabToWindow] == "" } {
	proc tkTabToWindow {w} {
		focus $w
		after 100 {
			set w [focus]
			if {[string equal [winfo class $w] Entry]} {
				$w selection range 0 end
				$w icursor end
			}
		}
	}
}

# -----------------------------------------------------------------------------
# -----------------------------------------------------------------------------

namespace eval HelpViewer {
	
	variable HelpBaseDir
	variable LastFileList
	variable oldpos
	variable sash_status
	
	set sash_status 1

	# These images are used in place of GIFs or of form elements
	#
	if { [lsearch [image names] smgray] == -1 } {
		
		image create photo smgray -data {
			R0lGODdhOAAYAPAAALi4uAAAACwAAAAAOAAYAAACI4SPqcvtD6OctNqLs968+w+G4kiW5omm
			6sq27gvH8kzX9m0VADv/
		}
		image create photo nogifbig -data {
			R0lGODdhJAAkAPEAAACQkADQ0PgAAAAAACwAAAAAJAAkAAACmISPqcsQD6OcdJqKM71PeK15
			AsSJH0iZY1CqqKSurfsGsex08XuTuU7L9HywHWZILAaVJssvgoREk5PolFo1XrHZ29IZ8oo0
			HKEYVDYbyc/jFhz2otvdcyZdF68qeKh2DZd3AtS0QWcDSDgWKJXY+MXS9qY4+JA2+Vho+YPp
			FzSjiTIEWslDQ1rDhPOY2sXVOgeb2kBbu1AAADv/
		}
		image create photo nogifsm -data {
			R0lGODdhEAAQAPEAAACQkADQ0PgAAAAAACwAAAAAEAAQAAACNISPacHtD4IQz80QJ60as25d
			3idKZdR0IIOm2ta0Lhw/Lz2S1JqvK8ozbTKlEIVYceWSjwIAO///
		}
	}
	
	if { [lsearch [image names] appbook16] == -1 } {
		
		image create photo appbook16 -data {
			R0lGODlhEAAQAIQAAPwCBAQCBDyKhDSChGSinFSWlEySjCx+fHSqrGSipESO
			jCR6dKTGxISytIy6vFSalBxydAQeHHyurAxubARmZCR+fBx2dDyKjPz+/MzK
			zLTS1IyOjAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAAVkICCOZGmK
			QXCWqTCoa0oUxnDAZIrsSaEMCxwgwGggHI3E47eA4AKRogQxcy0mFFhgEW3M
			CoOKBZsdUrhFxSUMyT7P3bAlhcnk4BoHvb4RBuABGHwpJn+BGX1CLAGJKzmK
			jpF+IQAh/mhDcmVhdGVkIGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9uIDIuNQ0K
			qSBEZXZlbENvciAxOTk3LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2ZWQuDQpo
			dHRwOi8vd3d3LmRldmVsY29yLmNvbQA7
		}
		image create photo appbookopen16 -data {
			R0lGODlhEAAQAIUAAPwCBAQCBExCNGSenHRmVCwqJPTq1GxeTHRqXPz+/Dwy
			JPTq3Ny+lOzexPzy5HRuVFSWlNzClPTexIR2ZOzevPz29AxqbPz6/IR+ZDyK
			jPTy5IyCZPz27ESOjJySfDSGhPTm1PTizJSKdDSChNzWxMS2nIR6ZKyijNzO
			rOzWtIx+bLSifNTGrMy6lIx+ZCRWRAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAAae
			QEAAQCwWBYJiYEAoGAFIw0E5QCScAIVikUgQqNargtFwdB9KSDhxiEjMiUlg
			HlB3E48IpdKdLCxzEAQJFxUTblwJGH9zGQgVGhUbbhxdG4wBHQQaCwaTb10e
			mB8EBiAhInp8CSKYIw8kDRSfDiUmJ4xCIxMoKSoRJRMrJyy5uhMtLisTLCQk
			C8bHGBMj1daARgEjLyN03kPZc09FfkEAIf5oQ3JlYXRlZCBieSBCTVBUb0dJ
			RiBQcm8gdmVyc2lvbiAyLjUNCqkgRGV2ZWxDb3IgMTk5NywxOTk4LiBBbGwg
			cmlnaHRzIHJlc2VydmVkLg0KaHR0cDovL3d3dy5kZXZlbGNvci5jb20AOw==
		}
		image create photo filedocument16 -data {
			R0lGODlhEAAQAIUAAPwCBFxaXNze3Ly2rJSWjPz+/Ozq7GxqbJyanPT29HRy
			dMzOzDQyNIyKjERCROTi3Pz69PTy7Pzy7PTu5Ozm3LyqlJyWlJSSjJSOhOzi
			1LyulPz27PTq3PTm1OzezLyqjIyKhJSKfOzaxPz29OzizLyidIyGdIyCdOTO
			pLymhOzavOTStMTCtMS+rMS6pMSynMSulLyedAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAAaQ
			QIAQECgajcNkQMBkDgKEQFK4LFgLhkMBIVUKroWEYlEgMLxbBKLQUBwc52Hg
			AQ4LBo049atWQyIPA3pEdFcQEhMUFYNVagQWFxgZGoxfYRsTHB0eH5UJCJAY
			ICEinUoPIxIcHCQkIiIllQYEGCEhJicoKYwPmiQeKisrKLFKLCwtLi8wHyUl
			MYwM0tPUDH5BACH+aENyZWF0ZWQgYnkgQk1QVG9HSUYgUHJvIHZlcnNpb24g
			Mi41DQqpIERldmVsQ29yIDE5OTcsMTk5OC4gQWxsIHJpZ2h0cyByZXNlcnZl
			ZC4NCmh0dHA6Ly93d3cuZGV2ZWxjb3IuY29tADs=
		}
		image create photo viewmag16 -data {
			R0lGODlhEAAQAIUAAPwCBCQmJDw+PAwODAQCBMza3NTm5MTW1HyChOTy9Mzq
			7Kze5Kzm7OT29Oz6/Nzy9Lzu7JTW3GTCzLza3NTy9Nz29Ize7HTGzHzK1AwK
			DMTq7Kzq9JTi7HTW5HzGzMzu9KzS1IzW5Iza5FTK1ESyvLTa3HTK1GzGzGzG
			1DyqtIzK1AT+/AQGBATCxHRydMTCxAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
			AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAACH5BAEAAAAALAAAAAAQABAAAAZ8
			QIAQEBAMhkikgFAwHAiC5FCASCQUCwYiKiU0HA9IRAIhSAcTSuXBsFwwk0wy
			YNBANpyOxPMxIzMgCyEiHSMkGCV+SAQQJicoJCllUgBUECEeKhAIBCuUSxMK
			IFArBIpJBCxmLQQuL6eUAFCusJSzr7GLArS5Q7O1tmZ+QQAh/mhDcmVhdGVk
			IGJ5IEJNUFRvR0lGIFBybyB2ZXJzaW9uIDIuNQ0KqSBEZXZlbENvciAxOTk3
			LDE5OTguIEFsbCByaWdodHMgcmVzZXJ2ZWQuDQpodHRwOi8vd3d3LmRldmVs
			Y29yLmNvbQA7
		}
		
	}
}


proc HelpViewer::GiveLastFile { w } {
	variable LastFileList
	set retval ""
	catch {
		set w [winfo toplevel $w]
		set retval $LastFileList($w)
	}
	return $retval
}

proc HelpViewer::EnterLastFile { w file } {
	variable LastFileList
	set w [winfo toplevel $w]
	set LastFileList($w) $file
}


proc HelpViewer::LoadRef { w new { enterinhistory 1 } } {
	global tcl_platform
	
	if { [regexp {http:/localhost/cgi-bin/man/man2html\?(\w+)\+(\w+)} $new {} sec word] } {
		SearchManHelpFor $w $word $sec
		return
	} elseif { $new != "" && [regexp {[a-zA-Z]+[a-zA-Z]:.*} $new] } {

		regexp {http:/.*} $new url
		
		if { [regexp {:/[^/]} $url] } {
			regsub {:/} $url {://} url
		}
		
		if { $tcl_platform(platform) != "windows"} {
			set comm [auto_execok konqueror]
			if { $comm == "" } {
				set comm [auto_execok netscape]
			}
			if { $comm == "" } {
				tk_messageBox -icon warning -message \
						"Check url: $url in your web browser." -type ok
			} else {
				exec $comm $url &
			}
		} else {

			global env
			if {[file exists [file join $env(ProgramFiles) "internet explorer" iexplore.exe]]} {
				exec [file join $env(ProgramFiles) "internet explorer" iexplore.exe] $url &
			} else  {
				tk_messageBox -icon warning -message \
						"Check url: $url in your web browser." -type ok
			}
		}
		return
	}
	
	if {$new!=""} {
		set LastFile [GiveLastFile $w]
		if { [string match \#* [file tail $new]] } {
			set new $LastFile[file tail $new]
		}
		set pattern $LastFile#
		set len [string length $pattern]
		incr len -1
		if {[string range $new 0 $len]==$pattern} {
			incr len
			$w yview [string range $new $len end]
			if { $enterinhistory } {
				History::Add $new
			}
		} elseif { [regexp {(.*)\#(.*)} $new {} file tag] } {
			LoadFile $w $file $enterinhistory $tag
		} else {
			LoadFile $w $new $enterinhistory
		}
	}
}

proc HelpViewer::Load { w } {
	global lastDir

	set filetypes {
		{{Html Files} {.html .htm}}
		{{All Files} *}
	}
	set f [tk_getOpenFile -initialdir $lastDir -filetypes $filetypes]
	
	if {$f != ""} {
		set lastDir [file dirname $f]
		LoadFile $w $f
	}
}

# Clear the screen.
#
proc HelpViewer::ClearHtmlWidget { } {
	variable hwidget

	# hiding the search widget automatically
	# clears all search tags in the html widget as well
	$hwidget hideSearchWidget
	$hwidget reset
}


proc HelpViewer::ReadFile {name} {
	#
	# read html file and try to detect charset
	# return value is a string holding all the html stuff
	#
	if { [file dirname $name] == "." } {
		set name [file tail $name]
	}
	if {[catch {open $name r} fp]} {
		tk_messageBox -icon error -message $fp -type ok
		return {}
	} else {
		fconfigure $fp -translation binary
		set r [read $fp [file size $name]]
		close $fp
		
		# attempt to detect charset="UTF-8" !

		if { [regexp {(?i)<meta\s+[^>]*charset=utf-8[^>]*>} $r] ||
			 [string first "charset=utf-8" [string tolower $r]] != -1 ||
			 [string first "charset=\"utf-8\"" [string tolower $r]] != -1  } {

			set fp [open $name r]
			fconfigure $fp -encoding utf-8
			set r [read $fp]
			close $fp
		}

		return $r
	}
}

# Load a file into the HTML widget
#
proc HelpViewer::LoadFile {hwidget name { enterinhistory 1 } { tag "" } } {
	variable HelpBaseDir
	global HelpPriv

	# note:
	# resetting the HelpBaseDir inside this proc
	# is not allowed - make sure to maintain this variable
	# in the caller procedure (!)...

	if { $name == "" } {
		return
	}

	if { [file isdir $name] } {
	
		set files [glob -nocomplain -dir $name *]
		set ipos [lsearch -regexp $files {(?i)(index|contents|_toc)\.(htm|html)}]

		if { $ipos != -1 } {
			set name [lindex $files $ipos]
		} else {
			return
		}
	}

	set html [ReadFile $name]

	if {$html == ""} {
		return
	}

	ClearHtmlWidget
	EnterLastFile $hwidget $name
	
	if { $enterinhistory } {
		if { $tag == "" } {
			History::Add $name
		} else {
			History::Add $name#$tag
		}
	}
	
	# actual html_basedir is *not* always equal to HelpBaseDir,
	# when using  $HelpBaseDir instead of [file dirname $name]
	# will cause the failure that there will be no images shown at all (!)...
	$hwidget configure -html_basedir [file dirname $name]
	$hwidget parse -final $html
		
	if { $tag != "" } {
		update idletasks
		$hwidget yview $tag
	}

	TryToSelect $name
	variable SearchPos
	set SearchPos ""
	
	SetMostRecentFileInfo $name
}


# Refresh the current file.
#
proc HelpViewer::Refresh {} {
	variable hwidget

	set LastFile [GiveLastFile $hwidget]
	if {![info exists LastFile] || ![winfo exists $hwidget] } return
	LoadFile $hwidget $LastFile 0
}

proc HelpViewer::ResolveUri { args } {
	return [file join [file dirname [lindex $args 0]] [lindex $args 1]]
}


proc HelpViewer::FillDir { tree node } {
	variable HelpBaseDir
	
	if { $node == "root" } {
		set dir $HelpBaseDir
	} else {
		set dir [lindex [$tree itemcget $node -data] 1]
	}
	
	set idxfolder 0
	set files ""
	foreach i [glob -nocomplain -dir $dir *] {
		lappend files [file tail $i]
	}
	foreach i [lsort -dictionary $files] {
		set fullpath [file join $dir $i]
		regsub {^[0-9]+} $i {} name
		regsub -all {\s} $fullpath _ item
		if { [file isdir $fullpath] } {

			# exclude special directories ...
			if { [string equal -nocase $i "images"] } { continue }
			if { [string equal -nocase $i "externals"] } { continue }
			if { [string equal -nocase $i "lib"] } { continue }

			$tree insert $idxfolder $node $item \
					-image appbook16 -text $name \
					-data [list folder $fullpath] -drawcross allways
			incr idxfolder
		} elseif { [string match .htm* [file ext $i]] } {
			set name [file root $i]
			$tree insert end $node $item \
					-image filedocument16 -text $name \
					-data [list file $fullpath]
		}
	}
}

proc HelpViewer::moddir { idx tree node } {
	variable HelpBaseDir
	
	if { $idx && [$tree itemcget $node -drawcross] == "allways" } {
		FillDir $tree $node
		$tree itemconfigure $node -drawcross auto
		
		if { [llength [$tree nodes $node]] } {
			$tree itemconfigure $node -image appbookopen16
		} else {
			$tree itemconfigure $node -image appbook16
		}
	} else {
		if { [lindex [$tree itemcget $node -data] 0] == "folder" } {
			switch $idx {
				0 { set img appbook16 }
				1 { set img appbookopen16 }
			}
			$tree itemconfigure $node -image $img
		}
	}
}


proc HelpViewer::KeyPress { a } {
	variable tree
	variable searchstring
	
	set node [$tree selection get]
	if { [llength $node] != 1 } { return }
	
	append searchstring $a
	after 300 [list set HelpViewer::searchstring ""]
	
	if { [$tree itemcget $node -open] == 1 && [llength [$tree nodes $node]] > 0 } {
		set parent $node
		set after 1
	} else {
		set parent [$tree parent $node]
		set after 0
	}
	
	foreach i [$tree nodes $parent] {
		if { !$after } {
			if { $i == $node } {
				if { [string length $HelpViewer::searchstring] > 1 } {
					set after 2
				} else {
					set after 1
				}
			}
		}
		if { $after == 2 && [string match -nocase $HelpViewer::searchstring* \
					[$tree itemcget $i -text]] } {
			$tree selection clear
			$tree selection set $i
			$tree see $i
			return
		}
		if { $after == 1 } { set after 2 }
	}
	foreach i [$tree nodes [$tree parent $node]] {
		if { $i == $node } { return }
		if { [string match -nocase $HelpViewer::searchstring* [$tree itemcget $i -text]] } {
			$tree selection clear
			$tree selection set $i
			$tree see $i
			return
		}
	}
}

proc HelpViewer::Select { tree num node } {
	variable hwidget
	
	if { $node == "" } {

		set node [$tree selection get]
		if { [llength $node] != 1 } { return }

	} elseif { ![$tree exists $node] } {
		return
	}
	
	if { $num >= 1 } {
		if { [$tree itemcget $node -open] == 0 } {
			$tree itemconfigure $node -open 1
			set idx 1
		} else {
			$tree itemconfigure $node -open 0
			set idx 0
		}
		moddir $idx $tree $node
		if { $num == 1 && $idx == 0 } {
			return
		}

		# set selection and ...
		# hans: bring current selection onto the screen

		$tree selection set $node
		$tree see $node

		if { [llength [$tree selection get]] == 1 } {
			set data [$tree itemcget [$tree selection get] -data]

			if { $num >= 1 && $num <= 2 } {
				LoadFile $hwidget [lindex $data 1]
			}
		}
		return
	}
}


proc HelpViewer::TryToSelect { name } {
	variable HelpBaseDir
	variable tree
	
	set nameL [file split $name]
	
	set level [llength [file split $HelpBaseDir]]
	set node root
	while 1 {
		set found 0
		foreach i [$tree nodes $node] {
			if { [lindex [$tree itemcget $i -data] 1] == [eval file join [lrange $nameL 0 $level]] } {
				set found 1
				break
			}
		}
		if { !$found } { return }
		if { [lindex [$tree itemcget $i -data] 0] == "folder" } {
			if { [$tree itemcget $i -open] == 0 } {
				$tree itemconfigure $i -open 1
			}
			moddir 1 $tree $i
		}
		
		if { $level == [llength $nameL]-1 } {
			Select $tree 3 $i
			return
		}
		set node $i
		incr level
	}
}


proc HelpViewer::CenterWindow {w wparent} {

    wm withdraw $w
    update idletasks

    set top [winfo toplevel [winfo parent $w]]
	set width [winfo reqwidth $w]
	set height [winfo reqheight $w]

	if { [wm state $top] == "withdrawn" } {
	    set x [expr [winfo screenwidth $top]/2-$width/2]
	    set y [expr [winfo screenheight $top]/2-$height/2]
	} else {
	    set x [expr [winfo x $top]+[winfo width $top]/2-$width/2]
	    set y [expr [winfo y $top]+[winfo height $top]/2-$height/2]
	}
	if { $x < 0 } { set x 0 }
	if { $y < 0 } { set y 0 }

	wm geom $w ${width}x${height}+${x}+$y
    wm deiconify $w
    update idletasks
    wm geom $w [wm geom $w]

    focus $w
}


proc HelpViewer::ExitCmd {{wbase ""}} {
	variable closecmd

	if {$closecmd != ""} {
		if { [catch { uplevel $closecmd } errmsg] != 0 } {

			set msg "Programmer's Error:"
			append msg "\nThe procedure $closecmd went wrong."
			append msg "\nError message is:"
			append msg "\n*** $errmsg ***"

			tk_messageBox -icon error -message $msg -type ok
		}
	}
	
	# exit 0,
	# works in stand alone mode,
	# but not possible, if the helpviewer is used within an application
	
	if {$wbase != "" && [winfo exists $wbase]} {
		destroy $wbase
	} else {
		exit 0
	}
}

proc HelpViewer::getTreeWidget {} {
	variable tree
	return $tree
}


proc HelpViewer::getTreeRootName {} {
	return "root"
}


proc HelpViewer::getHelpViewerScale {} {
	variable hwidget
	return [$hwidget fontScaleCmd "getscale"]
}

proc HelpViewer::setHelpViewerScale {scale} {
	variable hwidget
	$hwidget setscale $scale
}


# code taken from: http://wiki.tcl.tk/44272, Drawer Example
#
# A "Drawer" is a widget that slides in and out -- a pop-open task pane
# (reference BOOK About Face 4th edition pp 464).
# This is a simple example of an animated drawer using a paned window.


proc HelpViewer::movesash {pw inc limit} {

	if {![info exists pw] || ![winfo exists $pw] } { return }

	set sp [$pw sashpos 0]
	incr sp $inc
	
	if { ($inc < 0 && $sp < $limit) ||
		($inc > 0 && $sp > $limit) } {
		set sp $limit
		$pw sashpos 0 $sp
		return
	}
	$pw sashpos 0 $sp

	update idletasks
	
	after 10 [list [namespace current]::movesash $pw $inc $limit]
}

proc HelpViewer::doclose {pw w} {
	variable oldpos
	variable sash_frame
	variable sash_label
	variable sash_status

	if {![info exists pw] || ![winfo exists $pw] } { return }
	
	set sp [$pw sashpos 0]
	set oldpos $sp
	movesash $pw -40 12
	
	$sash_label configure -text "\u27eb"
	bind $sash_frame <ButtonRelease-1> [list [namespace current]::doopen $pw %W]
	bind $sash_label <ButtonRelease-1> [list [namespace current]::doopen $pw %W]

	set sash_status 0
}

proc HelpViewer::doopen {pw w} {
	variable oldpos
	variable sash_frame
	variable sash_label
	variable sash_status

	if {![info exists pw] || ![winfo exists $pw] } { return }
	
	movesash $pw 40 $oldpos

	$sash_label configure -text "\u27ea"
	bind $sash_frame <ButtonRelease-1> [list [namespace current]::doclose $pw %W]
	bind $sash_label <ButtonRelease-1> [list [namespace current]::doclose $pw %W]

	set sash_status $oldpos
}

proc HelpViewer::getSashPosition {} {
	variable sash_status
	return $sash_status
}

proc HelpViewer::getHelpViewerGeometry {} {
	variable base
	return [wm geometry $base]
}

proc HelpViewer::getMostRecentFile {} {
	variable mostrecent_file
	return $mostrecent_file
}


proc HelpViewer::setSashPosition {pos} {
	variable pw
	variable sash_frame
	variable oldpos

	if {![info exists pw] || ![winfo exists $pw] } { return }
	
	if {$pos == 0} {
		doclose $pw $sash_frame
	} else {
		set oldpos $pos
		doopen $pw $sash_frame
	}
}

proc HelpViewer::OpenFileOrDirectory {} {
	variable this_dialog_win
	variable hwidget
	variable HelpBaseDir
	variable tree
	variable mostrecent_file
	variable Index
	variable searchstring

	set initialdir [file dirname [info script]]

	set file_or_dir [getfileordirectory::getfileordirectory \
		-parent $this_dialog_win \
		-title  "Select File or Directory:" \
		-initialdir $initialdir \
	]
	
	# re-initializing the help viewer...
	
	if {$file_or_dir != ""} {
	
		# re-setting HelpBaseDir is required...

		if { [file isdirectory $file_or_dir] } {
			set HelpBaseDir $file_or_dir
		} else {
			set HelpBaseDir [file dirname $file_or_dir]
		}
		
		set mostrecent_file $file_or_dir
	
		# clear tree + html widgets...
		$tree delete [$tree nodes root]
		FillDir $tree root
		ClearHtmlWidget

		# clear search entries and everything related to
		# the search option, which might have been performed previously
		catch { unset Index }
		set searchstring ""
		SearchInAllHelp
		
		# and finally, load the new file or directory
		LoadFile $hwidget $file_or_dir
	}
}

# maintain entry widget's state and content

proc HelpViewer::SetMostRecentFileInfo {fileordir_name} {
	variable mostrecent_file_entry

	$mostrecent_file_entry configure -state normal
	$mostrecent_file_entry delete 0 end
	$mostrecent_file_entry insert 0 [string trim $fileordir_name]
	$mostrecent_file_entry configure -state disabled
}


proc HelpViewer::ShowInfoMessage {msg} {
	variable mostrecent_file_entry
	variable previous_info

	$mostrecent_file_entry configure -state normal

	# store previous content
	set previous_info [$mostrecent_file_entry get]
	
	$mostrecent_file_entry delete 0 end
	$mostrecent_file_entry insert 0 $msg
	$mostrecent_file_entry configure -state disabled

	after 3000 "[namespace current]::RestorePreviousMessage"
}

proc HelpViewer::RestorePreviousMessage {} {
	variable mostrecent_file_entry
	variable previous_info

	if { ![info exists previous_info] || [string trim $previous_info] == ""} {
		return
	}

	if { ![winfo exists $mostrecent_file_entry] } {
		return
	}

	$mostrecent_file_entry configure -state normal

	# only in case there is an info message availabe
	# user might have selected something else already...
	set msg  [$mostrecent_file_entry get]
	if { [string range $msg 0 2] == ">>>" } {
	
		$mostrecent_file_entry delete 0 end
		$mostrecent_file_entry insert 0 $previous_info
	}

	$mostrecent_file_entry configure -state disabled
}


# -unused-, todo: implement a popup in the html3widget
# which shows the actual link on hovering with the mouse over a href!...
# proc HelpViewer::SetStatusMessage {msg} {
#	variable status_msg_entry
#	$status_msg_entry configure -text [string trim $msg]
#}





# -----------------------------------------------------------------------------
# main dialog
# -----------------------------------------------------------------------------

proc HelpViewer::HelpViewer { file_or_dir args } {
	variable HelpBaseDir
	variable hwidget
	variable tree
	variable searchlistbox1
	variable searchlistbox2
	variable notebook
	variable closecmd
	variable pw
	variable sash_frame
	variable sash_label
	variable sash_status
	variable this_dialog_win
	variable tree
	variable base
	variable mostrecent_file
	variable mostrecent_file_entry
	# variable status_msg_entry

	global lastDir tcl_platform argv0
	
	set base ".help"
	set geom "800x600+150+150"
	set title ""
	set closecmd ""
	set aboutcmd ""
	set mostrecent_file $file_or_dir

	set idx 0
	while { $idx < [llength $args] } {
		set opt [lindex $args $idx]
		set val [lindex $args [expr {$idx +1}]]
		switch -exact -- $opt {
			"-base" {
				set base $val
			}
			"-geometry" {
				set geom $val
			}
			"-title" {
				set title $val
			}
			"-closecmd" {
				set closecmd $val
			}
			"-aboutcmd" {
				set aboutcmd $val
			}
			default {
				error "unknown option [lindex $args $idx]"
			}
		}
		incr idx 2
	}

	set this_dialog_win $base
	catch { destroy $base }
	
	if { [info procs InitWindow] != "" } {
		InitWindow $base $title PostHelpViewerWindowGeom
	} else {
		toplevel $base
		wm title $base $title
	}

	wm withdraw $base
	wm protocol $base WM_DELETE_WINDOW "[namespace current]::ExitCmd $base"

	# -unused-
	# set fstatus [ttk::frame $base.statusmsg -relief flat]
	# pack $fstatus -side bottom -fill x
	# ttk::label $fstatus.e -text ""
	# pack $fstatus.e -padx 5 -fill x -expand true
	# set status_msg_entry $fstatus.e

	
	#set pw [PanedWindow $base.pw \
	#			-activator button \
	#			-side top \
	#			-pad 5]

	set pw [ttk::panedwindow $base.pw \
				-orient "horizontal"]
				
	$pw add [set pane1 [ttk::frame $base.pane1]] ;# -weight 0
	$pw add [set pane2 [ttk::frame $base.pane2]] ;# -weight 1

	set sash_frame [ttk::frame $pane1.sep -width 10 -relief flat]
	pack $pane1.sep -padx 0 -pady 0 -side right -fill y -anchor e

	set sash_label [ttk::label $pane1.sep.c -text "\u27ea"]
	pack $pane1.sep.c -pady 20

	bind $sash_frame <ButtonRelease-1> [list [namespace current]::doclose $pw %W]
	bind $sash_label <ButtonRelease-1> [list [namespace current]::doclose $pw %W]

	NoteBook $pane1.nb \
		-homogeneous 1 \
		-bd 1 \
		-internalborderwidth 3 \
		-bg "#EDF3FE" \
		-activebackground "#EDF3FE" \
		-disabledforeground "#EDF3FE"

	pack $pane1.nb -padx 2 -side top -fill both -expand true
			
	set notebook $pane1.nb
	
	set f1 [$pane1.nb insert end tree -text "Contents" -image appbook16]
	
	set sw [ScrolledWindow $f1.lf -relief flat -borderwidth 0]
	pack $sw -fill both -expand yes
	
	set tree [Tree $sw.tree -bg white\
				-width 15 \
				-relief flat \
				-borderwidth 0 \
				-highlightthickness 0 \
				-redraw 1 \
				-deltay 18 \
				-bg "#EDF3FE" \
				-opencmd   "HelpViewer::moddir 1 $sw.tree" \
				-closecmd  "HelpViewer::moddir 0 $sw.tree"]

	$sw setwidget $tree
	
	# font metrics:
	set font [option get $tree font Font]

	if { $font == "" } {
		set font "TkDefaultFont"
	}

	catch {
		$tree configure -deltay [expr [font metrics $font -linespace]]
	}

	if { $::tcl_platform(platform) != "windows" } {
		$tree configure \
			-selectbackground "#48c96f" \
			-selectforeground white
	}
	$pane1.nb itemconfigure tree -raisecmd "focus $tree"

	if {[string equal "unix" $::tcl_platform(platform)]} {
		bind $tree.c <4> { %W yview scroll -5 units }
		bind $tree.c <5> { %W yview scroll 5 units }
	}

	$tree bindText  <ButtonPress-1>         "HelpViewer::Select $tree 1"
	$tree bindText  <Double-ButtonPress-1>  "HelpViewer::Select $tree 2"
	$tree bindImage <ButtonPress-1>         "HelpViewer::Select $tree 1"
	$tree bindImage <Double-ButtonPress-1>  "HelpViewer::Select $tree 2"
	$tree bindText  <Control-ButtonPress-1> "HelpViewer::Select $tree 3"
	$tree bindImage <Control-ButtonPress-1> "HelpViewer::Select $tree 3"
	$tree bindText  <Shift-ButtonPress-1>   "HelpViewer::Select $tree 4"
	$tree bindImage <Shift-ButtonPress-1>   "HelpViewer::Select $tree 4"

	# dirty trick...
	foreach i [bind $tree.c] {
		bind $tree.c $i "+[list after idle [list HelpViewer::Select $tree 0 {}]]"
	}
	bind $tree.c <Return> "HelpViewer::Select $tree 1 {}"
	bind $tree.c <KeyPress> "if \[string is wordchar -strict {%A}\] {HelpViewer::KeyPress %A}"
	bind $tree.c <Alt-KeyPress-Left> ""
	bind $tree.c <Alt-KeyPress-Right> ""
	bind $tree.c <Alt-KeyPress> { break }

	
	set f2 [$pane1.nb insert end search -text "Search" -image viewmag16]
	
	set fs [ttk::frame $f2.search]
	pack $fs -side top -fill x
	
	label $fs.l1 -text "S:" -bg "#EDF3FE"
	entry $fs.e1 -textvariable HelpViewer::searchstring -bg "#EDF3FE"

	pack $fs.l1 -side left
	pack $fs.e1 -side right -fill x -expand true
	
	$pane1.nb itemconfigure search -raisecmd "tkTabToWindow $fs.e1"

	bind $fs.e1 <Return> "focus $f2.lf1.lb; HelpViewer::SearchInAllHelp"
	
	set sw [ScrolledWindow $f2.lf1 -relief sunken]
	pack $sw -fill both -expand yes
	
	set searchlistbox1 \
			[listbox $f2.lf1.lb \
				-listvar HelpViewer::SearchFound \
				-bg "#EDF3FE" \
				-exportselection 0]

	$f2.lf1 setwidget $searchlistbox1

	bind $searchlistbox1 <FocusIn> "if { \[%W curselection\] == {} } { %W selection set 0 }"
	bind $searchlistbox1 <ButtonPress-1> "focus $f2.lf2.lb; HelpViewer::SearchInAllHelpL1; HelpViewer::SearchCmd"
	bind $searchlistbox1 <Return> "focus $f2.lf2.lb; HelpViewer::SearchInAllHelpL1; HelpViewer::SearchCmd"
	
	set sw [ScrolledWindow $f2.lf2 -relief sunken]
	pack $sw -fill both -expand yes
	
	set searchlistbox2 \
			[listbox $f2.lf2.lb \
				-listvar HelpViewer::SearchFound2 \
				-bg #EDF3FE \
				-exportselection 0]

	$f2.lf2 setwidget $searchlistbox2
	
	bind $searchlistbox2 <FocusIn> "if { \[%W curselection\] == {} } { %W selection set 0 }"
	bind $searchlistbox2 <ButtonPress-1> "HelpViewer::SearchInAllHelpL2; HelpViewer::SearchCmd"
	bind $searchlistbox2 <Return> "HelpViewer::SearchInAllHelpL2; HelpViewer::SearchCmd"
	
	set HelpViewer::SearchFound ""
	set HelpViewer::SearchFound2 ""

	$pane1.nb compute_size
	# add some extra margin for text widget
	$pane1.nb configure -width [expr {[$pane1.nb cget -width] +10}]
	$pane1.nb raise tree

	set sw [ScrolledWindow $pane2.lf -relief sunken -borderwidth 0]
	pack $sw -fill both -expand yes

	# ------------------------------
	# create html3widget
	# ------------------------------
	
	html3widget::html3widget $sw.h \
		-width 550 \
		-height 500

	set hwidget $sw.h
	$sw setwidget $hwidget

	
	bind [$hwidget get_htmlwidget] <1> \
		"+[namespace current]::HrefBinding $hwidget %x %y"

	frame $base.buts ;# -bg grey93

	# <<--
	Button $base.buts.b1 \
			-image $::hv_images(draw-arrow-back) \
			-command "History::GoBackward $hwidget" \
			-relief link \
			-helptext "Go Backward..."

	# -->>
	Button $base.buts.b2 \
			-image $::hv_images(draw-arrow-forward) \
			-command "History::GoForward $hwidget" \
			-relief link \
			-helptext "Go Forward..."

	# -bg grey93
	menubutton $base.buts.b3 -text "More..." \
			-fg DarkGrey -relief flat \
			-menu $base.buts.b3.m -activebackground grey93
	
	menu $base.buts.b3.m
	
	# file menu ...
	if { [catch { package require getfileordirectory }] == 0 } {

		$base.buts.b3.m add command \
			-label "Open New File or Directory..." -acc "" \
			-command "[namespace current]::OpenFileOrDirectory" \
			-image $::hv_images(folder) \
			-compound left

		$base.buts.b3.m add separator
	}
	
	$base.buts.b3.m add command \
			-label "Home" -acc "" \
			-command "History::GoHome $hwidget" \
			-image $::hv_images(go-home-4) \
			-compound left

	$base.buts.b3.m add command \
			-label "Previus" -acc "Alt-Left" \
			-command "History::GoBackward $hwidget" \
			-image $::hv_images(draw-arrow-back) \
			-compound left

	$base.buts.b3.m add command \
			-label "Next" -acc "Alt-Right" \
			-command "History::GoForward $hwidget" \
			-image $::hv_images(draw-arrow-forward) \
			-compound left

	$base.buts.b3.m add separator
	$base.buts.b3.m add command \
			-label "Search in page..." -acc "Ctrl+F" \
			-command "focus $hwidget; HelpViewer::SearchWindow" \
			-image $::hv_images(system-search) \
			-compound left

	$base.buts.b3.m add command \
			-label "  Close Search Dialog" -acc "" \
			-command "$hwidget hideSearchWidget" \
			-compound left

	$base.buts.b3.m add separator

	$base.buts.b3.m add command \
			-label "  Increase Viewer Font / Zoom +" -acc "Ctrl+Plus" \
			-command "$hwidget fontScaleCmd plus" \
			-compound left

	$base.buts.b3.m add command \
			-label "  Decrease Viewer Font / Zoom -" -acc "Ctrl+Minus" \
			-command "$hwidget fontScaleCmd minus" \
			-compound left

	# register about command...
	if {$aboutcmd != ""} {
			
		$base.buts.b3.m add separator

		$base.buts.b3.m add command \
			-label "  About..." \
			-command "$aboutcmd" \
			-compound left
	}


	# -->>
	ttk::entry $base.buts.fname \
		-state disabled
	
	set mostrecent_file_entry $base.buts.fname

	SetMostRecentFileInfo  $file_or_dir
	
	# Button $base.buts.b4 \
	#		-image $::hv_images(emblem-unreadable) \
	#		-command "[namespace current]::ExitCmd $base" \
	#		-relief link \
	#		-helptext "Close the Dialog"

	Button $base.buts.b5 \
			-image $::hv_images(rapidsvn) \
			-command "[namespace current]::Refresh" \
			-relief link \
			-helptext "Refresh <F5>..."
			
	pack $base.buts.b1 $base.buts.b2 -side left
	pack $base.buts.b3 -side left -padx 10
	pack $base.buts.fname -side left -padx 5 -fill x -expand true
	pack $base.buts.b5 -side right

	pack $base.buts -side top -fill x
	pack $pw -side bottom -fill both -expand true

	
	# This procedure is called when the user selects the File/Open
	# menu option.
	#
	set lastDir [pwd]
	
	if { [package provide Pan] != "" } {
		pan bind $tree.c
		
		# option -cursor is not implemented in html & html3widget...
		pan bind [winfo parent [$hwidget get_htmlwidget]]
	}

	bind [$hwidget get_htmlwidget] <3> \
			[list tk_popup $base.buts.b3.m %X %Y]


	focus $hwidget
	bind [$hwidget get_htmlwidget] <Prior> {%W yview scroll -1 pages}
	bind [$hwidget get_htmlwidget] <Next>  {%W yview scroll 1 pages}
	bind [$hwidget get_htmlwidget] <Home>  {%W yview moveto 0}
	bind [$hwidget get_htmlwidget] <End>   {%W yview moveto 1}
	
	bind [winfo toplevel $hwidget] <Alt-Left> "History::GoBackward $hwidget; break"
	bind [winfo toplevel $hwidget] <Alt-Right> "History::GoForward $hwidget; break"
	
	bind [winfo toplevel $hwidget] <F3> "focus $hwidget; HelpViewer::Search ; break"
	bind [winfo toplevel $hwidget] <F5> "[namespace current]::Refresh"

	bind [winfo toplevel $hwidget] <Control-f> "focus $hwidget; HelpViewer::SearchWindow; break"

	bind [winfo toplevel $hwidget] <Alt-KeyPress-c> [list $notebook raise tree]
	bind [winfo toplevel $hwidget] <Alt-KeyPress-i> [list $notebook raise search]
	bind [winfo toplevel $hwidget] <Alt-KeyPress-s> [list $notebook raise search]
	bind [winfo toplevel $hwidget] <Control-KeyPress-i> [list $notebook raise search]
	bind [winfo toplevel $hwidget] <Control-KeyPress-s> [list $notebook raise search]

	# could be either a directory or a file reference:
	# ------------------------------------------------
	# set file_or_dir [file normalize $file_or_dir]
	
	if { [file isdirectory $file_or_dir] } {
		set HelpBaseDir $file_or_dir
	} else {
		set HelpBaseDir [file dirname $file_or_dir]
	}
	# -----------------------------------------------
	# puts $HelpBaseDir

	FillDir $tree root

	
	# if an argument was specified, read it into the HTML widget.
	if {$file_or_dir != ""} {
		LoadFile $hwidget $file_or_dir
	}

	if { $geom == "" } {
		set x [expr [winfo screenwidth $base]/2-400]
		set y [expr [winfo screenheight $base]/2-300]
		wm geom $base 650x400+${x}+$y

	} else {
		wm geom $base $geom
	}
	
	update idletasks
	wm deiconify $base

	return $hwidget
}

