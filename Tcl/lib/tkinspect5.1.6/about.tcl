#
# Handle the about box.
#

dialog about {
    method create {} {
	global tkinspect tkinspect_library
	wm withdraw $self
	wm transient $self .
	wm title $self "About tkinspect"
	pack [frame $self.border] -expand 1 -fill both
	label $self.title -text "tkinspect" -font TkCaptionFont
	set ver "Release $tkinspect(release) ($tkinspect(release_date))"
	append ver "\nplus slight lifting by chw"
	label $self.ver -text $ver
	label $self.com -text "\n Bugs, suggestions and patches to:\n\
                      http://sourceforge.net/projects/tkcon/ \n"
	frame $self.mug -bd 4
	label $self.mug.l -justify left \
            -text "Originally by Sam Shen\n\Contributions\
            from:\nPaul Healy\nJohn LoVerso\n\T. Schotanus\
            \nPat Thoyts\nAlexander Caldwell\n"

	global about_priv
	if {![info exists about_priv(mug_image)]} {
	    set about_priv(mug_image) \
		[image create photo -file \
		    [file join $tkinspect_library doc sls.ppm]]
	}
	label $self.mug.bm -image $about_priv(mug_image)
	pack $self.mug.l -side left -fill both -expand yes
	pack $self.mug.bm -fill none
	ttk::button $self.ok -text "Ok" -command [list destroy $self]
	pack $self.title $self.ver $self.com $self.mug \
	    -in $self.border -side top -fill x
	pack $self.ok -in $self.border -side bottom -pady 5
	bind $self <Return> [list destroy $self]
    }
    method reconfig {} {
    }
    method run {} {
	wm deiconify $self
	focus $self
	center_window $self
	tkwait visibility $self
	grab set $self
	tkwait window $self
    }
}
