# -------------------------------------------------------------------------
# --- scrolledwidget.tcl
# -------------------------------------------------------------------------
# Revision history of this code:
#
# Scrodget:
#     Scrodget enables user to create easily a widget with its scrollbar.
#     Scrollbars are created by Scrodget and scroll commands are automatically
#     associated to a scrollable widget with Scrodget::associate.
#
#    scrodget was inspired by ScrolledWidget (BWidget)
#
#  Copyright (c) 2005 <Irrational Numbers> : <aburatti@libero.it>
#
#  This program is free software; you can redistibute it and/or modify
#  it under the terms of the GNU General Public License as published by
#  the Free Software Foundation.
#
#  See the file "license" for information on usage and
#  redistribution of this program, and for a disclaimer of all warranties.
#
# -------------------------------------------------------------------------
# scrolledwidget:
#   07.11.2011: Johann [dot] Oberdorfer [at] googlemail [dot] com
#
#   A TclOO approach, just to see how difficult it would be to convert a
#   snit widget to tcloo. In fact it was an easy one!
#  -enjoy-
# -------------------------------------------------------------------------
# -------------------------------------------------------------------------


package provide scrolledwidget 0.2

package require TclOO
package require tile

# workaround for aqua
if { [tk windowingsystem] eq "aqua" } {
	interp alias {} ttk::scrollbar {} ::scrollbar
}


namespace eval ::scrolledwidget {
	
	namespace export scrolledwidget
	
	# this is a tk-like wrapper around the class,
	# so that object creation works like other Tk widgets

	proc scrolledwidget {path args} {
		set obj [ScrolledWidget create tmp $path {*}$args]
		rename $obj ::$path
		return $path
	}
	
