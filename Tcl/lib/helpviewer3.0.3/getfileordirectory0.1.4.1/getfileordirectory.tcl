# ------------------------------------------------------------------------
# getfileordirectory.tcl ---
# ------------------------------------------------------------------------
# (c) 2017, Johann Oberdorfer - Engineering Support | CAD | Software
#     johann.oberdorfer [at] gmail.com
#     www.johann-oberdorfer.eu
# ------------------------------------------------------------------------
# This source file is distributed under the BSD license.
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#   See the BSD License for more details.
# ------------------------------------------------------------------------
# Purpose:
#  This source implements a drag&drop enabled file or directory
#  selection dialog.
# ------------------------------------------------------------------------

# 17-04-12: D&D is now optional as it is not supported on all platforms
#			change basicly was made to allow execution on
#			undroidwish/Androidwish
#           thank's to Christian Werner for his request

package require Tk
package require tile

# D&D support is optional
# note: for Androwish/undroidwish tkdnd is not supported!
catch { package require tkdnd }
package require rframe

package provide getfileordirectory 0.1


namespace eval getfileordirectory {
	
	variable widgetDefaults
	variable widgetImages
	variable widgetVars

	array set widgetDefaults {
		title "Drag&Drop file or directory:"
		\
		initialdir ""
		selectmode "directory"
		mostrecentfiles ""
	}

	set widgetDefaults(filetypes) {
		{{Html Files} {.html .htm}}
		{{Text-Files} {*.txt* .text}}
		{{All Files} *}
	}

	array set widgetVars {
		dnd_isavailable 0
		is_ok 0
		dragndrop_dir ""
		select_mode 1
		wlistbox ""
	}

	# initializing required images...

	set this_dir   [file dirname [info script]]
	set image_dir  [file join $this_dir "images"]
	set image_file [file join $this_dir "ImageLib.tcl"]

	proc LoadImages {image_dir {patterns {*.gif}}} {
		foreach p $patterns {
			foreach file [glob -nocomplain -directory $image_dir $p] {
				set img [file tail [file rootname $file]]
				if { ![info exists images($img)] } {
					set images($img) [image create photo -file $file]
				}
			}}
		return [array get images]
	}

	if { [file exists $image_file] } {
		source $image_file
		array set widgetImages [array get images]
	} else {
		array set widgetImages [LoadImages \
				[file join $image_dir] {"*.gif" "*.png"}]
	}

	# customized styles...

	# myToggle - checkbutton with style ...

	ttk::style element create myToggle.Checkbutton.indicator \
		image [list \
			$widgetImages(checkbox-off) \
			{disabled selected} $widgetImages(checkbox-off) \
			{selected} $widgetImages(checkbox-on) \
			{disabled} $widgetImages(checkbox-off) \
		]

	ttk::style layout myToggle.TCheckbutton [list \
		Checkbutton.padding -sticky nswe -children [list \
			myToggle.Checkbutton.indicator \
				-side left -sticky {} \
			Checkbutton.focus -side left -sticky w -children { \
				Checkbutton.label -sticky nswe \
			} \
		] \
	]
	ttk::style map myToggle.TCheckbutton \
		-background [list active \
		[ttk::style lookup myToggle.TCheckbutton -background]]


	# D&D support is optional
	# note: for Androwish/undroidwish tkdnd is not supported!
	
	if {[catch {package require tkdnd}] == 0 } {
		set widgetVars(dnd_isavailable) 1
	}
}


proc getfileordirectory::OKButtonCmd {} {
	variable widgetVars
	set widgetVars(is_ok) 1
}


proc getfileordirectory::EntryBindingsCmd {} {
	variable widgetVars

	set state disabled
	set fname [$widgetVars(input_entry) get]
	
	if { $fname != "" &&
		 ([file isfile $fname] || [file isdirectory $fname]) } {

		set state normal
	}

	foreach w [list $widgetVars(ok_button) $widgetVars(input_image)] {
		$w configure -state $state
	}
}


