#
#

dialog help_window {
    param topics {}
    param width 100
    param height 35
    param helpdir .
    member history {}
    member history_ndx -1
    member history_len 0
    member rendering 0
    method create {} {
	menu $self.menu -tearoff 0
	set m [menu $self.menu.topics -tearoff 0]
	$self.menu add cascade -label "Topics" -underline 0 \
	    -menu $m
	set m [menu $self.menu.navigate -tearoff 0]
	$self.menu add cascade -label "Navigate" -underline 0 \
	    -menu $m
	$m add command -label "Forward" -underline 0 -state disabled \
	    -command [list $self forward] -accelerator f
	$m add command -label "Back" -underline 0 -state disabled \
	    -command [list $self back] -accelerator b
	menu $m.go -tearoff 0 -postcommand [list $self fill_go_menu]
	$m add cascade -label "Go" -underline 0 -menu $m.go
	catch {$self configure -menu $self.menu}
	frame $self.text
	ttk::scrollbar $self.text.sb -command [list $self.text.t yview]
	text $self.text.t -yscroll [list $self.text.sb set] \
	    -wrap word -setgrid 1
	set t $self.text.t
	pack $self.text.sb -in $self.text -side right -fill y
	pack $self.text.t -in $self.text -side left -fill both -expand yes
	pack $self.text -in $self -side bottom -fill both -expand yes
	bind $self <Key-f> [list $self forward]
	bind $self <Key-b> [list $self back]
	bind $self <Alt-Right> [list $self forward]
	bind $self <Alt-Left> [list $self back]
	bind $self <Key-space> [list $self page_forward]
	bind $self <Key-Next> [list $self page_forward]
	bind $self <Key-BackSpace> [list $self page_back]
	bind $self <Key-Prior> [list $self page_back]
	bind $self <Key-Delete> [list $self page_back]
	bind $self <Key-Down> [list $self line_forward]
	bind $self <Key-Up> [list $self line_back]
    }
    method reconfig {} {
	set m $self.menu.topics
	$m delete 0 last
	foreach topic $slot(topics) {
	    $m add radiobutton -variable [object_slotname topic] \
		-value $topic \
		-label $topic \
		-command [list $self show_topic $topic]
	}
	$m add separator
	$m add command -label "Close Help" -underline 0 \
	    -command [list destroy $self]
	$self.text.t config -width $slot(width) -height $slot(height)
    }
    method show_topic {topic} {
	incr slot(history_ndx)
	set slot(history) [lrange $slot(history) 0 $slot(history_ndx)]
	set slot(history_len) [expr {$slot(history_ndx) + 1}]
	lappend slot(history) $topic
	$self read_topic $topic
    }
    method read_topic {topic} {
        # probably should use uri::geturl from tcllib
	set slot(topic) $topic
	wm title $self "Help: $topic"
        set filename [file join $slot(helpdir) $topic]
        if {![file exist $filename]} {
	    set filename1 [file join $slot(helpdir) .. $topic]
	    if {[file exists $filename1]} {
		set filename $filename1
	    } else {
		append filename .html
	    }
        }
	set f [open $filename r]
	set txt [read $f]
	close $f

        # Fix for
        if {[string match -nocase "*ChangeLog" $filename]} {
            set txt "<html><body><pre>$txt</pre></body></html>"
        }

	feedback .help_feedback -steps [set slot(len) [string length $txt]] \
	    -title "Rendering HTML"
	.help_feedback grab
	set slot(remaining) $slot(len)
	set slot(rendering) 1
	tkhtml_set_render_hook "$self update_feedback"
	tkhtml_set_command "$self follow_link"
	tkhtml_render $self.text.t $txt
	destroy .help_feedback
	set slot(rendering) 0
	set m $self.menu.navigate
	if {($slot(history_ndx)+1) < $slot(history_len)} {
	    $m entryconfig 0 -state normal
	} else {
	    $m entryconfig 0 -state disabled
	}
	if {$slot(history_ndx) > 0} {
	    $m entryconfig 1 -state normal
	} else {
	    $m entryconfig 1 -state disabled
	}
    }
    method follow_link {link} {
	$self show_topic $link
    }
    method forward {} {
	if {$slot(rendering) || ($slot(history_ndx)+1) >= $slot(history_len)} return
	incr slot(history_ndx)
	$self read_topic [lindex $slot(history) $slot(history_ndx)]
    }
    method back {} {
	if {$slot(rendering) || $slot(history_ndx) <= 0} return
	incr slot(history_ndx) -1
	$self read_topic [lindex $slot(history) $slot(history_ndx)]
    }
    method fill_go_menu {} {
	set m $self.menu.navigate.go
	catch {$m delete 0 last}
	for {set i [expr {[llength $slot(history)]-1}]} {$i >= 0} {incr i -1} {
	    set topic [lindex $slot(history) $i]
	    $m add command -label $topic \
		-command [list $self show_topic $topic]
	}
    }
    method update_feedback {n} {
	if {($slot(remaining) - $n) > .1*$slot(len)} {
	    .help_feedback step [expr {$slot(remaining) - $n}]
	    update idletasks
	    set slot(remaining) $n
	}
    }
    method page_forward {} {
	$self.text.t yview scroll 1 pages
    }
    method page_back {} {
	$self.text.t yview scroll -1 pages
    }
    method line_forward {} { $self.text.t yview scroll 1 units }
    method line_back {} { $self.text.t yview scroll -1 units }
}
