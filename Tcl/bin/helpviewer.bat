::set dos {
@set PATH=C:\Tcl\bin;%PATH%
@wish86tg.exe %0 %*
@exit
}

# -------------------------
# what packages do we need:
# -------------------------
set topdir [file join [file dirname [info script]] ".." "lib" "helpviewer3.0.3"]
set auto_path [linsert $auto_path 0 $topdir]
puts topdir:$topdir

package require Tk
package require tile

catch { package require Img }
catch { package require tkdnd }

package require Tkhtml 3.0

package require BWidget 1.9
	Widget::theme 1

package require infowindow
package require savedefault
package require rframe
package require getfileordirectory

package require http
package require fileutil
package require inifile
package require Markdown
package require html3widget
package require helpviewer

# ----------------------
# Initialization section
# ----------------------

array set ::app {
	TITLE "HelpViewer"
	VERSION "V3.0.2"
	CFG_FILE "helpviewerapp.cfg"
	\
	TESTMODE 0
}

foreach fname {
	"helpviewerapp.tcl"
	"helpviewerapp_about.tcl"
	"clean_up_temporary_files.tcl"
} {
	source [file join $topdir $fname]
}


# -during development-
if {$app(TESTMODE) == 1} {
	console show
	console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}
	
	source [file join $topdir "ped.tcl"]
}

# start the help viewer
# application...
# --------------------------
wm withdraw .
helpviewerapp::helpviewerapp
# --------------------------

# EOF