proc getfileordirectory::CommandOnDrop {drop_argument} {
	variable widgetVars
	variable widgetDefaults

	set is_valid 0
	
	if { [winfo exists $widgetVars(wlistbox)] } {
		$widgetVars(wlistbox) selection clear 0 end
	}
	
	switch -- $widgetDefaults(selectmode) {
		"file" {
			if { [file isdirectory $drop_argument] } {

				# if a directory has been choosen,
				# just switch to "directory" mode...
				set widgetDefaults(selectmode) "directory"
				set widgetVars(select_mode) 1
				RadioButtonCmd

				set is_valid 1
			}

			if { [file isfile $drop_argument] } {
				set is_valid 1
			}
		}
		"directory" {

			if { [file isfile $drop_argument] } {

				# if a file name has been choosen
				# just switch to "file" mode...
				set widgetDefaults(selectmode) "file"
				set widgetVars(select_mode) 0
				RadioButtonCmd

				set is_valid 1
			}
		
			if { [file isdirectory $drop_argument] } {
				set is_valid 1
			}
		}
		default { return }
	}

	if { $is_valid == 0 } {
		set widgetVars(dragndrop_dir) ""
	} else {
		set widgetVars(dragndrop_dir) $drop_argument
	}

	EntryBindingsCmd
}


proc getfileordirectory::SelectFileCmd {} {
	variable widgetDefaults
	variable widgetImages
	variable widgetVars
	
	if { [winfo exists $widgetVars(wlistbox)] } {
		$widgetVars(wlistbox) selection clear 0 end
	}

	switch -- $widgetVars(select_mode) {
		0 { 
			# select file ...
			set fname [tk_getOpenFile \
				-parent $widgetVars(this) \
				-title "Select File:" \
				-initialdir $widgetDefaults(initialdir) \
				-filetypes  $widgetDefaults(filetypes) \
			]
		}
		1 { 
			# select directory...
			set fname [tk_chooseDirectory \
				-parent $widgetVars(this) \
				-title "Select Directory:" \
				-initialdir $widgetDefaults(initialdir) \
				-mustexist 1 \
			]
		}
		default { return }
	}


	if {$fname != ""} {
		set widgetDefaults(initialdir) [file dirname $fname]
		set widgetVars(dragndrop_dir) $fname

		EntryBindingsCmd
		OKButtonCmd
	}
}

proc getfileordirectory::CancelCmd {} {
	variable widgetVars
	set widgetVars(is_ok) 2
}

proc getfileordirectory::RadioButtonCmd {} {
	variable widgetVars
	
	if { [winfo exists $widgetVars(wlistbox)] } {
		$widgetVars(wlistbox) selection clear 0 end
	}
	
	switch -- $widgetVars(select_mode) {
		0 { set txt "Select File ...    " }
		1 { set txt "Select Directory..." }
		default { return }
	}
	
	$widgetVars(selfile_bttn) configure -text $txt

	# clean previous selection:
	set widgetVars(dragndrop_dir) ""
	EntryBindingsCmd
}

proc getfileordirectory::ListboxSelectCmd {wlistbox} {
	variable widgetDefaults

	# this works for single selection mode:
	set idx [$wlistbox curselection]
	set fname [lindex $widgetDefaults(mostrecentfiles) $idx]

	
	# make sure, the file or directory still exists,
	# (just to be sure, file validation should have been done
	# in the caller program already)
	#
	if { ![file exists $fname] } {
		return
	}

	# we can use the D&D command to trigger entry & button state, etc...
	CommandOnDrop $fname
}


proc getfileordirectory::DoubleClickCmd {wlistbox} {
	variable widgetDefaults
	variable widgetVars

	# as we have cleared the current selection previously,
	# the curselection index returns an empty string
	# set idx [$wlistbox curselection]
	# set fname [lindex $widgetDefaults(mostrecentfiles) $idx]

	# this is  why we retrieve the current fname from the entry widget:
	set fname $widgetVars(dragndrop_dir)
	
	# make sure, the file or directory still exists,
	# (just to be sure, file validation should have been done
	# in the caller program already)
	#
	if { ![file exists $fname] } {
		return
	}
	
	OKButtonCmd
}



