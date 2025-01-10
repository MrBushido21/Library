set dir [file dirname [info script]]

# ------------------------------------------
# where to find support packages & libraries
# ------------------------------------------

# callup in the application development environment:
lappend auto_path [file join $dir ".."]
lappend auto_path [file join $dir "../../00-lib"]
lappend auto_path [file join $dir "../../00-lib2"]
lappend auto_path [file join $dir "../../00-lib3"]
lappend auto_path [file join $dir "../../00-libbin"]

# alternativ, callup inside the app:
lappend auto_path [file join $dir "../../lib"]
lappend auto_path [file join $dir "../../lib3"]
lappend auto_path [file join $dir "../../libbin"]

package require Tk

wm withdraw .
console show
console eval {wm protocol . WM_DELETE_WINDOW {exit 0}}

# requiring exactly 2.0 to avoid getting the one from Activestate
package require -exact Tkhtml 3.0


# same is required for BWidget ...
package require -exact BWidget 1.9.10
package require BWidget_patch
	Widget::theme 1

# packages are optional
catch {	package require Pan }
catch {	package getfileordirectory }
catch { package require tkdnd }

package require rframe
package require helpviewer
package require http
package require fileutil
package require Markdown
package require infowindow
package require html3widget


# --------------------------
# various test conditions...
# --------------------------

set mode 1
switch -- $mode {
	1 {
		set dir [file dirname [info script]]
		set demo_file [file join $dir "BWMan/contents.html"]
		
		HelpViewer::HelpViewer $demo_file -title "HelpViewer Demo"
	}
	2 {
		#  demo file 
		set dir [file dirname [info script]]
		set demo_file [file join $dir "demo_doc/tcl2006_tkhtml3.html"]
		
		# -------------------------------
		HelpViewer::HelpViewer $demo_file
		# -------------------------------
	}
	3 - default {
		# demo dir
		# set demo_dir [file join [file dirname [info script]] "demo_doc"]
		# set demo_dir [file join [file dirname [info script]] "demo_help"]
		# set demo_dir  [file join $::BWIDGET::LIBRARY "docu"]
		# set demo_dir "R:/Projekte_SoftwareEntwicklung/02_StartCATScript/CATDocu"
		set demo_dir "C:/_hugo/johann-oberdorfer.eu/content/blog"
		
		# -------------------------------
		HelpViewer::HelpViewer $demo_dir
		# -------------------------------
	}

} 


# HelpViewer::LoadRef $hwidget $demo_file
# catch {console show}
# catch {source [file join $dir "ped.tcl"]}

