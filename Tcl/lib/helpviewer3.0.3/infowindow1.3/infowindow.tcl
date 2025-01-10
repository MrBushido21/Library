# -------------------------------------------------------------------------
# (c) 2017, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] googlemail.com
#     www.johann-oberdorfer.eu
# -------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -------------------------------------------------------------------------
#
# Usage:
# pop-up info_window, example calls like:
#
# ::infowindow::infowindow $wparent  \
#    "Welcome to my App" \
#    -infostring "my_logo.gif \"Johann Oberdorfer\"" \
#    -default no
#
# ::infowindow::infowindow $wparent \
#  "Application XXX\nCreated: June 00\nJ.Oberdorfer" \
#         -default yes
# --------------------------------------------------------------------
# Revision History:
# 2017, 1st version
# --------------------------------------------------------------------

package provide infowindow 1.1

# the following packages are required:
# package require Markdown
# package require html3widget


namespace eval ::infowindow {
	variable TIMEOUT 16000
	variable dir

	set dir [file normalize [file dirname [info script]]]
	
	image create photo MY_PHOTO_IMAGE -file \
		[file join $dir "images/job_engineering_logo.png"]
}



# the following code was copied from BWidget

# ----------------------------------------------------------------------------
#  Command BWidget::place
# ----------------------------------------------------------------------------
#
# Notes:
#  For Windows systems with more than one monitor the available screen area may
#  have negative positions. Geometry settings with negative numbers are used
#  under X to place wrt the right or bottom of the screen. On windows, Tk
#  continues to do this. However, a geometry such as 100x100+-200-100 can be
#  used to place a window onto a secondary monitor. Passing the + gets Tk
#  to pass the remainder unchanged so the Windows manager then handles -200
#  which is a position on the left hand monitor.
#  I've tested this for left, right, above and below the primary monitor.
#  Currently there is no way to ask Tk the extent of the Windows desktop in 
#  a multi monitor system. Nor what the legal co-ordinate range might be.
#
proc ::infowindow::Place { path w h args } {

    update idletasks

    # If the window is not mapped, it may have any current size.
    # Then use required size, but bound it to the screen width.
    # This is mostly inexact, because any toolbars will still be removed
    # which may reduce size.
    if { $w == 0 && [winfo ismapped $path] } {
        set w [winfo width $path]
    } else {
        if { $w == 0 } {
            set w [winfo reqwidth $path]
        }
        set vsw [winfo vrootwidth  $path]
        if { $w > $vsw } { set w $vsw }
    }

    if { $h == 0 && [winfo ismapped $path] } {
        set h [winfo height $path]
    } else {
        if { $h == 0 } {
            set h [winfo reqheight $path]
        }
        set vsh [winfo vrootheight $path]
        if { $h > $vsh } { set h $vsh }
    }

    set arglen [llength $args]
    if { $arglen > 3 } {
        return -code error "apputil::Place: bad number of argument"
    }

    if { $arglen > 0 } {
        set where [lindex $args 0]
	set list  [list "at" "center" "left" "right" "above" "below"]
        set idx   [lsearch $list $where]
        if { $idx == -1 } {
	    return -code error [BWidget::badOptionString position $where $list]
        }
        if { $idx == 0 } {
            set err [catch {
                # purposely removed the {} around these expressions - [PT]
                set x [expr int([lindex $args 1])]
                set y [expr int([lindex $args 2])]
            }]
            if { $err } {
                return -code error "BWidget::place: incorrect position"
            }
            if {$::tcl_platform(platform) == "windows"} {
                # handle windows multi-screen. -100 != +-100
                if {[string index [lindex $args 1] 0] != "-"} {
                    set x "+$x"
                }
                if {[string index [lindex $args 2] 0] != "-"} {
                    set y "+$y"
                }
            } else {
                if { $x >= 0 } {
                    set x "+$x"
                }
                if { $y >= 0 } {
                    set y "+$y"
                }
            }
        } else {
            if { $arglen == 2 } {
                set widget [lindex $args 1]
                if { ![winfo exists $widget] } {
                    return -code error "apputil::Place: \"$widget\" does not exist"
                }
	    } else {
		set widget .
	    }
            set sw [winfo screenwidth  $path]
            set sh [winfo screenheight $path]
            if { $idx == 1 } {
                if { $arglen == 2 } {
                    # center to widget
                    set x0 [expr {[winfo rootx $widget] + ([winfo width  $widget] - $w)/2}]
                    set y0 [expr {[winfo rooty $widget] + ([winfo height $widget] - $h)/2}]
                } else {
                    # center to screen
                    set x [winfo rootx $path]
                    set x0 [expr {($sw - $w)/2}]
                    set vx [winfo vrootx $path]
                    set vw [winfo vrootwidth $path]
                    if {$x < 0 && $vx < 0} {
                        # We are left to the main screen
                        # Start of left screen: vx (negative)
                        # End coordinate of left screen: -1
                        # Width of left screen: vx * -1
                        # x0 = vx + ( -vx - w ) / 2
                        set x0 [expr {($vx - $w)/2}]
                    } elseif {$x > $sw && $vx+$vw > $sw} {
                        # We are right to the main screen
                        # Start of right screen: sw
                        # End of right screen: vx+vw-1
                        # Width of right screen: vx+vw-sw
                        # x0 = sw + ( vx + vw - sw - w ) / 2
                        set x0 [expr {($vx+$vw+$sw-$w)/2}]
                    }
                    # Same for y
                    set y [winfo rooty $path]
                    set y0 [expr {($sh - $h)/2}]
                    set vy [winfo vrooty $path]
                    set vh [winfo vrootheight $path]
                    if {$y < 0 && $vy < 0} {
                        # We are above to the main screen
                        set y0 [expr {($vy - $h)/2}]
                    } elseif {$y > $sh && $vy+$vh > $sh} {
                        # We are below to the main screen
                        set x0 [expr {($vy+$vh-$sh-$h)/2+$sh}]
                    }
                }
                set x "+$x0"
                set y "+$y0"
                if {$::tcl_platform(platform) != "windows"} {
                    if { $x0+$w > $sw } {set x "-0"; set x0 [expr {$sw-$w}]}
                    if { $x0 < 0 }      {set x "+0"}
                    if { $y0+$h > $sh } {set y "-0"; set y0 [expr {$sh-$h}]}
                    if { $y0 < 0 }      {set y "+0"}
                }
            } else {
                set x0 [winfo rootx $widget]
                set y0 [winfo rooty $widget]
                set x1 [expr {$x0 + [winfo width  $widget]}]
                set y1 [expr {$y0 + [winfo height $widget]}]
                if { $idx == 2 || $idx == 3 } {
                    set y "+$y0"
                    if {$::tcl_platform(platform) != "windows"} {
                        if { $y0+$h > $sh } {set y "-0"; set y0 [expr {$sh-$h}]}
                        if { $y0 < 0 }      {set y "+0"}
                    }
                    if { $idx == 2 } {
                        # try left, then right if out, then 0 if out
                        if { $x0 >= $w } {
                            set x [expr {$x0-$w}]
                        } elseif { $x1+$w <= $sw } {
                            set x "+$x1"
                        } else {
                            set x "+0"
                        }
                    } else {
                        # try right, then left if out, then 0 if out
                        if { $x1+$w <= $sw } {
                            set x "+$x1"
                        } elseif { $x0 >= $w } {
                            set x [expr {$x0-$w}]
                        } else {
                            set x "-0"
                        }
                    }
                } else {
                    set x "+$x0"
                    if {$::tcl_platform(platform) != "windows"} {
                        if { $x0+$w > $sw } {set x "-0"; set x0 [expr {$sw-$w}]}
                        if { $x0 < 0 }      {set x "+0"}
                    }
                    if { $idx == 4 } {
                        # try top, then bottom, then 0
                        if { $h <= $y0 } {
                            set y [expr {$y0-$h}]
                        } elseif { $y1+$h <= $sh } {
                            set y "+$y1"
                        } else {
                            set y "+0"
                        }
                    } else {
                        # try bottom, then top, then 0
                        if { $y1+$h <= $sh } {
                            set y "+$y1"
                        } elseif { $h <= $y0 } {
                            set y [expr {$y0-$h}]
                        } else {
                            set y "-0"
                        }
                    }
                }
            }
        }

        ## If there's not a + or - in front of the number, we need to add one.
        if {[string is integer [string index $x 0]]} { set x +$x }
        if {[string is integer [string index $y 0]]} { set y +$y }

        wm geometry $path "${w}x${h}${x}${y}"
    } else {
        wm geometry $path "${w}x${h}"
    }
    update idletasks
}


