# -----------------------------------------------------------------------------
# html3widget.tcl ---
# -----------------------------------------------------------------------------
# (c) 2016, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# -----------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# -----------------------------------------------------------------------------
# Purpose:
#  A TclOO class implementing the html3widget megawidget.
#  Might be usefull as a starting point.
# -----------------------------------------------------------------------------
# TclOO naming conventions:
# public methods  - starts with lower case declaration names, whereas
# private methods - starts with uppercase naming,
#                   so we are going to use CamelCase ...
# -----------------------------------------------------------------------------

# for development: try to find autoscroll, etc ...

# COMMANDS:
#   html3widget::html3widget path ?args?
#
# WIDGET-COMMANDS:
# 	<widget> parseurl 'url'
#	<widget> parsefile html_file

# examples:
#   set html3 [html3widget::html3widget .t]
#	pack $html3
# 	$html3 parseurl "http://wiki.tcl.tk/48458"
#	$html3 parsefile [file join $dir "demo_doc/tkhtml_doc.html"]
#


# for the moment, we keep required add-on packages
# down below *this* directory...

set dir [file normalize [file dirname [info script]]]
set auto_path [linsert $auto_path 0 [file join $dir "."]]


# in addition, these are the packages we essentially need:

package require Tk
package require -exact Tkhtml 3.0
package require scrolledwidget
package require selectionmanager
package require findwidget

# replace http package with native Tkhtml functionality:
catch {package require http}


package provide html3widget 0.2.1


namespace eval html3widget {
	variable image_dir
	variable image_file
	
	set this_dir   [file dirname [info script]]
	set image_dir  [file join $this_dir "images"]
	set image_file [file join $this_dir "ImageLib.tcl"]
	
	variable cnt 0
	
	proc LoadImages {image_dir {patterns {*.gif}}} {
		foreach p $patterns {
			foreach file [glob -nocomplain -directory $image_dir $p] {
				set img [file tail [file rootname $file]]
				if { ![info exists images($img)] } {
					set images($img) [image create photo -file $file]
		}}}
		return [array get images]
	}

	# ---------------------------------------------------------------
	# read images from library file or alternatively one by one
	# ---------------------------------------------------------------
	if { [file exists $image_file] } {
		source $image_file
		array set appImages [array get images]
	} else {
		array set appImages [::html3widget::LoadImages \
				[file join $image_dir] {"*.gif" "*.png"}]
	}
	# ---------------------------------------------------------------


	# html3widget.TCheckbutton - checkbutton style declaration

	ttk::style element create html3widget.Checkbutton.indicator \
		image [list \
			$appImages(checkbox-off) \
			{disabled selected} $appImages(checkbox-off) \
			{selected} $appImages(checkbox-on) \
			{disabled} $appImages(checkbox-off) \
		]

	ttk::style layout html3widget.TCheckbutton [list \
		Checkbutton.padding -sticky nswe -children [list \
			html3widget.Checkbutton.indicator \
				-side left -sticky {} \
			Checkbutton.focus -side left -sticky w -children { \
				Checkbutton.label -sticky nswe \
			} \
		] \
	]
	ttk::style map html3widget.TCheckbutton \
		-background [list active \
		[ttk::style lookup html3widget.TCheckbutton -background]]


	proc html3widget {path args} {
		#
		# this is a tk-like wrapper around my... class so that
		# object creation works like other tk widgets
		#
		variable cnt; incr cnt
		set obj [Html3WidgetClass create tmp${cnt} $path {*}$args]
		
		# rename oldName newName
		rename $obj ::$path
		return $path
	}
	
