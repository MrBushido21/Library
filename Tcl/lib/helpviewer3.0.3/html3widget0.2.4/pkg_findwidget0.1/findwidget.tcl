# -----------------------------------------------------------------------------
# findwidget.tcl ---
# -----------------------------------------------------------------------------
# (c) 2017, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# Credits:
#  Code derived from:
#    http://tkhtml.tcl.tk/hv3_widget.html
#    danielk1977 (Dan)
#
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------
# Purpose:
#  A TclOO class implementing the findwidget megawidget.
#  Might be usefull as a starting point.
# -----------------------------------------------------------------------------

# Widget Command:
#   findwidget::findwidget path
#
#
# Widget Specific Options:
#	configure interface not implemented

# Widget Sub-commands:
#   
#    getlabelwidget
#		returns the label widget, might be used to
#       configuration the label with custom image, etc...
#
#    getbuttonwidget
#       returns the button widget
#
#    register_htmlwidget <html3 widget>
#        call this function to establisch communication
#        between findwidget and html3widget
#
#    register_closecommand <command>
#        specify a command to be executed, once the widget
#        is set to no-show
#
#

package provide findwidget 0.1

namespace eval findwidget {
	variable cnt 0

	proc findwidget {path args} {
		#
		# this is a tk-like wrapper around my... class so that
		# object creation works like other tk widgets
		#
		variable cnt; incr cnt
		set obj [FindwidgetClass create tmp${cnt} $path {*}$args]

		# rename oldName newName
		rename $obj ::$path
		return $path
	}

