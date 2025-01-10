#!/bin/sh
#\
exec wish "$0" ${1+"$@"}
#
#

package require Tk
package require tile

set tkinspect(title) "Tkinspect"
set tkinspect(counter) -1
set tkinspect(main_window_count) 0
set tkinspect(list_classes) {
    namespaces_list Namespaces
    procs_list Procs
    globals_list Globals
    class_list Classes
    object_list Objects
    windows_list Windows
    images_list Images
    menus_list Menus
    canvas_list Canvases
    afters_list Afters
}
set tkinspect(list_class_files) {
    lists.tcl procs_list.tcl globals_list.tcl windows_list.tcl
    images_list.tcl about.tcl value.tcl help.tcl cmdline.tcl
    windows_info.tcl menus_list.tcl canvas_list.tcl classes_list.tcl
    objects_list.tcl names.tcl afters_list.tcl namespaces_list.tcl
}
set tkinspect(help_topics) {
    Intro Value Lists Procs Globals Windows Images Canvases Menus
    Classes Value Miscellany Notes WhatsNew ChangeLog
}

if {[info commands itcl_info] ne ""} {
    set tkinspect(default_lists) {
	object_list procs_list globals_list windows_list
    }
} else {
    set tkinspect(default_lists) {
	namespaces_list procs_list globals_list windows_list
    }
}

wm withdraw .

# Find the tkinspect library - support scripted documents (Steve Landers)
# also supports starkits (Pat Thoyts).
if {[info exists ::starkit::topdir]} {
    set tkinspect_library [file join $::starkit::topdir lib tkinspect]
    lappend auto_path $tkinspect_library
} elseif {[info exists ::scripdoc::self]} {
    lappend auto_path [file join $::scripdoc::self lib]
    set tkinspect_library [file join $::scripdoc::self lib tkinspect]
    lappend auto_path $tkinspect_library
} elseif {[file exists @tkinspect_library@/tclIndex]} {
    lappend auto_path [set tkinspect_library @tkinspect_library@]
} else {
    lappend auto_path [set tkinspect_library [file dirname [info script]]]
}

# If we have Tk send - use it (on windows this has no effect)
if {[info command tk] ne {}} {
    ::tk appname $tkinspect(title)
}

# Emulate the 'send' command using the dde package if available.
if {[tk windowingsystem] eq "win32"} {
    if {![catch {package require dde}]} {
        array set dde [list count 0 topic $tkinspect(title)]
        while {[dde services TclEval $dde(topic)] ne {}} {
            incr dde(count)
            set dde(topic) "$tkinspect(title) #$dde(count)"
        }
        dde servername $dde(topic)
        set tkinspect(title) $dde(topic)
        unset dde
        proc send {app args} {
            eval dde eval [list $app] $args
        }
    }
}

# Provide non-send based support using tklib's comm package.
if {![catch {package require comm}]} {
    # defer the cleanup for 2 seconds to allow other events to process
    comm::comm hook lost {after 2000 set x 1; vwait x}

    #
    # replace send with version that does both send and comm
    #
    if {[string match send [info command send]]} {
        rename send tk_send
    } else {
        proc tk_send args {}
    }
    proc tkinspect_bgerror {msg opts} {
    }
    proc send {app args} {
        if {[string match {[0-9]*} $app]} {
	    #
	    # during comm::comm send ignore background errors
	    #
	    set bgerr [interp bgerror {}]
	    interp bgerror {} tkinspect_bgerror
	    set code [catch {uplevel 1 comm::comm send [list $app] $args} ret]
	    interp bgerror {} $bgerr
	    return -code $code $ret
        }
        uplevel 1 tk_send [list $app] $args
    }
}

stl_lite_init
version_init

proc tkinspect_exit {} {
    after 0 {exit 0}
}

proc tkinspect_widgets_init {} {
    global tkinspect_library
    global tkinspect

    foreach file $tkinspect(list_class_files) {
	uplevel #0 source $tkinspect_library/$file
    }
}

proc tkinspect_about {parent} {
    catch {destroy .about}
    about .about
    wm transient .about $parent
    .about run
}