	oo::class create ScrolledWidget {
		
		variable widgetOptions
		variable widgetCompounds
    	variable auto
		variable isHidden
		variable GridIdx
		
		constructor {path args} {

			my variable widgetOptions
			my variable widgetCompounds
			my variable isHidden
			my variable GridIdx
            
            set widgetCompounds(internalW) {}

			array set widgetOptions {
				-scrollsides  se
				-autohide 1
			}
			
			# for each 'side' (n,s,w,e)
			#  define the position {row,col} within the 3x3 grid
			array set GridIdx {
				n { 0 1 }
				s { 2 1 }
				w { 1 0 }
				e { 1 2 }
			}
			
			# attributes for south/north (or east/west) are paired
			set isHidden(ns)  0
			set isHidden(ew)  0
			
			set win [ttk::frame $path -class ScrolledWidget]
			
            if { [tk windowingsystem] eq "aqua" } {
                        set sb "scrollbar"
            } else {    set sb ttk::scrollbar }

			set widgetCompounds(frame) $win
			set widgetCompounds(northScroll) [$sb $win.northScroll -orient horizontal]
			set widgetCompounds(southScroll) [$sb $win.southScroll -orient horizontal]
			set widgetCompounds(eastScroll)  [$sb $win.eastScroll]
			set widgetCompounds(westScroll)  [$sb $win.westScroll]
			
			# fix against deprecated scrollbar set/get syntax
			$widgetCompounds(northScroll) set 0 1
			$widgetCompounds(southScroll) set 0 1
			$widgetCompounds(eastScroll)  set 0 1
			$widgetCompounds(westScroll)  set 0 1
			
			# 3 x 3 grid ;
			#  the central cell (1,1) is for the internal widget.
			#  +-----+-----+----+
			#  |     | n   |    |
			#  +-----+-----+----+
			#  | w   |inter| e  |
			#  +-----+-----+----+
			#  |     | s   |    |
			#  +-----+-----+----+
			# Cells e or w are for vertical scrollbars
			# Cells n or s are for horizontal scrollbars
			# Note that scrollbars may be hidden.
			
			grid rowconfig    $win 1 -weight 1 -minsize 0
			grid columnconfig $win 1 -weight 1 -minsize 0
			
			# we must rename the widget command since it clashes with
			# the object being created
			
			set win ${path}_
			rename $path $win
			
			my SetAutohide $widgetOptions(-autohide)
			my SetScrollsides $widgetOptions(-scrollsides)
			
			my configure {*}$args
		}

        # public methods starts with lower case declaration names,
        # whereas private methods starts with uppercase naming
		
		method cget { {opt "" }  } {
			my variable widgetOptions
			
			if { [string length $opt] == 0 } {
				return [array get widgetOptions]
			}
			if { [info exists widgetOptions($opt) ] } {
				return $widgetOptions($opt)
			}
			return -code error "# unknown option"
		}
		
		method configure { args } {
			my variable widget
			my variable widgetOptions
			
			if {[llength $args] == 0}  {
				
				# return all custom options
				return [array get widgetOptions]
				
			} elseif {[llength $args] == 1}  {
				
				# return configuration value for this option
				set opt $args
				if { [info exists widgetOptions($opt) ] } {
					return $widgetOptions($opt)
				}
				return [$widget cget $opt]
			}
			
			# error checking
			if {[expr {[llength $args]%2}] == 1}  {
				return -code error "value for \"[lindex $args end]\" missing"
			}
			
			# process the new configuration options...
			array set opts $args
			
			foreach opt [array names opts] {
				set val $opts($opt)
				
				# overwrite with new value
				if { [info exists widgetOptions($opt)] } {
					set widgetOptions($opt) $val
				}
				
				# some options need action from the widgets side...
				switch -- $opt {
					-scrollsides {
						if { ! [regexp -expanded  {^[nesw]*$} $val] } {
							return -code error "# bad scrollsides \"$opt\": only n,s,w,e allowed"
						}
						my SetScrollsides $val
					}
					-autohide {
						my SetAutohide $val
					}
					default {
						return -code error "unknown configuration option: \"$opt\" specified"
					}
				}
			}
		}
		
		method associate { args } {
			my variable widgetCompounds
			
			switch -- [llength $args] {
				0 { return $widgetCompounds(internalW) }
				1 { set w [lindex $args 0] }
				default {
					return -code error \
                        "wrong # args: should be \"$ $widgetCompounds(frame) associate ?widget?\""
				}
			}
			
			if { $w != {}  &&  ! [winfo exists $w] } {
				return -code error "error: widget \"$w\" does not exist"
			}
			
			# detach previously associated-widget (if any)
			catch {
				grid forget $widgetCompounds(internalW)
				$widgetCompounds(internalW) configure -xscrollcommand {} -yscrollcommand {}
			}
			
			set widgetCompounds(internalW) $w
				
			$widgetCompounds(eastScroll) configure  -command "$w yview"
			$widgetCompounds(westScroll) configure  -command "$w yview"
			$widgetCompounds(northScroll) configure -command "$w xview"
			$widgetCompounds(southScroll) configure -command "$w xview"

			$w configure \
					-xscrollcommand "[self] auto_setScrollbar $widgetCompounds(northScroll) $widgetCompounds(southScroll)" \
					-yscrollcommand "[self] auto_setScrollbar $widgetCompounds(eastScroll) $widgetCompounds(westScroll)"
				
			catch {raise $w $widgetCompounds(frame)}
			grid $w -in $widgetCompounds(frame) -row 1 -column 1  -sticky news
 		}

		
		method auto_setScrollbar { sbA sbB {first 0} {last 1} }  {
			my variable widgetOptions
			my variable auto
			my variable isHidden
			
			set sideA  [my WhichSide $sbA]
			set orient [my WhichOrient $sbA]
			
			if { $auto($orient) } {
				if { $first == 0 && $last == 1 } {
					if { ! $isHidden($orient) } {
						grid forget $sbA
						grid forget $sbB
						set isHidden($orient) 1
					}
				} else {
					if { $isHidden($orient) } {
						my ShowScrollbar $sbA $widgetOptions(-scrollsides)
						my ShowScrollbar $sbB $widgetOptions(-scrollsides)
						set isHidden($orient) 0
					}
				}
			}
			$sbA set $first $last
			$sbB set $first $last
		}

 
   		# from the scrollbar's name, derive its 'side'
		#   i.e.  [WhichSide $widgetCompounds(westScroll])  returns 'w'

		method WhichSide { sb } {
			return [string index [winfo name $sb] 0]
		}

		
		# from the scrollbar's name, derive its 'orientation'
		# return values are: "ns" or "ew"
		# note: [my WhichSide $widgetCompounds(northScroll)] returns 'ew' (i.e. horizontal)
		
		method WhichOrient { sb } {
			set side [my WhichSide $sb]
			if { [string first $side "ns"] >= 0 } {
				set orient ew
			} else {
				set orient ns
			}
			return $orient
		}
		

		method SetScrollsides {sides} {
			my variable widgetOptions
			my variable widgetCompounds
			my variable isHidden
           
			set widgetOptions(-scrollsides) $sides
			if { ! $isHidden(ew) } {
				my ShowScrollbar $widgetCompounds(northScroll)  $widgetOptions(-scrollsides)
				my ShowScrollbar $widgetCompounds(southScroll)  $widgetOptions(-scrollsides)
			}
			if { ! $isHidden(ns) } {
				my ShowScrollbar $widgetCompounds(eastScroll)   $widgetOptions(-scrollsides)
				my ShowScrollbar $widgetCompounds(westScroll)   $widgetOptions(-scrollsides)
			}
		}
		
		
		# note: both scrollbars have the same orientation

		method HandleAutohide { sbA sbB } {
			my variable widgetOptions
			my variable auto
			my variable isHidden
			
			set sideA  [my WhichSide $sbA]
			set orient [my WhichOrient $sbA]
			
			if { $auto($orient) } {
				# 1/true : check if scrollbar should be hidden
				#          (based on the scrollbar's visible range)
				my auto_setScrollbar $sbA $sbB {*}[$sbA get]
			} else {
				# 0/false : if scrollbars are hidden, then show them
				if { $isHidden($orient) } {
					my ShowScrollbar $sbA  $widgetOptions(-scrollsides)
					my ShowScrollbar $sbB  $widgetOptions(-scrollsides)
					set isHidden($orient) 0
				}
			}
		}

		
		method BoolValue {x} {
 			if { [string is boolean $x] } {
				if { "$x" } { return 1 } else { return 0 }
			}
			return -code error "# not a boolean value"
		}

        
		method SetAutohide {value} {
			my variable widgetOptions
			my variable widgetCompounds
			my variable auto
			
			set value1 $value
			# normalize boolean value (if boolean)
			catch { set value1 [my BoolValue $value1] }
			
			switch -- $value1 {
				0 -
				none       { set auto(ew) 0 ; set auto(ns) 0 }
				vertical   { set auto(ew) 0 ; set auto(ns) 1 }
				horizontal { set auto(ew) 1 ; set auto(ns) 0 }
				1 -
				both       { set auto(ew) 1 ; set auto(ns) 1 }
				default    { return -code error \
                    "# bad autohide \"$value\": must be none,vertical,horizontal,both or a boolean value"
				}
			}
			set widgetOptions(-autohide) $value
			
			my HandleAutohide $widgetCompounds(northScroll) $widgetCompounds(southScroll)
			my HandleAutohide $widgetCompounds(eastScroll)  $widgetCompounds(westScroll)
		}
		
		
		method ShowScrollbar {sb validSides} {
			my variable GridIdx
			
			set side [my WhichSide $sb]
			if { [string first $side $validSides] != -1 } {
				set r [lindex $GridIdx($side) 0]
				set c [lindex $GridIdx($side) 1]
				set sticky [my WhichOrient $sb]
				grid $sb -row $r -column $c -sticky $sticky
			} else {
				grid forget $sb
			}
		}
	}
}
