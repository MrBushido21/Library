# Maintains the list of windows, and caches window class information.
# (the list is shared between windows_list and menus_list.)

object_class windows_info {
    member windows {}
    method clear {} {
	foreach w $slot(windows) {
	    if {[info exists slot($w.class)]} {
		unset slot($w.class)
	    }
	}
	set slot(windows) {}
    }
    method get_windows {} { return $slot(windows) }
    method append_windows {target result_var parent} {
	upvar $result_var result
        set cmd [subst -nocommands {
	    if {[::info command ::winfo] eq "::winfo"} {
		::winfo children $parent
            }
	}]
	foreach w [send $target $cmd] {
	    lappend slot(windows) $w
	    $self append_windows $target result $w
	}
    }
    method update {target} {
	$self clear
        set cmd [subst -nocommands {
	    if {[::info command ::winfo] eq "::winfo"} {
		::winfo children .
	    } else {
		error "Tk is not loaded"
	    }
	}]
	if {[catch {set slot(windows) [send $target $cmd]}]} {
            set slot(windows) {}
        } else {
	    set slot(windows) [concat "." $slot(windows)]
	}
	feedback .feedback -title "Getting Windows" \
	    -steps [llength $slot(windows)]
	.feedback grab
	foreach w [lrange $slot(windows) 1 end] {
	    $self append_windows $target windows $w
	    .feedback step
	    update idletasks
	}
	destroy .feedback
    }
    method get_class {target w} {
	if {![info exists slot($w.class)]} {
	    if {![send $target [list winfo exists $w]]} {
		# the window no longer exists, so delete it from our list
		set ndx [lsearch -exact $slot(windows) $w]
		if {$ndx >= 0} {
		    set slot(windows) [lreplace $slot(windows) $ndx $ndx]
		}
		return ""
	    }
	    set slot($w.class) [send $target [list winfo class $w]]
	}
	return $slot($w.class)
    }
}