dialog tkinspect_main {
    param target ""
    member last_list {}
    member lists ""
    member cmdline_counter -1
    member cmdlines ""
    member windows_info
    method create {} {
        global tkinspect
	menu $self.menu
	$self configure -menu $self.menu
	set m [menu $self.menu.file -tearoff 0]
	$self.menu add cascade -label "File" -underline 0 -menu $m
	$m add cascade -label "Select Interpreter (send)" -underline 0 \
	    -menu $self.menu.file.interps
        if {[package provide comm] ne {}} {
            $m add cascade -label "Select Interpreter (comm)" -underline 21 \
                    -menu $self.menu.file.comminterps
            $m add command -label "Connect to (comm)" -underline 0 \
                    -command [list $self connect_dialog]
        }
	$m add command -label "Update Lists" -underline 0 \
	    -command [list $self update_lists]
	$m add separator
	$m add command -label "New Tkinspect Window" -underline 0 \
	    -command tkinspect_create_main_window
	$m add command -label "New Command Line" -underline 12 \
	    -command [list $self add_cmdline]
	foreach {list_class name} $tkinspect(list_classes) {
	    $m add checkbutton -label "$name List" \
		-variable [object_slotname ${list_class}_is_on] \
		-command [list $self toggle_list $list_class]
	}
	$m add separator
	$m add command -label "Close Window" -underline 0 \
	    -command [list $self close]
	$m add command -label "Exit Tkinspect" -underline 1 \
	    -command tkinspect_exit
	menu $self.menu.file.interps -tearoff 0 \
	    -postcommand [list $self fill_interp_menu]
	if {[package provide comm] ne {}} {
            menu $self.menu.file.comminterps -tearoff 0 \
                    -postcommand [list $self fill_comminterp_menu]
        }
	pack [set f [frame $self.buttons -bd 0]] -side top -fill x
	label $f.cmd_label -text " Command: "
	pack $f.cmd_label -side left
	ttk::entry $f.command
	bind $f.command <Return> [subst -nocommands {
	    $self send_command [%W get]
	}]
	pack $f.command -side left -fill x -expand yes
	ttk::button $f.send_command -text "Send Command" \
	    -command [subst -nocommands {
		$self send_command [$f.command get]
	    }]
	pack $f.send_command -side left -padx {4 2} -pady 4
	ttk::button $f.send_value -text "Send Value" \
	    -command [list $self.value send_value]
	pack $f.send_value -side left -padx {2 4} -pady 4

        pack [panedwindow $self.pane -showhandle 0 -orient vertical] \
	    -side top -fill both -expand yes
        $self.pane add [panedwindow $self.lists -showhandle 0]
	$self.pane paneconfigure $self.lists -sticky nsew -stretch always \
	    -minsize 100

	value $self.value -main $self
	$self.pane add $self.value
	$self.pane paneconfigure $self.value -sticky nsew -stretch always \
	    -minsize 100

	foreach list_class $tkinspect(default_lists) {
	    $self add_list $list_class
	    set slot(${list_class}_is_on) 1
	}

	set m [menu $self.menu.help -tearoff 0]
	$self.menu add cascade -label "Help" -underline 0 -menu $m
	$m add command -label "About..." -command [list tkinspect_about $self]\
	    -underline 0
	foreach topic $tkinspect(help_topics) {
	    $m add command -label $topic -command [list $self help $topic] \
		-underline 0
	}

	pack [frame $self.status] -side top -fill x
	label $self.status.l -anchor w -bd 0 -relief sunken
	pack $self.status.l -side left -fill x -expand yes
	set slot(windows_info) [object_new windows_info]
	wm iconname $self $tkinspect(title)
	wm title $self "$tkinspect(title): $slot(target)"
	$self status "Ready."
    }
    method reconfig {} {
    }
    method destroy {} {
        global tkinspect
	object_delete $slot(windows_info)
        if {[incr tkinspect(main_window_count) -1] == 0} tkinspect_exit
    }
    method close {} {
	after 0 [list destroy $self]
    }
    method set_target {target {type send}} {
        global tkinspect
	set slot(target) $target
        set slot(target,type) $type
        if {$type eq "comm"} {
            set slot(target,self) [comm::comm self]
        } else {
            set slot(target,self) $tkinspect(title)
        }
	$self update_lists
	foreach cmdline $slot(cmdlines) {
	    $cmdline set_target $target
	}
	set name [file tail [send $target ::set argv0]]
	$self status "Remote interpreter is \"$target\" ($name)"
	wm title $self "$tkinspect(title): $target ($name)"
    }
    method update_lists {} {
	if {$slot(target) eq ""} return
	$slot(windows_info) update $slot(target)
	foreach list $slot(lists) {
	    $list update $slot(target)
	}
    }
    method select_list_item {list item} {
	if {![winfo exists $list]} {
	    return
	}
	set slot(last_list) $list
	set target [$self target]
	$self.value set_value "[$list get_item_name] $item" \
	    [$list retrieve $target $item] \
	    [list $self select_list_item $list $item]
	$self.value set_send_filter [list $list send_filter]
	$self status "Showing \"$item\""
    }
    method connect_dialog {} {
	if {![winfo exists $self.connect]} {
	    connect_interp $self.connect -value $self
	    under_mouse $self.connect
	} else {
	    wm deiconify $self.connect
	    under_mouse $self.connect
	}
    }
    method fill_interp_menu {} {
	set m $self.menu.file.interps
	catch {$m delete 0 last}
	if {[tk windowingsystem] eq "aqua"} {
	    # not available
	    return
	}
        if {[package provide dde] ne {}} {
            foreach service [dde services TclEval {}] {
                set label [lindex $service 1]
                set app $label
                $m add command -label $label \
                    -command [list $self set_target $app dde]
            }
        } else {
            foreach interp [winfo interps] {
                $m add command -label $interp \
                    -command [list $self set_target $interp]
            }
        }
    }
    method fill_comminterp_menu {} {
	set m $self.menu.file.comminterps
	catch {$m delete 0 last}
	foreach interp [comm::comm interps] {
	    if {[string match [comm::comm self] $interp]} {
		set label "$interp (self)"
	    } else {
		set label "$interp ([file tail [send $interp ::set argv0]])"
	    }
	    if {[info exists labels($label)]} {
		continue
	    }
	    set labels($label) $interp
	    $m add command -label $label \
		-command [list $self set_target $interp comm]
	}
    }
    method status {msg} {
	$self.status.l config -text $msg
    }
    method target {} {
	if {![string length $slot(target)]} {
	    tkinspect_failure \
	     "No interpreter has been selected yet.  Please select one first."
	}
	return $slot(target)
    }
    method last_list {} { return $slot(last_list) }
    method send_command {cmd} {
	set slot(last_list) ""
	$self.value set_send_filter ""
	set result [send $slot(target) $cmd]
	$self status "Command sent."
	$self.value set_value [list command $cmd] $result \
	    [list $self send_command $cmd]
    }
    method toggle_list {list_class} {
	set list $self.lists.$list_class
	if {!$slot(${list_class}_is_on)} {
	    if {[llength $slot(lists)] < 2} {
		set slot(${list_class}_is_on) 1
		return
	    }
	    $list remove
	} else {
	    $self add_list $list_class
	    if {[string length $slot(target)]} {
		$list update $slot(target)
	    }
	}
    }
    method add_list {list_class} {
	set list $self.lists.$list_class
	if {[winfo exists $list]} return
	set slot(${list_class}_is_on) 1
	lappend slot(lists) $list
	$list_class $list -command [list $self select_list_item $list] \
	    -main $self
        $self.lists add $list -width 150
	$self.lists paneconfigure $list -sticky nsew -stretch always
    }
    method delete_list {list} {
	global tk_patchLevel
	set ndx [lsearch -exact $slot(lists) $list]
	set slot(lists) [lreplace $slot(lists) $ndx $ndx]
        $self.lists forget $list
	set list_class [lindex [split $list .] 3]
	set slot(${list_class}_is_on) 0
    }
    method add_cmdline {} {
	set cmdline \
	  [command_line $self.cmdline[incr slot(cmdline_counter)] -main $self]
	$cmdline set_target $slot(target)
	lappend slot(cmdlines) $cmdline
    }
    method delete_cmdline {cmdline} {
	set ndx [lsearch -exact $slot(cmdlines) $cmdline]
	set slot(cmdlines) [lreplace $slot(cmdlines) $ndx $ndx]
    }
    method add_menu {name} {
	set w $self.menu.[string tolower $name]
	menu $w -tearoff 0
	$self.menu add cascade -label $name -underline 0 -menu $w
	return $w
    }
    method delete_menu {name} {
	$self.menu delete "*$name"
	set w $self.menu.[string tolower $name]
	destroy $w
    }
    method help {topic} {
	global tkinspect tkinspect_library
	if {[winfo exists $self.help]} {
	    wm deiconify $self.help
	    raise $self.help
	} else {
	    help_window $self.help -topics $tkinspect(help_topics) \
		-helpdir [file join $tkinspect_library doc]
	    center_window $self.help
	}
	$self.help show_topic $topic
    }
    method windows_info {args} {
	eval $slot(windows_info) $args
    }
}