	oo::class create FindwidgetClass {
		#
		# This widget encapsulates the "Find in page..." functionality.
		# Two tags may be added to the html widget(s):
		#    findwidget         (all search hits)
		#    findwidgetcurrent  (the current search hit)
		#
		constructor {path args} {
			my variable hwidget
			my variable win

			my variable myNocaseVar
			my variable myEntryVar
			my variable myCaptionVar

			my variable myCurrentHit
			my variable myCurrentList

			set myNocaseVar 1
			set myEntryVar  ""
			set myCaptionVar ""
		
			set myCurrentHit -1
			set myCurrentList ""
		
			# we use a frame for this specific widget class
			set win [ttk::frame $path -class findwidget]
			
			# we must rename the widget command
			# since it clashes with the object being created
			set widget ${path}_
			rename $path $widget

			ttk::entry $win.entry \
				-width 30 \
				-textvar "[namespace current]::myEntryVar"

			ttk::label $win.label \
				-text "Search"

			ttk::checkbutton $win.check_nocase \
				-text "Case Insensitive" \
				-variable "[namespace current]::myNocaseVar"
				# -style html3widget.TCheckbutton

			ttk::button $win.seach_next \
				-text "Seach Next..."  \
				-compound left \
				-command "[namespace code {my Return}] 1" \
				-style Toolbutton

			ttk::button $win.seach_prev \
				-text "Seach Previous..."  \
				-compound left \
				-command "[namespace code {my Return}] -1" \
				-style Toolbutton
				
			ttk::label $win.num_results \
				-textvar "[namespace current]::myCaptionVar"

			ttk::button $win.close \
				-text "Close" \
				-command "[namespace code {my Escape}]" \
				-style Toolbutton

			trace add variable "[namespace current]::myEntryVar" write "[namespace code {my DynamicUpdate}]"
			trace add variable "[namespace current]::myNocaseVar" write "[namespace code {my DynamicUpdate}]"
		
			bind $win.entry <Return> "[namespace code {my Return}] 1"
			bind $win.entry <Control-Return> "[namespace code {my Return}] -1"
			focus $win.entry

			# Propagate events that occur in the entry widget to the
			# ::html3widget::findwidget widget itself. This allows the calling script
			# to bind events without knowing the internal mega-widget structure.
			# For example, the html3widget app binds the <Escape> key to delete the
			# findwidget widget.
			#
			bindtags $win.entry [concat [bindtags $win.entry] $win]

			pack $win.entry $win.label -padx 4 -side left
			pack $win.check_nocase $win.seach_next $win.seach_prev -padx 2 -side left
			pack $win.num_results -side left -fill x
			pack $win.close -side right
		}

		destructor {
			set w [namespace tail [self]]
			catch {bind $w <Destroy> {}}
			catch {destroy $w}
		}

		# no configuration, just member functions to get access tho the
		# internal widget's (might be useful to configure imaces, etc.. later on)
		
		method getlabelwidget      {} { my variable win ; return $win.label }
		method getbuttonwidget     {} {	my variable win ; return $win.close	}
		method getentrywidget      {} { my variable win ; return $win.entry }
		method getsearchnextwidget {} { my variable win ; return $win.seach_next }
		method getsearchprevwidget {} {	my variable win ; return $win.seach_prev }
		
		method register_htmlwidget {widget} {
			my variable hwidget
			set hwidget $widget
		}

		method register_closecommand {cmd} {
			my variable win

			$win.close configure -command \
				"[namespace code {my Escape}]; $cmd"
		}
		
		method execute_return_kbd_action {mode} {
			my variable myEntryVar

			if {$myEntryVar != ""} {
				switch -- $mode {
					"Return" { my Return 1 }
					"ControlReturn" { my Return -1 }
				}
			}
		}

		method Escape {} {
			my variable win
			my variable myEntryVar
			my variable myCaptionVar
			
			# Delete any tags added to the html3widget widget.
			# Do this inside a [catch] block, as it may be that
			# the html3widget widget has itself already been destroyed.
			#
			foreach hwidget [my GetWidgetList] {
				catch {
					$hwidget tag delete findwidget
					$hwidget tag delete findwidgetcurrent
				}
			}
			trace remove variable "[namespace current]::myEntryVar" write "[namespace code {my UpdateDisplay}]"
			trace remove variable "[namespace current]::myNocaseVar" write "[namespace code {my UpdateDisplay}]"

			set myEntryVar  ""
			set myCaptionVar ""
		}
		
		method ComparePositionId {frame1 frame2} {
			return [string compare [$frame1 positionid] [$frame2 positionid]]
		}
		
		method GetWidgetList {} {
			my variable hwidget
			return [list $hwidget]
		}
		
		method LazyMoveto {hwidget n1 i1 n2 i2} {
			set nodebbox [$hwidget text bbox $n1 $i1 $n2 $i2]
			set docbbox  [$hwidget bbox]
			
			set docheight "[lindex $docbbox 3].0"
			
			set ntop    [expr ([lindex $nodebbox 1].0 - 30.0) / $docheight]
			set nbottom [expr ([lindex $nodebbox 3].0 + 30.0) / $docheight]
			
			set sheight [expr [winfo height $hwidget].0 / $docheight]
			set stop    [lindex [$hwidget yview] 0]
			set sbottom [expr $stop + $sheight]
			
			
			if {$ntop < $stop} {
				$hwidget yview moveto $ntop
			} elseif {$nbottom > $sbottom} {
				$hwidget yview moveto [expr $nbottom - $sheight]
			}
		}
		
		# Dynamic update proc.
		method UpdateDisplay {nMaxHighlight} {

			my variable myNocaseVar
			my variable myEntryVar
			my variable myCaptionVar
			my variable myCurrentList
			
			set nMatch 0      ;# Total number of matches
			set nHighlight 0  ;# Total number of highlighted matches
			set matches [list]
			
			# Get the list of html3widget widgets that (currently) make up this browser
			# display. There is usually only 1, but may be more in the case of
			# frameset documents.
			#
			set html3widgetlist [my GetWidgetList]
			
			# Delete any instances of our two tags - "findwidget" and
			# "findwidgetcurrent". Clear the caption.
			#
			foreach hwidget $html3widgetlist {

				$hwidget tag delete findwidget
				$hwidget tag delete findwidgetcurrent
			}
			set myCaptionVar ""
			
			# Figure out what we're looking for. If there is nothing entered
			# in the entry field, return early.
			set searchtext $myEntryVar
			if {$myNocaseVar} {
				set searchtext [string tolower $searchtext]
			}
			if {[string length $searchtext] == 0} return
			
			foreach hwidget $html3widgetlist {
				set doctext [$hwidget text text]
				if {$myNocaseVar} {
					set doctext [string tolower $doctext]
				}
				
				set iFin 0
				set lMatch [list]
				
				while {[set iStart [string first $searchtext $doctext $iFin]] >= 0} {
					set iFin [expr $iStart + [string length $searchtext]]
					lappend lMatch $iStart $iFin
					incr nMatch
					if {$nMatch == $nMaxHighlight} { set nMatch "many" ; break }
				}
				
				set lMatch [lrange $lMatch 0 [expr ($nMaxHighlight - $nHighlight)*2 - 1]]
				incr nHighlight [expr [llength $lMatch] / 2]
				if {[llength $lMatch] > 0} {
					lappend matches $hwidget [eval [concat $hwidget text index $lMatch]]
				}
			}
			
			set myCaptionVar "(highlighted $nHighlight of $nMatch hits)"
			
			foreach {hwidget matchlist} $matches {
				foreach {n1 i1 n2 i2} $matchlist {
					$hwidget tag add findwidget $n1 $i1 $n2 $i2
				}
				$hwidget tag configure findwidget -bg purple -fg white
				my LazyMoveto $hwidget                         \
						[lindex $matchlist 0] [lindex $matchlist 1] \
						[lindex $matchlist 2] [lindex $matchlist 3]
			}
			
			set myCurrentList $matches
		}
		
		method DynamicUpdate {args} {
			my variable myCurrentHit
		
			set myCurrentHit -1
			my UpdateDisplay 42
		}
		
		method Return {dir} {
			my variable hwidget
			my variable myCaptionVar
			my variable myCurrentHit
			my variable myCurrentList
			
			set previousHit $myCurrentHit
			if {$myCurrentHit < 0} {
				my UpdateDisplay 100000
			}
			incr myCurrentHit $dir
			
			set nTotalHit 0
			foreach {hwidget matchlist} $myCurrentList {
				incr nTotalHit [expr [llength $matchlist] / 4]
			}
			
			if {$myCurrentHit < 0 || $nTotalHit <= $myCurrentHit} {

				# tk_messageBox \
				#	-parent $hwidget \
				#	-message "End of Search reached." \
				#	-type ok
				
				if { $nTotalHit == 0 } {
					set myCaptionVar "No search result."
				} else {
				
					if { $myCurrentHit < 0 } {
						set myCaptionVar \
							"Hit 1 / ${nTotalHit}. Begin of search reached."
					} else {
						set myCaptionVar \
							"Hit $myCurrentHit / ${nTotalHit}. End of search reached."
					}
				}

				incr myCurrentHit [expr -1 * $dir]
				return
			}

			set myCaptionVar "Hit [expr $myCurrentHit + 1] / $nTotalHit"
			
			set hwidget ""
			foreach {hwidget n1 i1 n2 i2} [my GetHit $previousHit] { }
			catch {$hwidget tag delete findwidgetcurrent}
			
			set hwidget ""
			foreach {hwidget n1 i1 n2 i2} [my GetHit $myCurrentHit] { }
			my LazyMoveto $hwidget $n1 $i1 $n2 $i2
			$hwidget tag add findwidgetcurrent $n1 $i1 $n2 $i2
			$hwidget tag configure findwidgetcurrent -bg black -fg yellow
		}
		
		method GetHit {iIdx} {
			my variable myCurrentList

			set nSofar 0
			foreach {hwidget matchlist} $myCurrentList {
				set nThis [expr [llength $matchlist] / 4]
				if {($nThis + $nSofar) > $iIdx} {
					return [concat $hwidget [lrange $matchlist \
							[expr ($iIdx-$nSofar)*4] [expr ($iIdx-$nSofar)*4+3]
					]]
				}
				incr nSofar $nThis
			}
			return ""
		}
	}
}