# -------------------------------------------------------------------------
# gui declaration
# -------------------------------------------------------------------------

proc getfileordirectory::getfileordirectory {args} {
	variable widgetDefaults
	variable widgetImages
	variable widgetVars
	
	set wparent ""
	set ind 0
	
	while { $ind < [llength $args] } {
		switch -exact -- [lindex $args $ind] {
			"-parent" {
				incr ind
				set wparent [lindex $args $ind]
				incr ind
			}
			"-title" {
				incr ind
				set widgetDefaults(title) [lindex $args $ind]
				incr ind
			}
			"-initialdir" {
				incr ind
				set widgetDefaults(initialdir) [lindex $args $ind]
				incr ind
			}
			"-filetypes" {
				incr ind
				set widgetDefaults(filetypes) [lindex $args $ind]
				incr ind
			}
			"-selectmode" {
				incr ind
				set widgetDefaults(selectmode) [lindex $args $ind]

				# map radio button flag...
				switch -exact $widgetDefaults(selectmode) {
					"file" {
						set widgetVars(select_mode) 0
					}
					"directory" {
						set widgetVars(select_mode) 1
					}
				}
				incr ind
			}
			"-mostrecentfiles" {
				incr ind
				set widgetDefaults(mostrecentfiles) [lindex $args $ind]
				incr ind
			}
			default {
				puts "unknown option [lindex $args $ind]"
				return ""
			}
		}
	}
	
	set w $wparent.getfilename
	set widgetVars(this) $w
	catch {destroy $w}

	if {$widgetDefaults(mostrecentfiles) == ""} {
		set geometry "800x250+350+350"
	} else {
		set geometry "800x400+350+350"
	}
	
	toplevel $w
	wm title $w "File Selection Dialog"
	wm geometry $w $geometry
	wm transient $w $wparent
	bind $w <KeyPress-Escape> "[namespace current]::CancelCmd"
	
	
	set fmain [ttk::frame $w.main -relief groove]
	pack $fmain -side bottom -fill x

	ttk::button $fmain.chk \
		-text "Continue" \
		-compound left \
		-command "[namespace current]::OKButtonCmd" \
		-state disabled

	set widgetVars(ok_button) $fmain.chk 
		
	ttk::button $fmain.cancel \
		-text "Cancel" \
		-image $widgetImages(dialog-close) \
		-compound left \
		-command "[namespace current]::CancelCmd" \

	pack $fmain.chk $fmain.cancel -side left -expand true -padx 4 -pady 4

	# drag'n drop area here ("#DFECFF"):
	# ----------------------------------
	set bgcolor "white"

	ttk::style configure DnD.TLabel \
		-background $bgcolor \
		-foreground "DarkGrey"

	ttk::style configure DnD.TFrame \
		-background $bgcolor \
		-bd 2

	set fmode [ttk::labelframe $w.toc -text "  Selection Mode:  "]
		pack $fmode -padx 5 -pady 2 -side top -fill x
		
		# ttk::label $fmode.lbl -text "Selection Mode:"
		
		ttk::radiobutton $fmode.b1 \
			-text "File" \
			-variable "[namespace current]::widgetVars(select_mode)" \
			-value 0 \
			-style myToggle.TCheckbutton \
			-command "[namespace current]::RadioButtonCmd"
		
		ttk::radiobutton $fmode.b2 \
			-text "Directory" \
			-variable "[namespace current]::widgetVars(select_mode)" \
			-value 1 \
			-style myToggle.TCheckbutton \
			-command "[namespace current]::RadioButtonCmd"
		
		pack $fmode.b1 $fmode.b2 -padx 5 -pady 5 -side left

		if { $widgetVars(dnd_isavailable) == 0} {
			set dnd_info_txt "Drag&Drop currently not supported. "
		} else {
			set dnd_info_txt "Use Drag&Drop to select a file or directory."
		}

		ttk::label $fmode.info -text $dnd_info_txt
		pack $fmode.info -side right -padx 5

		
	set f [::rframe::rframe $w.dnd $bgcolor]
		
		pack $f -padx 4 -pady 4 -side top -fill both -expand true

		if {$::tcl_platform(platform) == "windows"} {

			ttk::label $f.logo \
				-text $widgetDefaults(title) \
				-image $widgetImages(system-log-out-3) \
				-compound top \
				-style DnD.TLabel
			pack $f.logo -side top -padx 5 -pady 4 -anchor center
	
			ttk::label $f.lbl \
				-image $widgetImages(folder) \
				-style DnD.TLabel \
				-state disabled
		} else {

			# don't know, how to style this for OSX (?)...
			# need to figure out this issue later ...

			label $f.logo \
				-text $widgetDefaults(title) \
				-image $widgetImages(system-log-out-3) \
				-compound top \
				-foreground "DarkGrey" \
				-background $bgcolor
			pack $f.logo -side top -padx 5 -pady 4 -anchor center

			label $f.lbl \
				-image $widgetImages(folder) \
				-background $bgcolor \
				-state disabled
		}

		set widgetVars(input_image) $f.lbl
		
		ttk::entry $f.entry \
			-width 40 \
			-textvariable "[namespace current]::widgetVars(dragndrop_dir)"

		set widgetVars(input_entry) $f.entry

		ttk::button $f.selfile \
			-text "..." \
			-command "[namespace current]::SelectFileCmd"
				
		set widgetVars(selfile_bttn) $f.selfile
			
		# triggers the button text configuration
		RadioButtonCmd

		# slightly different "decoration" when DnD is available
		if {$widgetVars(dnd_isavailable) == 1} {
			$f.selfile configure -style Toolbutton
		}
		
		pack $f.lbl -side left -padx 5 -pady 5
		pack $f.entry -side left -padx 5 -pady 5 -fill x -expand true

		pack $f.selfile -side right

		bind $widgetVars(input_entry) <Leave>  "[namespace current]::EntryBindingsCmd"
		bind $widgetVars(input_entry) <Return> "[namespace current]::EntryBindingsCmd"


	# most recent files or directories ...
	
	if { $widgetDefaults(mostrecentfiles) != "" } {
	
		set bg ttk::style 
	
		set flb [ ttk::labelframe $w.lb \
					-text "  Most recently used files or directories:  " \
					-height [expr {[llength $widgetDefaults(mostrecentfiles)] +1}] ]
		pack $flb -padx 4 -pady 4 -side bottom -fill x

		set lb $flb.lb
		
		ttk::scrollbar $flb.y -orient vertical -command [list $lb yview]
		
		listbox $lb \
			-highlightthickness 0 \
			-relief flat \
			-selectmode "browse" \
			-fg [ttk::style configure . -foreground] \
			-bg [ttk::style configure . -background] \
			-yscrollcommand [list $flb.y set]

		pack $lb -side left -padx 4 -pady 4 -fill x -expand true
		pack $flb.y -side left -fill y
		
		# fill listbox with values...
		foreach fname $widgetDefaults(mostrecentfiles) {
			$lb insert end $fname
		}
		
		# listbox callback ...
		bind $lb <<ListboxSelect>> "[namespace current]::ListboxSelectCmd %W"
		bind $lb <Double-Button-1> "[namespace current]::OKButtonCmd"

		set widgetVars(wlistbox) $lb
	}
	
		
	# optional tk dnd support
	# -----------------------

	if {$widgetVars(dnd_isavailable) == 1} {
	
		foreach w [list $w.dnd $f.entry] {
			tkdnd::drop_target register $w "*"
			bind $w <<Drop>> "[namespace current]::CommandOnDrop %D"
		}
	}
	
	# wait user
	grab $widgetVars(this)
	tkwait variable "[namespace current]::widgetVars(is_ok)"
	grab release $widgetVars(this)
	
	if { $widgetVars(is_ok) == 1 } {
		set retval [$widgetVars(input_entry) get]
	} else {
		set retval ""
	}
	
	destroy $widgetVars(this)
	return $retval
}