proc tkinspect_create_main_window {args} {
    global tkinspect
    set w [tkinspect_main .main[incr tkinspect(counter)] {*}$args]
    incr tkinspect(main_window_count)
    return $w
}

# 971005: phealy
#
# With tk8.0 the default tkerror proc is finally gone - bgerror
# takes its place (see the changes tk8.0 changes file). This
# simplified error handling should be ok.
#
proc tkinspect_failure {reason} {
    tk_dialog .failure "Tkinspect Failure" $reason warning 0 Ok
}

tkinspect_widgets_init
tkinspect_default_options
if {[file exists ~/.tkinspect_opts]} {
    source ~/.tkinspect_opts
}
tkinspect_create_main_window
if {[file exists .tkinspect_init]} {
    source .tkinspect_init
}

dialog connect_interp {
    param value
    method create {} {
	frame $self.top
	pack $self.top -side top -fill x
	label $self.l -text "Connect to:"
	ttk::entry $self.e
	bind $self.e <Return> [list $self connect]
	bind $self.e <Escape> [list destroy $self]
	pack $self.l -in $self.top -side left
	pack $self.e -in $self.top -fill x -expand yes
	ttk::button $self.close -text "OK" -width 8 \
	    -command [list $self connect]
	ttk::button $self.cancel -text "Cancel" -width 8 \
	    -command [list destroy $self]
	pack $self.close $self.cancel -side left
	wm title $self "Connect to Interp.."
	wm iconname $self "Connect to Interp.."
	focus $self.e
    }
    method reconfig {} {
    }
    method connect {} {
	set text [$self.e get]
	if {![string match {[0-9]*} $text]} return
	comm::comm connect $text
	wm withdraw $self
	$slot(value) set_target $text comm
    }
}