proc ::infowindow::CenterWin { w wparent } {
	Place $w 0 0 center $wparent
}


proc ::infowindow::init_htmlwidget {} {
	variable dir

	variable current_msg
	variable hwidget
	
	# data initialization...
	$hwidget reset

	# css support...
	# looks like, that we don't need "bootstrap.css" (?!) ...
	# (1st approach was: foreach ... {"bootstrap.css" "cerulean_mod.css"} ... )

	set stylecount 0
	foreach css_file {"cerulean_mod.css"} {
		set fp [open [file join $dir "css" $css_file] "r"]
		set css_content [read $fp]
		close $fp

		incr stylecount
		set id "author.[format %.4d $stylecount]"
		set importid "${id}.[format %.4d [incr ${stylecount}]]"
			
		$hwidget style -id $importid.9999 $css_content
	}
		
	# convert msg into html via markdown...
	set html_msg [::Markdown::convert $current_msg]
	
	$hwidget parse -final $html_msg
}

# -------------------------------------------------------------------------
# used to display information window...
# e.g. call with:
# info_window $w "Welcome to ...\nCreated: Aug.99 J.Oberdorfer"
# -------------------------------------------------------------------------

proc ::infowindow::infowindow {w msg args} {
	variable TIMEOUT
	variable dir
	global info_window_close 0
	
	variable current_msg
	variable hwidget
	
	set current_msg $msg

	if {$msg == ""} {
		set msg    "Programming:\nJohann Oberdorfer\n"
		append msg "e-mail:\njohann.oberdorfer@gmail.com\n"
	}

	if {$w == ""} {
		set infowin .imageWin
	} else {
		set infowin $w.imageWin
	} 
	
	catch {
		destroy $infowin
	}

	toplevel $infowin
	wm title $infowin "Program Information:"

	ttk::button $infowin.button \
		-text "Return" \
		-command {set ::info_window_close 1}
		
	pack $infowin.button -side bottom -padx 1 -pady 1

	
	set f [frame $infowin.frame -bg "white"]
		pack $f -side top -fill both -expand true -padx 1 -pady 1

	# option handling:
	# ----------------
	# e.g.: -infostr "image_name.gif \"Hello world\""
	#       -default no

	set cnt 0
	foreach {op value} $args {
    
		switch -exact -- $op {
			-infostring {

				# disassemble value-pair
				# ----------------------
				set lst [split $value " "]
				set img [lindex $lst 0]
				set txt [string range $value [string length $img] end]
				regsub -all "\"" $txt "" txt
			}
			-default {set default $value }
			-dummy { set dummy $value }
		}
		incr cnt
	}

	set f2 [ttk::frame $f.default]
	pack $f2 -side top -fill both -expand true -pady 2

   
	if { [info exist default] &&  $default == "yes"} {
 
		ttk::label $f2.image -image MY_PHOTO_IMAGE
		pack $f2.image -side top -padx 1 -pady 1

		# ttk::label $f2.label -text $msg
		# pack $f2.image $f2.label -side top -padx 1 -pady 1
		
		set hwidget [::html3widget::html3widget $f2.html]
		pack $f2.html -side bottom -fill both -expand true -padx 1 -pady 1

	
	} else {

		ttk::label $f2.label -text $msg
		pack  $f2.label -side top -padx 1 -pady 1
	}    

	if {$w != ""} {
		CenterWin $infowin $w
	}
	
	# avoid flickering ...
	after 300 "[namespace current]::init_htmlwidget"

	
	# -disabled-, we don't want the dialog to dissapear automaticaly
	# after $TIMEOUT { set ::info_window_close 1 }

	# ---------------------------------
	grab $infowin
	tkwait variable ::info_window_close
	grab release $infowin
	# ---------------------------------

	destroy $infowin
}