	oo::class create Html3WidgetClass {
		
		constructor {path args} {
			
			my variable hwidget
			my variable html_baseurl

			my variable widgetOptions
			my variable widgetCompounds
			my variable isvisible
			
			# this goes together with the -zoom 1.0 option of the html widget
			my variable current_scaleidx
			my variable fontscales
			
			set html_baseurl ""

			set fontscales {0.6 0.8 0.9 1.0 1.2 1.4 2.0}
			set current_scaleidx 3

			set isvisible 0
			
			array set widgetCompounds {
				dummy 0
				selection_mgr ""
			}

			# declaration of all additional widget options
			array set widgetOptions {
				-dummy  {}
				-html_basedir ""
			}
			
			# incorporate arguments to local widget options
			array set widgetOptions $args
			
			# we use a frame for this specific widget class
			set f [ttk::frame $path -class html3widget]
			
			# we must rename the widget command
			# since it clashes with the object being created
			set widget ${path}_
			my Build $f
			rename $path $widget
			
			my configure {*}$args
		}
		
		destructor {
			# adds a destructor to clean up the widget
			set w [namespace tail [self]]
			catch {bind $w <Destroy> {}}
			catch {destroy $w}
		}
		
		method cget { {opt "" }  } {
			my variable hwidget
			my variable widgetOptions
			
			if { [string length $opt] == 0 } {
				return [array get widgetOptions]
			}
			if { [info exists widgetOptions($opt) ] } {
				return $widgetOptions($opt)
			}
			return [$hwidget cget $opt]
		}
		
		method configure { args } {
			my variable hwidget
			my variable widgetOptions
			
			if {[llength $args] == 0}  {
				
				# return all tablelist options
				set opt_list [$hwidget configure]
				
				# as well as all custom options
				foreach xopt [array get widgetOptions] {
					lappend opt_list $xopt
				}
				return $opt_list
				
			} elseif {[llength $args] == 1}  {
				
				# return configuration value for this option
				set opt $args
				if { [info exists widgetOptions($opt) ] } {
					return $widgetOptions($opt)
				}
				return [$hwidget cget $opt]
			}
			
			# error checking
			if {[expr {[llength $args]%2}] == 1}  {
				return -code error "value for \"[lindex $args end]\" missing"
			}
			
			# process the new configuration options...
			array set opts $args
			
			foreach opt_name [array names opts] {
				set opt_value $opts($opt_name)
				
				# overwrite with new value
				if { [info exists widgetOptions($opt_name)] } {
					set widgetOptions($opt_name) $opt_value
				}
				
				# some options need action from the widgets side
				switch -- $opt_name {
					-dummy {}
					-html_basedir {}
					default {
						
						# -------------------------------------------------------
						# if the configure option wasn't one of our special one's,
						# pass control over to the original tablelist widget
						# -------------------------------------------------------
						
						if {[catch {$hwidget configure $opt_name $opt_value} result]} {
							return -code error $result
						}
					}
				}
			}
		}
		
		method unknown {method args} {
			#
			# if the command wasn't one of our special one's,
			# pass control over to the original tablelist widget
			#
			my variable hwidget
			
			if {[catch {$hwidget $method {*}$args} result]} {
				return -code error $result
			}
			return $result
		}
	}
}

# --------------------------------------------------------
# Public Functions / implementation of our new subcommands
# --------------------------------------------------------
oo::define ::html3widget::Html3WidgetClass {
	
	method get_htmlwidget {} {
		my variable hwidget
		return $hwidget
	}

	method setsearchstring {search_str} {
		my variable widgetCompounds

		set wentry [$widgetCompounds(find_widget) getentrywidget]

		$wentry delete 0 end
		after idle "$wentry insert end $search_str"
	}
	
	method parsefile {html_file} {
		my variable hwidget
		my variable widgetOptions
	
		if { ![file exists $html_file] || ![file readable $html_file]} {
			return
		}
		set widgetOptions(-html_basedir) [file dirname $html_file]
		
		set fp [open $html_file "r"]
		set data [read $fp]
		close $fp

		$hwidget reset
		$hwidget parse -final $data
	}

	method parseurl {full_url} {
		my variable hwidget
		my variable html_baseurl

		# extract base url from url

		set b [::tkhtml::uri $full_url]
		# puts  "--> scheme: [$b scheme] authority: [$b authority]  path: [$b path]"

		# might be overwritten by the <base> handler - if there is a
		# custom declaration in the html's header section

		set html_baseurl "[$b scheme]://[$b authority]"

		set url [$b resolve $full_url]
		$b destroy
		
		set t [http::geturl $url]
		set data [http::data $t]
			
		$hwidget reset
		$hwidget parse -final $data
		http::cleanup $t
	}

	
	# this procedure normally is triggered by
	# a <control-f> binding declaration

	method showhideSearchWidget {} {
		my variable hwidget
		my variable widgetCompounds
		my variable isvisible

		# retrieve the actual selection (if available)...
	
		if {$widgetCompounds(selection_mgr) != ""} {
			set current_sel [string trim \
					[$widgetCompounds(selection_mgr) selected]]
		} else {
			set current_sel ""
		}
		
		# mimik the n++ behaviour:
		# see, if there is a user selection available,
		# if yes, trigger the search with this value...

		set frm $widgetCompounds(searchframe)
		set wentry [$widgetCompounds(find_widget) getentrywidget]
		
		# the -before argument is *very* important
		# to keep track of the required pack order

		if { $isvisible == 0 } {
			set isvisible 1
			pack $frm -before $widgetCompounds(scrolledw) -side top -fill x

			if {$current_sel != "" } {
				$wentry delete 0 end
				after idle "$wentry insert end $current_sel"
			}		
		} else {
		
			# keep the search window on screen, just copy the selection
			# into the etry widget and perform the search ...

			if {$current_sel != "" } {
				$wentry delete 0 end
				after idle "$wentry insert end $current_sel"
				return
			}

			$wentry delete 0 end
			
			set isvisible 0
			pack forget $frm
		}
	}

	method showSearchWidget {} {
		my variable widgetCompounds
		my variable isvisible

		set frm $widgetCompounds(searchframe)

		if { $isvisible == 1 } { return }

		set isvisible 1
		pack $widgetCompounds(searchframe) \
				-before $widgetCompounds(scrolledw) \
				-side top -fill x
	}

	method hideSearchWidget {} {
		my variable widgetCompounds
		my variable isvisible

		if { $isvisible == 0 } { return	}

		# clean search entry
		set wentry [$widgetCompounds(find_widget) getentrywidget]
		$wentry delete 0 end
		
		set isvisible 0
		pack forget $widgetCompounds(searchframe)
	}

	method fontScaleCmd {mode} {
		my variable hwidget
		my variable current_scaleidx
		my variable fontscales

		# set default value, if required
		if { ![info exists current_scaleidx] } {
			$hwidget configure -fontscale  1.0
			set current_scaleidx [lsearch $fontscales 1.0]
		}

		# zoom up/down acc. taking limits into account
		switch -- $mode {
			"plus" {
				set imax [expr { [llength $fontscales] -1 }]
			
				if {$current_scaleidx == $imax} {
					return
				}
				incr current_scaleidx
			}
			"minus" {
				if {$current_scaleidx == 0} {
					return
				}
				incr current_scaleidx -1
			}
			"getscale" {
				# returns the actual scale
				return [lindex $fontscales $current_scaleidx]
			}
			default {
				# unknown option, do nothing...
				return {}
			}
		}

		set current_scale [lindex $fontscales $current_scaleidx]
		
		# need some more information about this option (?):
		# $hwidget configure \
		#	-forcefontmetrics true \
		#	-fonttable [list 13 14 15 16 18 20 22]
		#
		$hwidget configure -fontscale $current_scale
		return $current_scale
	}

	method setscale {current_scale} {
		my variable hwidget
		my variable current_scaleidx
		my variable fontscales

		if {[set idx [lsearch $fontscales $current_scale]] != -1} {
			set current_scaleidx $idx
			$hwidget configure -fontscale $current_scale
		}
	}

	# This procedure is called when the user clicks on a hyperlink.
	#
	method hrefBinding {x y} {
		my variable hwidget
		my variable widgetOptions
		
		if {$widgetOptions(-html_basedir) == ""} {
			return
		}
	
		set node_data [$hwidget node -index $x $y]

		if { [llength $node_data] >= 2 } {
			set node [lindex $node_data 0]
		} else {
			set node $node_data
		}

		# parent node is an <A> tag (maybe?)
		if { [catch {set node [$node parent]} ] == 0 } {
	
			if {[$node tag] == "a"} {
				set href [string trim [$node attr -default "" href]]

				if {$href ne "" && $href ne "#"} {
					set fname [file join $widgetOptions(-html_basedir) $href]

					# follow the link, if the file exists
					if {[file exists $fname] } {
						my parsefile $fname
					}
				}
			}
		}
	}
	
	# Node handler script for <base> tags.
	#
	method Base_node_handler {node} {
		my variable html_baseurl

		# If a <base> tag is available in the main start page,
		# the default html_baseurl is overwritten by this node handler.
		# Might be the case for CMS generated pages.
		#
		set html_baseurl [$node attr -default "" href]
	}

	
	# Returns the full-uri formed by resolving $rel relative
	# to $base.
	#
	method Resolve_uri {base rel} {
		set b [::tkhtml::uri $base]
		# puts  "--> scheme: [$b scheme] authority: [$b authority]  path: [$b path]"
		
		set ret [$b resolve $rel]
		$b destroy
		set ret
	}

	# --------------------
	# Private Functions...
	# --------------------
	
	#  retrieve CSS "@import {...}" directives...

	method GetCSSImportTags {content} {
		set reflst {}
		foreach item [split $content ";"] {
			# item might look like something like:
			#   @import url("/_css/wikit.css")
			#
			if { [string first "@import" $item]  != -1 } {

				set uri [string trim [lindex [split $item "\""] 1]]
				if { $uri != "" } {
					lappend reflst $uri
				}
			}
		}
		return $reflst
	}
	
	method GetImageCmd {uri} {
		# see as well:
		#   http://wiki.tcl.tk/15586
		#
		my variable hwidget
		my variable widgetOptions
		my variable html_baseurl

		if { $html_baseurl != ""} {
			
			# convert from relative to absolute 'url'
			set uri [my Resolve_uri $html_baseurl $uri]

			# if the 'url' is an http url.
			if { [string equal -length 7 $uri "http://"] } {

				# image already exists
				if { [lsearch [image names] $uri] != -1 } {
					return $uri
				}
				
				# attempt to retrieve image data from the web...
				set token [::http::geturl $uri]
				set data [::http::data $token]
				::http::cleanup $token

				# some kind of image data validation
				if {[catch { image create photo $uri -data $data }] == 0 } {
					return $uri
				}

				return ""
			}
		}

		if {$widgetOptions(-html_basedir) != ""} {

			# if the 'url' passed is an image name
			if { [lsearch [image names] $uri] > -1 } {
				return $uri
			}
		
			# if the 'url' passed is a file on disk
			if { [file isfile $uri]  && [file readable $uri] } {

				# create image using file
				if {[catch { image create photo $uri -file $uri }] == 0 } {
					return $uri
				}
			} 
		
			# if the 'url' passed is a file on disk,
			# located relative behind the html_basedir...
			set fname [file join $widgetOptions(-html_basedir) $uri]		

			if { [file isfile $fname]  && [file readable $fname] } {

				# create image using file
				if {[catch { image create photo $uri -file $fname }] == 0 } {
					return $uri
				}
			}
		}

		return ""
	}
	
	method StyleSheetHandler {node} {
		#
		# implementations of application callbacks to load
		# stylesheets from the various sources enumerated above.
		#
		my variable hwidget
		my variable widgetOptions
		my variable html_baseurl
		my variable stylecount
		
		if { [string first "href" [$node attr]] == -1 } { return }
		
		set href [$node attr "href"]
		global "$href"

		if { ![info exists stylecount] } { set stylecount 0	}
		incr ::stylecount
		set id "author.[format %.4d $stylecount]"
		
		if {$html_baseurl != ""} {

			# convert from relative to absolute 'url'
			set href [my Resolve_uri $html_baseurl $href]
			
			# if the 'href' is an http url.
			if { [string equal -length 7 $href http://] } {

				set token [::http::geturl $href]
				set href_content [::http::data $token]
				::http::cleanup $token

				# console show; puts $href
				# handle CSS "@import {...}" directives:
				# as a 1st approach we just read in 1st level of @import

				foreach import_ref [my GetCSSImportTags $href_content] {

					set importurl [my Resolve_uri $html_baseurl $import_ref]
					set importid "${id}.[format %.4d [incr ${stylecount}]]"

					set token [::http::geturl $importurl]
					set css_content [::http::data $token]
					::http::cleanup $token

					$hwidget style -id $importid.9999 $css_content
				}

				$hwidget style -id $id.9999 $href_content
			}
		}

		if {$widgetOptions(-html_basedir) != ""} {

			# use the full path name of the css reference
			set fname [file join $widgetOptions(-html_basedir) $href]	

			if { [file exists $fname] && ![file isdirectory $fname] } {

				set fp [open $fname "r"]
				set href_content [read $fp]
				close $fp

				$hwidget style -id $id.9999 $href_content
			}
		}
		
	}

	method ImageTagHandler {node} {
		# puts [$node attr "src"]
		# my GetImageCmd [$node attr "src"]
		
	}
	
	method ScriptHandler {node} {
		my variable hwidget
		# not implemented
	}

	method ATagHandler {node} {
		my variable hwidget

		if {[$node tag] == "a"} {
			set href [string trim [$node attr -default "" href]]
		
			if {[string first "#" $href] == -1 &&
				[string trim [lindex [$node attr] 0]] != "name"	} {

				# console show
				# puts "href: $href"
				# puts "attr: [lindex [$node attr] 0]"

				$node dynamic set link
			}
		}
	}
	
	
	# Register for a callback when the end-user moves the pointer
	# over the HTML widget using the standard Tk bind command.
	#
	method RegisterDynamicEffectBindings {x y} {
		my variable hwidget
		
		# Clear the "hover" flag on all nodes
		# on which it is currently set.
		#
		foreach node [$hwidget search :hover] {
			$node dynamic clear hover
		}

		[winfo parent $hwidget] configure -cursor {}
		
		# Set the hover flag on all nodes that generate content
		# at the specified coordinates, and all ancestors of said nodes.
		#
		foreach node [$hwidget node $x $y] {
			for {} {$node != ""} {set node [$node parent]} {
				# console show
				#puts "--> $node : [$node attr]"
				if { [string first "href" [$node attr]] != -1 } {
					[winfo parent $hwidget] configure -cursor hand2
				}
				catch { $node dynamic set hover }
			}
		}
	}

	# emulate scroll behavior when pressing the middle mouse button:
	# cursor: sb_v_double_arrow / hand2
	#
	method RegisterMiddleMouseScrollBindings {} {
		my variable hwidget

		bind $hwidget <ButtonPress-2> {
			set html_pointery [lindex [winfo pointerxy %W] 1]
			[winfo toplevel %W] configure -cursor "hand2"
		}

		bind $hwidget <ButtonRelease-2> {
			[winfo toplevel %W] configure -cursor ""
		}

		bind $hwidget <B2-Motion> {
	
			# (%D)irection is not supported for the Html widget class
			if { [lindex [winfo pointerxy %W] 1] >= $html_pointery } {
				set D 1
			} else {
				set D -1
			}

			# we must make sure that positive and negative movements are rounded
			# equally to integers, avoiding the problem that
			#    (int)1/3 = 0, but (int)-1/3 = -1
			if {$D >= 0} {
				%W yview scroll [expr {-$D/3}] units
			} else {
				%W yview scroll [expr {(2-$D)/3}] units
			}
	
			set html_pointery [lindex [winfo pointerxy %W] 1]
		}
	}
	
	method Build {frm} {
		my variable widgetCompounds
		my variable hwidget
		my variable current_scaleidx

		set f [ttk::frame $frm.wmain]
		pack $f -side bottom -fill both -expand true

		set fsearch [ttk::frame $f.search -height 15]
		### will be packed later on via binding
		
		set widgetCompounds(searchframe) $fsearch

		set sc [scrolledwidget::scrolledwidget $f.sc]
		pack $sc -side bottom -fill both -expand 1 -padx 2 -pady 2
		
		# required to take care about the pack order
		set widgetCompounds(scrolledw) $f.sc

		# --------------------------
		# html 3 widget goes here...
		# --------------------------
		
		html $f.html \
				-mode quirks \
				-parsemode "xhtml" \
				-zoom 1.0 \
				-imagecmd "[namespace code {my GetImageCmd}]"

		pack $f.html -side left -fill both -expand true
			
		set hwidget $f.html
		$sc associate $hwidget
		
		my setscale 1.0
		
		# register selection manager
		# (as a TclOO object, we instantiate the obj with "new")
		
		set widgetCompounds(selection_mgr) \
								[selectionmanager new $hwidget]
		
		# register style sheet handler...
		# ** link base meta title style script body **

		$hwidget handler "node" "base" "[namespace code {my Base_node_handler}]"
		$hwidget handler "node" "link" "[namespace code {my StyleSheetHandler}]"
		$hwidget handler "node" "img"  "[namespace code {my ImageTagHandler}]"
		$hwidget handler "node" "a"    "[namespace code {my ATagHandler}]"

		$hwidget handler "script" "script" "[namespace code {my ScriptHandler}]"

		# hlight + change cursor
		# when hovering with the mouse over a hypertext link
		bind $hwidget <Motion> \
				"+[namespace code {my RegisterDynamicEffectBindings}] %x %y"

		my RegisterMiddleMouseScrollBindings
				
		# ---------------------------
		# create the findwidget ...
		# ---------------------------
		set wfind [::findwidget::findwidget $fsearch.find]
		pack $wfind -side left -fill x -expand true
		
		# tell the search widget where to communicate to
		# and which command to execute too, when the search functionality is done
		$wfind register_htmlwidget $hwidget
		$wfind register_closecommand "[namespace code {my hideSearchWidget}]"
		
		# beautify at last...
		set wlabel [$wfind getlabelwidget]
		$wlabel configure -text "" \
			-image $::html3widget::appImages(system-search)
			
		set wbutton [$wfind getbuttonwidget]
		$wbutton configure \
			-text "" \
			-image $::html3widget::appImages(dialog-close) \
			-compound left

		set wbutton [$wfind getsearchnextwidget]
		$wbutton configure \
			-text "" \
			-image $::html3widget::appImages(arrow-down) \
			-compound left

		set wbutton [$wfind getsearchprevwidget]
		$wbutton configure \
			-text "" \
			-image $::html3widget::appImages(arrow-up) \
			-compound left
			
			
		bind all <F3> \
			"[namespace code {my showhideSearchWidget}]"
		bind all <Control-f> \
			"[namespace code {my showhideSearchWidget}]"

		# enable enter key "everywhere" and not only when the
		# curser is inside the find dialog entry widget
		bind $hwidget <Return> \
			"$wfind execute_return_kbd_action Return"
		bind $hwidget <Control-Return> \
			"$wfind execute_return_kbd_action ControlReturn"
			
		set widgetCompounds(find_widget) $wfind
		# ---------------------------
		# eof findwidget declarations
		# ---------------------------

		bind all <Control-plus> "[namespace code {my fontScaleCmd}] plus"
		bind all <Control-minus> "[namespace code {my fontScaleCmd}] minus"

		# perhaps, makes the behavor of bindings more "reactive" ?
		tk_focusFollowsMouse
	}
}


# ---
# EOF
# ---
